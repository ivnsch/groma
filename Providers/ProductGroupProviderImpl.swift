//
//  ProductGroupProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs
import RealmSwift

class ProductGroupProviderImpl: ProductGroupProvider {

    let dbGroupsProvider = RealmProductGroupProvider()
    let remoteGroupsProvider = RemoteGroupsProvider()

    
    func groups(sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<Results<ProductGroup>>) -> Void) {
        dbGroupsProvider.groups(sortBy: sortBy) {(groups: Results<ProductGroup>?) in
            if let groups = groups {
                handler(ProviderResult(status: .success, sucessResult: groups))
            } else {
                QL4("Couldn't load groups")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // TODO don't use QuickAddItemSortBy here, map to a (new) group specific enum
    func groups(_ range: NSRange, sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<[ProductGroup]>) -> Void) {
        dbGroupsProvider.groups(range, sortBy: sortBy) {dbGroups in
            
//            let sotedDBGroups: [ProductGroup] = {
//                if sortBy == .order {
//                    return dbGroups.sortedByOrder() // include name in sorting to guarantee equal ordering with remote result, in case of duplicate order fields
//                } else {
//                    return dbGroups
//                }
//            }()
            
            handler(ProviderResult(status: .success, sucessResult: dbGroups))

            // Disabled while impl. realm sync
//            self?.remoteGroupsProvider.groups {remoteResult in
//                
//                if let remoteGroups = remoteResult.successResult {
//                    let groups: [ProductGroup] = remoteGroups.map{ProductGroupMapper.listItemGroupWithRemote($0)}
//                    let sortedGroups = groups.sortedByOrder()
//                    
//                    if sotedDBGroups != sortedGroups {
//                        self?.dbGroupsProvider.overwrite(groups, clearTombstones: true) {saved in
//                            if saved {
//                                handler(ProviderResult(status: .success, sucessResult: sortedGroups))
//                                
//                            } else {
//                                QL4("Error updating groups - coulnd't save remote groups")
//                            }
//                        }
//                    }
//                    
//                } else {
//                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                }
//            }
            
        }
    }
    
    func groups(_ text: String, range: NSRange, sortBy: GroupSortBy, _ handler: @escaping (ProviderResult<(substring: String?, groups: [ProductGroup])>) -> Void) {
        dbGroupsProvider.groups(text, range: range, sortBy: sortBy) {groups in
            handler(ProviderResult(status: .success, sucessResult: groups))
        }
    }

    func add(_ group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbGroupsProvider.add(group, dirty: remote) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseSavingError))

            // Disabled while impl. realm sync
//            if saved && remote {
//                self?.remoteGroupsProvider.addGroup(group) {remoteResult in
//                    if let remoteGroup = remoteResult.successResult {
//                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroup) {success in
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                    }
//                }
//            }
        }
    }
    
    func addGroupItems(_ srcGroup: ProductGroup, targetGroup: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<[(groupItem: GroupItem, delta: Float)]>) -> Void) {
        groupItems(srcGroup, sortBy: .alphabetic, fetchMode: .memOnly) {[weak self] result in
            if let groupItems = result.sucessResult {
                if groupItems.isEmpty {
                    handler(ProviderResult(status: .isEmpty))
                } else {
                    let productsWithQuantities: [(product: QuantifiableProduct, quantity: Float)] = groupItems.map{($0.product, $0.quantity)}
                    self?.add(targetGroup, productsWithQuantities: productsWithQuantities, remote: remote) {result in
                        // return fetched group items to the caller
                        if let groupItems = result.sucessResult {
                            handler(ProviderResult(status: .success, sucessResult: groupItems))
                        } else {
                            print("Error: ProductGroupProviderImpl.addGroupItems: Couldn't save group items for group: \(targetGroup)")
                            handler(ProviderResult(status: result.status))
                        }
                    }
                }
            } else {
                print("Error: ProductGroupProviderImpl.addGroupItems: Can't get group items for group: \(srcGroup)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func update(_ group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        dbGroupsProvider.update(group, dirty: remote) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseSavingError))
            
            // Disabled while impl. realm sync
//            if saved && remote {
//                self?.remoteGroupsProvider.updateGroup(group) {remoteResult in
//                    if let remoteGroup = remoteResult.successResult {
//                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroup) {success in
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<RemoteGroup>) in
//                            print("Error: updating group in remote: \(group), result: \(remoteResult)")
//                        }
//                    }
//                }
//            }
        }
    }
    
    func update(_ groups: [ProductGroup], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbGroupsProvider.update(groups, dirty: remote) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseSavingError))

            // Disabled while impl. realm sync
//            if saved && remote {
//                self?.remoteGroupsProvider.updateGroups(groups) {remoteResult in
//                    if let remoteGroups = remoteResult.successResult {
//                        self?.dbGroupsProvider.updateLastSyncTimeStamp(remoteGroups) {success in
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<RemoteGroup>) in
//                            print("Error: updating groups in remote: \(groups), result: \(remoteResult)")
//                        }
//                    }
//                }
//            }
        }
    }
    
    func remove(_ group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        removeGroup(group.uuid, remote: remote, handler)
    }

    func removeGroup(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbGroupsProvider.removeGroup(uuid, markForSync: remote) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))

            // Disabled while impl. realm sync
//            if saved && remote {
//                self?.remoteGroupsProvider.removeGroup(uuid) {remoteResult in
//                    if remoteResult.success {
//                        self?.dbGroupsProvider.clearGroupTombstone(uuid) {removeTombstoneSuccess in
//                            if !removeTombstoneSuccess {
//                                QL4("Couldn't delete tombstone for group: \(uuid)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                            print("Error: removing group in remote: \(uuid), result: \(remoteResult)")
//                        }
//                    }
//                }
//            }
        }
    }

    func groupItems(_ group: ProductGroup, sortBy: InventorySortBy, fetchMode: ProviderFetchModus, _ handler: @escaping (ProviderResult<Results<GroupItem>>) -> Void) {
        DBProv.groupItemProvider.groupItems(group, sortBy: sortBy) {dbItems in
         
            
            if let dbItems = dbItems {
                handler(ProviderResult(status: .success, sucessResult: dbItems))
            } else {
                QL4("Inventory items is nil")
                handler(ProviderResult(status: .unknown))
            }
            
            if fetchMode == .memOnly {
                return
            }
            
            // Disabled while impl. realm sync
//            self?.remoteGroupsProvider.groupsItems(group) {remoteResult in
//                
//                if let remoteItems = remoteResult.successResult {
//                    
//                    let items: [GroupItem] = GroupItemMapper.groupItemsWithRemote(remoteItems).groupItems.sortBy(sortBy)
//                    
//                    if sortedDbItems != items {
//                        
//                        DBProv.groupItemProvider.overwrite(items, groupUuid: group.uuid, clearTombstones: true) {saved in
//                            if saved {
//                                handler(ProviderResult(status: .success, sucessResult: items))
//                                
//                            } else {
//                                print("Error overwriting group items - couldn't save")
//                            }
//                        }
//                    }
//                    
//                } else {
//                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                }
//            }
        }
    }
    
    // TODO pass a prototype or product+quantity similar to list items. Don't pass a new group item, the creation of the new group item should happen in the db provider, only when one with given semantic unique doesn't exist already.
    func add(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<GroupItem>) -> Void) {
        DBProv.groupItemProvider.addOrIncrement(item, dirty: remote) {addedOrIncrementedGroupItemMaybe in
            if let addedOrIncrementedGroupItem = addedOrIncrementedGroupItemMaybe {
                handler(ProviderResult(status: .success, sucessResult: addedOrIncrementedGroupItem))
                
                // Disabled while impl. realm sync - access of realm objs here causes wrong thread exception
//                if remote {
//                    self?.remoteGroupsProvider.addGroupItem(addedOrIncrementedGroupItem) {remoteResult in
//                        if let remoteGroupItems = remoteResult.successResult {
//                            DBProv.groupItemProvider.updateLastSyncTimeStamp(remoteGroupItems) {success in
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                                QL4("Error adding group item in remote: \(addedOrIncrementedGroupItem), result: \(remoteResult)")
//                            }
//                        }
//                    }
//                }
                
            } else {
                print("Error: InventoryItemsProviderImpl.add: Error adding group item")
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // new - decouple input from actual source by passing only product+quantity. TODO make other methods where this is usable also use it
    
    func add(_ group: ProductGroup, productsWithQuantities: [(product: QuantifiableProduct, quantity: Float)], remote: Bool, _ handler: @escaping (ProviderResult<[(groupItem: GroupItem, delta: Float)]>) -> Void) {
        DBProv.groupItemProvider.addOrIncrement(group, productsWithQuantities: productsWithQuantities, dirty: remote) {addedOrIncrementedGroupItemsMaybe in
            if let addedOrIncrementedGroupItems = addedOrIncrementedGroupItemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: addedOrIncrementedGroupItems))
//                
//                let groupItems = addedOrIncrementedGroupItems.map{$0.groupItem}
//                
                // Disabled while impl. realm sync
//                if remote {
//                    self?.remoteGroupsProvider.addGroupItems(groupItems) {remoteResult in
//                        if let remoteInventoryItems = remoteResult.successResult {
//                            DBProv.groupItemProvider.updateLastSyncTimeStamp(remoteInventoryItems) {success in
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
                
            } else {
                QL4("Unknown error adding to group in local db, group: \(group), productsWithQuantities: \(productsWithQuantities)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    ////////////////////////////////////////////////////////////////////////////////
    
    func addOrUpdateLocal(_ groupItems: [GroupItem], _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.groupItemProvider.addOrUpdate(groupItems, update: true, dirty: false) {updated in
            handler(ProviderResult(status: updated ? .success : .databaseUnknown))
        }
    }
    
    func add(_ items: [GroupItem], group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.groupItemProvider.addOrIncrement(items, dirty: remote) {saved in
            if saved {
                handler(ProviderResult(status: .success))
                
                if saved {
                    
                    // Disabled while impl. realm sync
//                    self?.remoteGroupsProvider.addGroupItems(items) {remoteResult in
//                        if let remoteGroupItems = remoteResult.successResult {
//                            DBProv.groupItemProvider.updateLastSyncTimeStamp(remoteGroupItems) {success in
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
                }
            } else {
                QL4("Error saving items to local db: \(items)")
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }
    
    func add(_ itemInput: GroupItemInput, group: ProductGroup, remote: Bool, _ handler: @escaping (ProviderResult<GroupItem>) -> Void) {
        
        func onHasProduct(_ product: QuantifiableProduct) {
            let groupItem = GroupItem(uuid: UUID().uuidString, quantity: 1, product: product, group: group)
            add(groupItem, remote: remote) {result in
                if result.success {
                    handler(ProviderResult(status: .success, sucessResult: groupItem))
                } else {
                    print("Error: InventoryItemsProviderImpl.addToInventory: couldn't add to inventory, result: \(result)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
            }
        }
        
        QL4("Outdated implementation")
        handler(ProviderResult(status: .unknown))
        // Commented because structural changes
//        Prov.productProvider.product(itemInput.name, brand: itemInput.brand) {productResult in
//            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
//            if productResult.success || productResult.status == .notFound {
//                if let product = productResult.sucessResult {
//                    onHasProduct(product)
//                } else {
//                    Prov.productCategoryProvider.categoryWithName(itemInput.category) {result in
//                        if let category = result.sucessResult {
//                            let product = Product(uuid: UUID().uuidString, name: itemInput.name, category: category, brand: itemInput.brand)
//                            onHasProduct(product)
//                        } else {
//                            let category = ProductCategory(uuid: UUID().uuidString, name: itemInput.category, color: itemInput.categoryColor)
//                            let product = Product(uuid: UUID().uuidString, name: itemInput.name, category: category, brand: itemInput.brand)
//                            onHasProduct(product)
//                        }
//                    }
//                }
//            } else {
//                print("Error: InventoryItemsProviderImpl.addToInventory: Error fetching product, result: \(productResult)")
//                handler(ProviderResult(status: .databaseUnknown))
//            }
//        }
    }
    
    
    func update(_ input: ListItemInput, updatingGroupItem: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<(groupItem: GroupItem, replaced: Bool)>) -> Void) {
        
        // Remove a possible already existing item with same unique (name+brand) in the same list. Exclude editing item - since this is not being executed in a transaction with the upsert of the item, we should not remove it.
        let quantifiableProductUnique = QuantifiableProductUnique(name: input.name, brand: input.brand, unit: input.storeProductInput.unit, baseQuantity: input.storeProductInput.baseQuantity)
        DBProv.groupItemProvider.deletePossibleGroupItem(quantifiableProductUnique: quantifiableProductUnique, group: updatingGroupItem.group, notUuid: updatingGroupItem.uuid) {foundAndDeletedGroupItem in
            // Point to possible existing product with same semantic unique / create a new one instead of updating underlying product, which would lead to surprises in other screens.
            
            // TODO units? for now doesn't matter since we are not going to continue using groups
            let prototype = ProductPrototype(name: input.name, category: input.section, categoryColor: input.sectionColor, brand: input.brand, baseQuantity: "1", unit: .none)
            Prov.productProvider.mergeOrCreateProduct(prototype: prototype, updateCategory: false, updateItem: false) {[weak self] (result: ProviderResult<QuantifiableProduct>) in
                
                if let product = result.sucessResult {
                    let updatedGroupItem = updatingGroupItem.copy(quantity: input.quantity, product: product)
                    self?.update(updatedGroupItem, remote: remote) {result in
                        if result.success {
                            handler(ProviderResult(status: .success, sucessResult: (groupItem: updatedGroupItem, replaced: foundAndDeletedGroupItem)))
                        } else {
                            QL4("Error updating group item: \(result)")
                            handler(ProviderResult(status: result.status))
                        }
                    }
                } else {
                    QL4("Error fetching product: \(result.status)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
            }
        }
    }
    
    func update(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.groupItemProvider.update(item, dirty: remote) {saved in
            if saved {
                handler(ProviderResult(status: .success))
                
                // Disabled while impl. realm sync
//                if saved {
//                    self?.remoteGroupsProvider.updateGroupItem(item) {remoteResult in
//                        if let remoteListItems = remoteResult.successResult {
//                            DBProv.groupItemProvider.updateLastSyncTimeStamp(remoteListItems) {success in
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                                QL4("Error updating group item in remote: \(item), result: \(remoteResult)")
//                            }
//                        }
//                    }
//                }
                
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }

    func updateGroupsOrder(_ orderUpdates: [OrderUpdate], remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        // dirty == remote: if we want to do a remote call, it means the update is client triggered (opposed to e.g. processing a websocket message) which means the data is not in the server yet, which means it's dirty.
        DBProv.listItemGroupProvider.updateGroupsOrder(orderUpdates, dirty: remote) {success in
            if success {
                handler(ProviderResult(status: .success))
                
                // Disabled while impl. realm sync
//                if remote {
//                    self?.remoteGroupsProvider.updateGroupsOrder(orderUpdates) {remoteResult in
//                        // Note: no server update timetamps here, because server implementation details, more info see note in RemoteOrderUpdate
//                        if !remoteResult.success {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                        }
//                    }
//                }
            } else {
                QL4("Error updating lists order in local database, orderUpdates: \(orderUpdates)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func incrementFav(_ groupUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.listItemGroupProvider.incrementFav(groupUuid, {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))

            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteGroupsProvider.incrementFav(groupUuid) {remoteResult in
//                    if remoteResult.success {
//                        // no timestamp - for increment fav this looks like an overkill. If there's a conflict some favs may get lost - ok
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            QL4("Remote call no success: \(remoteResult)")
//                        })
//                    }
//                }
//            }
        })
    }
    
    func remove(_ item: GroupItem, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        removeGroupItem(item.uuid, remote: remote, handler)
    }
    
    func removeGroupItem(_ uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.groupItemProvider.removeGroupItem(uuid, markForSync: true) {saved in
            if saved {
                handler(ProviderResult(status: .success))

                // Disabled while impl. realm sync
//                if remote {
//                    if saved {
//                        self?.remoteGroupsProvider.removeGroupItem(uuid) {remoteResult in
//                            if remoteResult.success {
//                                DBProv.groupItemProvider.clearGroupItemTombstone(uuid) {removeTombstoneSuccess in
//                                    if !removeTombstoneSuccess {
//                                        QL4("Couldn't delete tombstone for group item: \(uuid)")
//                                    }
//                                }
//                            } else {
//                                DefaultRemoteErrorHandler.handle(remoteResult, errorMsg: "removeGroupItem\(uuid)", handler: handler)
//                            }
//                        }
//                    } else {
//                        QL4("Couldn't remove group item")
//                    }
//                }
                
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }
    
    // Copied from ListItemProviderImpl (which is copied from inventory provider) refactor?
    func increment(_ groupItem: GroupItem, delta: Float, remote: Bool, _ handler: @escaping (ProviderResult<Float>) -> Void) {
        increment(ItemIncrement(delta: delta, itemUuid: groupItem.uuid), remote: remote, handler)
    }
    
    func increment(_ increment: ItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<Float>) -> Void) {
        DBProv.groupItemProvider.incrementGroupItem(increment, dirty: remote) {updatedQuantityMaybe in

            if let updatedQuantity = updatedQuantityMaybe {
                handler(ProviderResult(status: .success, sucessResult: updatedQuantity))
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }

            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteGroupsProvider.incrementGroupItem(increment) {remoteResult in
//                    
//                    if let incrementResult = remoteResult.successResult {
//                        DBProv.groupItemProvider.updateGroupItemWithIncrementResult(incrementResult) {success in
//                            if !success {
//                                QL4("Couldn't save increment result for item: \(increment), remoteResult: \(remoteResult)")
//                            }
//                        }
//                        
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Int>) in
//                            QL4("Error incrementing item: \(increment) in remote, result: \(result)")
//                            handler(result)
//                        })
//                    }
//                }
//            }
        }
    }
}
