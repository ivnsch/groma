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
    
    func groups(range: NSRange, _ handler: ProviderResult<[ListItemGroup]> -> Void) {
        dbGroupsProvider.groups(range) {groups in
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
        
        Providers.productProvider.product(itemInput.name) {productResult in
            // TODO consistent handling everywhere of optional results - return always either .Success & Option(None) or .NotFound & non-optional.
            if productResult.success || productResult.status == .NotFound {
                if let product = productResult.sucessResult {
                    onHasProduct(product)
                } else {
                    Providers.productCategoryProvider.categoryWithName(itemInput.category) {result in
                        if let category = result.sucessResult {
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit)
                            onHasProduct(product)
                        } else {
                            let category = ProductCategory(uuid: NSUUID().UUIDString, name: itemInput.category, color: itemInput.categoryColor)
                            let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit)
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
}