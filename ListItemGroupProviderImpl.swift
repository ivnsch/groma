//
//  ListItemGroupProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

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
        dbGroupsProvider.groups(range, sortBy: sortBy) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }
    
    func groupsContainingText(text: String, _ handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groupsContainingText(text) {groups in
            handler(ProviderResult(status: .Success, sucessResult: groups))
        }
    }

    func add(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.add(group) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))

            if saved && remote {
                self?.remoteGroupsProvider.addGroup(group) {remoteResult in
                    if !remoteResult.success {
                        print("Error: adding group in remote: \(group), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func update(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        update([group], remote: remote, handler)
    }
    
    func update(groups: [ListItemGroup], remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.update(groups) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseSavingError))
            
            if saved && remote {
                self?.remoteGroupsProvider.updateGroups(groups) {remoteResult in
                    if !remoteResult.success {
                        print("Error: updating groups in remote: \(groups), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func remove(group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.remove(group) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if saved && remote {
                self?.remoteGroupsProvider.removeGroup(group) {remoteResult in
                    if !remoteResult.success {
                        print("Error: removing group in remote: \(group), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
            }
        }
    }
    
    func groupItems(group: ListItemGroup, _ handler: ProviderResult<[GroupItem]> -> Void) {
        dbGroupsProvider.groupItems(group) {items in
            handler(ProviderResult(status: .Success, sucessResult: items))
        }
    }
    
    func add(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.addOrIncrement(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.addGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: adding group item in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
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
        dbGroupsProvider.addOrIncrement(items) {saved in
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
            add(groupItem, group: group, remote: remote) {result in
                if result.success {
                    handler(ProviderResult(status: .Success, sucessResult: groupItem))
                } else {
                    print("Error: InventoryItemsProviderImpl.addToInventory: couldn't add to inventory, result: \(result)")
                    handler(ProviderResult(status: .DatabaseUnknown))
                }
            }
        }
        
        Providers.productProvider.product(itemInput.name, brand: itemInput.brand ?? "") {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .NotFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                } else {
                    Providers.productCategoryProvider.categoryWithName(itemInput.category) {result in
                        if let category = result.sucessResult {
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit, brand: itemInput.brand)
                            onHasProduct(product)
                        } else {
                            let category = ProductCategory(uuid: NSUUID().UUIDString, name: itemInput.category, color: itemInput.categoryColor)
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit, brand: itemInput.brand)
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
    
    func update(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbGroupsProvider.update(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.updateGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: updating group item in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func remove(item: GroupItem, group: ListItemGroup, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbGroupsProvider.remove(item) {[weak self] saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                if saved {
                    self?.remoteGroupsProvider.removeGroupItem(item, group: group) {remoteResult in
                        if !remoteResult.success {
                            print("Error: removeGroupItem in remote: \(item), result: \(remoteResult)")
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                        }
                    }
                }
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    // Copied from ListItemProviderImpl (which is copied from inventory provider) refactor?
    func increment(listItem: GroupItem, delta: Int, _ handler: ProviderResult<Any> -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
//        let memIncremented = memProvider.increment(listItem, quantity: ListItemStatusQuantity(status: .Todo, quantity: delta))
//        if memIncremented {
//            handler(ProviderResult(status: .Success))
//        }
        
        dbGroupsProvider.incrementGroupItem(listItem, delta: delta) {saved in
//            
//            if !memIncremented { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if saved {
                    handler(ProviderResult(status: .Success))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
//            }
            
            //            print("SAVED DB \(item)(+delta) in local db. now going to update remote")
            
            // TODO!! no server for gorup item increment yet
//            self?.remoteGroupsProvider.incrementGroupItem(listItem, delta: delta) {remoteResult in
//                
//                if remoteResult.success {
//                    
//                    //                    //                    print("SAVED REMOTE will revert delta now in local db for \(item.product.name), with delta: \(-delta)")
//                    //
//                    //                    // Now that the item was updated in server, set back delta in local database
//                    //                    // Note we subtract instead of set to 0, to handle possible parallel requests correctly
//                    //                    self?.dbInventoryProvider.incrementInventoryItem(listItem, delta: -delta, onlyDelta: true) {saved in
//                    //
//                    //                        if saved {
//                    //                            //                            self?.findInventoryItem(item) {result in
//                    //                            //                                if let newitem = result.sucessResult {
//                    //                            //                                    print("3. CONFIRM incremented item: \(item) + \(delta) == \(newitem)")
//                    //                            //                                }
//                    //                            //                            }
//                    //
//                    //                        } else {
//                    //                            print("Error: couln't save remote list item")
//                    //                        }
//                    //
//                    //                    }
//                    
//                } else {
//                    print("Error incrementing item: \(listItem) in remote, result: \(remoteResult)")
//                    DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                        // if there's a not connection related server error, invalidate cache
//                        self?.memProvider.invalidate()
//                        handler(remoteResult)
//                    }
//                }
//            }
        }
    }
    
}