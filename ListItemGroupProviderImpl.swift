//
//  ListItemGroupProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class ListItemGroupProviderImpl: ListItemGroupProvider {

    let dbGroupsProvider = RealmListItemGroupProvider()
    let remoteGroupsProvider = RemoteGroupsProvider()

    
    // TODO remove
    func groups(handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groups {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }
    
    // TODO don't use QuickAddItemSortBy here, map to a (new) group specific enum
    func groups(range: NSRange, sortBy: GroupSortBy, _ handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groups(range, sortBy: sortBy) {[weak self] dbGroups in
            handler(ProviderResult(status: .Success, sucessResult: dbGroups))
            
            self?.remoteGroupsProvider.groups {remoteResult in
                
                if let remoteGroups = remoteResult.successResult {
                    let groups: [ListItemGroup] = remoteGroups.map{ListItemGroupMapper.listItemGroupWithRemote($0)}
                    let sortedGroups = groups.sortedByOrder()
                    
                    if dbGroups != sortedGroups {
                        self?.dbGroupsProvider.overwrite(groups, clearTombstones: true) {saved in
                            if saved {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: sortedGroups))
                                
                            } else {
                                QL4("Error updating groups - coulnd't save remote groups")
                            }
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                }
            }
            
        }
    }
    
    func groups(text: String, range: NSRange, sortBy: GroupSortBy, _ handler: ProviderResult<(substring: String?, groups: [ListItemGroup])> -> Void) {
        dbGroupsProvider.groups(text, range: range, sortBy: sortBy) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }

    func add(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(group, dirty: remote) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))

            if saved && remote {
                self?.remoteGroupsProvider.addGroup(group) {remoteResult in
                    if let remoteGroup = remoteResult.successResult {
                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroup) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<RemoteGroup>) in
                            print("Error: adding group in remote: \(group), result: \(remoteResult)")
                        }
                    }
                }
            }
        }
    }
    
    func addGroupItems(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<[GroupItem]> -> ()) {
        groupItems(group, sortBy: .Alphabetic) {[weak self] result in
            if let groupItems = result.sucessResult {
                self?.add(groupItems, group: group, remote: remote) {result in
                    // return fetched group items to the caller
                    if result.success {
                        handler(ProviderResult(status: .Success, sucessResult: groupItems))
                    } else {
                        print("Error: ListItemGroupProviderImpl.addGroupItems: Couldn't save group items for group: \(group)")
                        handler(ProviderResult(status: result.status))
                    }
                }
            } else {
                print("Error: ListItemGroupProviderImpl.addGroupItems: Can't get group items for group: \(group)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }

    func update(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbGroupsProvider.update(group, dirty: remote) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))
            
            if saved && remote {
                self?.remoteGroupsProvider.updateGroup(group) {remoteResult in
                    if let remoteGroup = remoteResult.successResult {
                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroup) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<RemoteGroup>) in
                            print("Error: updating group in remote: \(group), result: \(remoteResult)")
                        }
                    }
                }
            }
        }
    }
    
    func update(groups: [ListItemGroup], remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.update(groups, dirty: remote) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))
            
            if saved && remote {
                self?.remoteGroupsProvider.updateGroups(groups) {remoteResult in
                    if let remoteGroups = remoteResult.successResult {
                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroups) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<RemoteGroup>) in
                            print("Error: updating groups in remote: \(groups), result: \(remoteResult)")
                        }
                    }
                }
            }
        }
    }
    
    func remove(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        removeGroup(group.uuid, remote: remote, handler)
    }

    func removeGroup(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.removeGroup(uuid, markForSync: remote) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if saved && remote {
                self?.remoteGroupsProvider.removeGroup(uuid) {remoteResult in
                    if remoteResult.success {
                        self?.dbGroupsProvider.clearGroupTombstone(uuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for group: \(uuid)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                            print("Error: removing group in remote: \(uuid), result: \(remoteResult)")
                        }
                    }
                }
            }
        }
    }

    func groupItems(group: ListItemGroup, sortBy: InventorySortBy, _ handler: ProviderResult<[GroupItem]> -> Void) {
        DBProviders.groupItemProvider.groupItems(group, sortBy: sortBy) {[weak self] (var dbItems) in
            
            dbItems = dbItems.sortBy(sortBy)
            
            handler(ProviderResult(status: .Success, sucessResult: dbItems))
            
            self?.remoteGroupsProvider.groupsItems(group) {remoteResult in
                
                if let remoteItems = remoteResult.successResult {
                    
                    let items: [GroupItem] = GroupItemMapper.groupItemsWithRemote(remoteItems).groupItems.sortBy(sortBy)
                    
                    if dbItems != items {
                        
                        DBProviders.groupItemProvider.overwrite(items, groupUuid: group.uuid, clearTombstones: true) {saved in
                            if saved {
                                handler(ProviderResult(status: .Success, sucessResult: items))
                                
                            } else {
                                print("Error overwriting group items - couldn't save")
                            }
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                }
            }
        }
    }
    
    // TODO pass a prototype or product+quantity similar to list items. Don't pass a new group item, the creation of the new group item should happen in the db provider, only when one with given semantic unique doesn't exist already.
    func add(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        DBProviders.groupItemProvider.addOrIncrement(item) {[weak self] addedOrIncrementedGroupItemMaybe in
            if let addedOrIncrementedGroupItem = addedOrIncrementedGroupItemMaybe {
                handler(ProviderResult(status: .Success))
                
                if remote {
                    self?.remoteGroupsProvider.addGroupItem(addedOrIncrementedGroupItem) {remoteResult in
                        if let remoteGroupItems = remoteResult.successResult {
                            DBProviders.groupItemProvider.updateLastSyncTimeStamp(remoteGroupItems) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                                QL4("Error adding group item in remote: \(addedOrIncrementedGroupItem), result: \(remoteResult)")
                            }
                        }
                    }
                }
                
            } else {
                print("Error: InventoryItemsProviderImpl.add: Error adding group item")
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }

    func add(items: [GroupItem], group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        DBProviders.groupItemProvider.addOrIncrement(items) {saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    // TODO!!
//                    self?.remoteGroupsProvider.addGroupItem(item, group: group) {remoteResult in
//                        if !remoteResult.success {
//                            print("Error: adding group item in remote: \(item), result: \(remoteResult)")
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func add(itemInput: GroupItemInput, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<GroupItem> -> Void) {
        
        func onHasProduct(product: Product) {
            let groupItem = GroupItem(uuid: NSUUID().UUIDString, quantity: 1, product: product, group: group)
            add(groupItem, remote: remote) {result in
                if result.success {
                    handler(ProviderResult(status: .Success, sucessResult: groupItem))
                } else {
                    print("Error: InventoryItemsProviderImpl.addToInventory: couldn't add to inventory, result: \(result)")
                    handler(ProviderResult(status: .DatabaseUnknown))
                }
            }
        }
        
        Providers.productProvider.product(itemInput.name, brand: itemInput.brand) {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .NotFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                } else {
                    Providers.productCategoryProvider.categoryWithName(itemInput.category) {result in
                        if let category = result.sucessResult {
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, category: category, brand: itemInput.brand)
                            onHasProduct(product)
                        } else {
                            let category = ProductCategory(uuid: NSUUID().UUIDString, name: itemInput.category, color: itemInput.categoryColor)
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, category: category, brand: itemInput.brand)
                            onHasProduct(product)
                        }
                    }
                }
            } else {
                print("Error: InventoryItemsProviderImpl.addToInventory: Error fetching product, result: \(productResult)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    
    func update(input: ListItemInput, updatingGroupItem: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        
        Providers.productProvider.mergeOrCreateProduct(input.name, category: input.section, categoryColor: input.sectionColor, baseQuantity: input.baseQuantity, unit: input.unit, brand: input.brand, updateCategory: false) {[weak self] result in
            
            if let product = result.sucessResult {
                let updatedGroupItem = updatingGroupItem.copy(quantity: input.quantity, product: product)
                self?.update(updatedGroupItem, remote: remote, handler)
            } else {
                QL4("Error fetching product: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func update(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.groupItemProvider.update(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.updateGroupItem(item) {remoteResult in
                        if let remoteListItems = remoteResult.successResult {
                            DBProviders.groupItemProvider.updateLastSyncTimeStamp(remoteListItems) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                                QL4("Error updating group item in remote: \(item), result: \(remoteResult)")
                            }
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }

    func updateGroupsOrder(orderUpdates: [OrderUpdate], remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProviders.listItemGroupProvider.updateGroupsOrder(orderUpdates, dirty: remote) {[weak self] success in
            if success {
                handler(ProviderResult(status: .Success))
                
                if remote {
                    self?.remoteGroupsProvider.updateGroupsOrder(orderUpdates) {remoteResult in
                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
            } else {
                QL4("Error updating lists order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func incrementFav(groupUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.listItemGroupProvider.incrementFav(groupUuid, {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if remote {
                self?.remoteGroupsProvider.incrementFav(groupUuid) {remoteResult in
                    if remoteResult.success {
                        // no timestamp - for increment fav this looks like an overkill. If there's a conflict some favs may get lost - ok
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Remote call no success: \(remoteResult)")
                        })
                    }
                }
            }
        })
    }
    
    func remove(item: GroupItem, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        removeGroupItem(item.uuid, remote: remote, handler)
    }
    
    func removeGroupItem(uuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        DBProviders.groupItemProvider.removeGroupItem(uuid, markForSync: true) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if remote {
                    if saved {
                        self?.remoteGroupsProvider.removeGroupItem(uuid) {remoteResult in
                            if remoteResult.success {
                                DBProviders.groupItemProvider.clearGroupItemTombstone(uuid) {removeTombstoneSuccess in
                                    if !removeTombstoneSuccess {
                                        QL4("Couldn't delete tombstone for group item: \(uuid)")
                                    }
                                }
                            } else {
                                DefaultRemoteErrorHandler.handle(remoteResult, errorMsg: "removeGroupItem\(uuid)", handler: handler)
                            }
                        }
                    } else {
                        QL4("Couldn't remove group item")
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    // Copied from ListItemProviderImpl (which is copied from inventory provider) refactor?
    func increment(groupItem: GroupItem, delta: Int, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        increment(ItemIncrement(delta: delta, itemUuid: groupItem.uuid), remote: remote, handler)
    }
    
    func increment(increment: ItemIncrement, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        DBProviders.groupItemProvider.incrementGroupItem(increment) {[weak self] saved in

            if saved {
                handler(ProviderResult(status: .Success))
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
            
            if remote {
                self?.remoteGroupsProvider.incrementGroupItem(increment) {remoteResult in
                    
                    if let incrementResult = remoteResult.successResult {
                        DBProviders.groupItemProvider.updateGroupItemWithIncrementResult(incrementResult) {success in
                            if !success {
                                QL4("Couldn't save increment result for item: \(increment), remoteResult: \(remoteResult)")
                            }
                        }
                        
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Error incrementing item: \(increment) in remote, result: \(result)")
                            handler(result)
                        })
                    }
                }
            }
        }
    }
}