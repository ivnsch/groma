//
//  RealmGroupItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class RealmGroupItemProvider: RealmProvider {
    
    func groupItems(_ group: ProductGroup, sortBy: InventorySortBy, handler: @escaping (Results<GroupItem>?) -> Void) {
        // Fixes Realm acces in incorrect thread exceptions
        let groupCopy = group.copy()
        
        do {
            let realm = try Realm()
            
            
            let sortData: (key: String, ascending: Bool) = {
                switch sortBy {
                case .alphabetic: return ("name", true)
                case .count: return ("quantity", false)
                }
            }()
            
            let items: Results<GroupItem> = self.loadSync(realm, filter: GroupItem.createFilterGroup(groupCopy.uuid), sortDescriptor: SortDescriptor(property: sortData.key, ascending: sortData.ascending))
            handler(items)
            
        } catch let e {
            QL4("Error: creating Realm, returning empty results, error: \(e)")
            handler(nil)
        }
    }
    
    func add(_ groupItem: GroupItem, dirty: Bool, handler: @escaping (Bool) -> Void) {
        addOrUpdate(groupItem, dirty: dirty, handler: handler)
    }
    
    ///////////////////////////////////////////////////////////////
    // New - add/increment using only product + quantity, like in inventory, no fake/input group items
    
    func addOrIncrement(_ group: ProductGroup, productsWithQuantities: [(product: Product, quantity: Int)], dirty: Bool, _ handler: @escaping ([(groupItem: GroupItem, delta: Int)]?) -> Void) {
        doInWriteTransaction({[weak self] realm in guard let weakSelf = self else {return nil}
            
            var addedOrIncrementedItems: [(groupItem: GroupItem, delta: Int)] = []
            for productsWithQuantity in productsWithQuantities {
                let groupItem = weakSelf.addOrIncrementGroupItem(realm, group: group, product: productsWithQuantity.product, quantity: productsWithQuantity.quantity, dirty: dirty)
                addedOrIncrementedItems.append(groupItem)
            }
            return addedOrIncrementedItems
            
            }, finishHandler: {(addedOrIncrementedItems: [(groupItem: GroupItem, delta: Int)]?) in
                handler(addedOrIncrementedItems)
        })
    }
    
    fileprivate func addOrIncrementGroupItem(_ realm: Realm, group: ProductGroup, product: Product, quantity: Int, dirty: Bool) -> (groupItem: GroupItem, delta: Int) {
        
        // increment if already exists (currently there doesn't seem to be any functionality to do this using Realm so we do it manually)
        let existingGroupItems: [GroupItem] = loadSync(realm, filter: GroupItem.createFilter(product, group: group))
        
        let addedOrIncrementedGroupItem: GroupItem = {
            if let existingGroupItem = existingGroupItems.first {
                let existingQuantity = existingGroupItem.quantity
                
                return existingGroupItem.copy(quantity: quantity + existingQuantity)
                
            } else { // if item doesn't exist there's nothing to increment
                return GroupItem(uuid: UUID().uuidString, quantity: quantity, product: product, group: group)
            }
        }()
    
        // save
        realm.add(addedOrIncrementedGroupItem, update: true)
        
        return (groupItem: addedOrIncrementedGroupItem, delta: quantity)
    }
    
    ///////////////////////////////////////////////////////////////
    
    
    // param groupItems: Important: There are the input group items - not the target group items! This is when we add a group to a group - the input group items belong to the group that we are adding. This is equivalent to adding prototypes, products or group items to list/inventory.
    func addOrIncrement(_ groupItems: [GroupItem], dirty: Bool, handler: @escaping (Bool) -> Void) {
        
        func addOrIncrement(_ groupItems: [GroupItem]) -> Bool {
            do {
                // load items
                let realm = try Realm()

                let items: [GroupItem] = self.loadSync(realm, filter: GroupItem.createFilterGroupItemsUuids(groupItems))
//                let items: [GroupItem] = realm.objects(GroupItem.self).filter(GroupItem.createFilterGroupItemsUuids(groupItems))
                
                // decide if add/increment
                let dict: [String: GroupItem] = items.toDictionary{($0.uuid, $0)}
                let newOrIncrementedGroupItems: [GroupItem] = groupItems.map {groupItem in
                    return {
                        if let storedGroupItem = dict[groupItem.uuid] { // item exists - update existing one with incremented copy
                            return storedGroupItem.incrementQuantityCopy(groupItem.quantity)
                        } else { // item doesn't exist - create a new one
                            return groupItem
                        }
                    }()
                }

                //save
                try realm.write {
                    for obj in newOrIncrementedGroupItems {
                        realm.add(obj, update: true)
                    }
                }
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(_ success: Bool) {
            DispatchQueue.main.async(execute: {
                handler(success)
            })
        }

        let groupItemsCopy = groupItems.map{$0.copy()} // copy fixes Realm acces in incorrect thread exceptions
        
        DispatchQueue.global(qos: .background).async {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItemsCopy)
                }
                finished(success)
            } else {
                print("Error: RealmProductGroupProvider.addOrIncrement: no self")
                finished(false)
            }
        }
    }
    
    func addOrIncrement(_ groupItem: GroupItem, dirty: Bool, handler: @escaping (GroupItem?) -> Void) {
        
        func addOrIncrement(_ item: GroupItem) -> GroupItem? {
            do {
                let realm = try Realm()
                // TODO!! why looking here for unique instead of uuid? when add group item with product we should be able to find the product using only the uuid?
                if let item: GroupItem = loadSync(realm, filter: GroupItem.createFilterGroupAndProductName(item.group.uuid, productName: item.product.name, productBrand: item.product.brand)).first {
                    let incremented = item.incrementQuantityCopy(groupItem.quantity)
                    _ = saveObjSync(incremented, update: true)
                    return incremented
                } else {
                    _ = saveObjSync(item, update: true)
                    return groupItem
                }
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return nil // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(_ groupItemMaybe: GroupItem?) {
            DispatchQueue.main.async(execute: {
                handler(groupItemMaybe)
            })
        }
        
        let groupItemsCopy = groupItem.copy() // copy fixes Realm acces in incorrect thread exceptions
        
        DispatchQueue.global(qos: .background).async {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItemsCopy)
                }
                finished(success)
            } else {
                print("Error: RealmProductGroupProvider.addOrIncrement: no self")
                finished(nil)
            }
        }
    }
    
    func update(_ groupItem: GroupItem, dirty: Bool, handler: @escaping (Bool) -> Void) {
        addOrUpdate(groupItem, dirty: dirty, handler: handler)
    }
    
    func addOrUpdate(_ groupItem: GroupItem, dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbObj = groupItem.copy()
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func addOrUpdate(_ groupItems: [GroupItem], update: Bool =  true, dirty: Bool, handler: @escaping (Bool) -> Void) {
        let dbObjs = groupItems.map{$0.copy()}
        self.saveObjs(dbObjs, update: update, handler: handler)
    }
    
    func remove(_ groupItem: GroupItem, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        removeGroupItem(groupItem.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeGroupItem(_ uuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        // Needs custom handling because we need the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({realm in
            if let itemToRemove = realm.objects(GroupItem.self).filter(GroupItem.createFilter(uuid)).first {
                if markForSync {
                    let toRemove = DBRemoveGroupItem(itemToRemove)
                    realm.add(toRemove, update: true)
                }
                realm.delete(itemToRemove)
            }
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    func deletePossibleGroupItemWithUnique(_ productName: String, productBrand: String, group: ProductGroup, notUuid: String, handler: @escaping (Bool) -> Void) {
        removeReturnCount(GroupItem.createFilterGroupAndProductName(group.uuid, productName: productName, productBrand: productBrand, notUuid: notUuid), handler: {removedCountMaybe in
            if let removedCount = removedCountMaybe {
                if removedCount > 0 {
                    QL2("Found group item with same name+brand in list, deleted it. Name: \(productName), brand: \(productBrand), group: {\(group.uuid), \(group.name)}")
                }
            } else {
                QL4("Remove didn't succeed: Name: \(productName), brand: \(productBrand), list: {\(group.uuid), \(group.name)}")
            }
            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: GroupItem.self)
    }
    
    
    // Expected to be executed in do/catch and write block
    func removeGroupItemsForGroupSync(_ realm: Realm, groupUuid: String, markForSync: Bool) -> Bool {
        let dbGroupItems = realm.objects(GroupItem.self).filter(GroupItem.createFilterGroup(groupUuid))
        for dbGroupItem in dbGroupItems {
            removeGroupItemSync(realm, dbGroupItem: dbGroupItem, markForSync: markForSync)
        }
        return true
    }

    func removeGroupItemsForProductSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let dbGroupItems = realm.objects(GroupItem.self).filter(GroupItem.createFilterProduct(productUuid))
        for dbGroupItem in dbGroupItems {
            removeGroupItemSync(realm, dbGroupItem: dbGroupItem, markForSync: markForSync)
        }
        return true
    }
    
    func removeGroupItemSync(_ realm: Realm, dbGroupItem: GroupItem, markForSync: Bool) {
        if markForSync {
            let toRemoveGroupItem = DBRemoveGroupItem(dbGroupItem)
            realm.add(toRemoveGroupItem, update: true)
        }
        realm.delete(dbGroupItem)
    }
    
    func overwrite(_ items: [GroupItem], groupUuid: String, clearTombstones: Bool, handler: @escaping (Bool) -> Void) {
        let dbObjs: [GroupItem] = items.map{$0.copy()}
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilterWithGroup(groupUuid))} : nil
        self.overwrite(dbObjs, deleteFilter: GroupItem.createFilterGroup(groupUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    // Copied from realm list item provider (which is copied from inventory item provider) refactor?
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    func incrementGroupItem(_ item: GroupItem, delta: Int, dirty: Bool, handler: @escaping (Int?) -> Void) {
        incrementGroupItem(ItemIncrement(delta: delta, itemUuid: item.uuid), dirty: dirty, handler: handler)
    }
    
    func incrementGroupItem(_ increment: ItemIncrement, dirty: Bool, handler: @escaping (Int?) -> Void) {
        
        doInWriteTransaction({realm in
            
            syncedRet(self) {
                
                let results = realm.objects(GroupItem.self).filter(GroupItem.self.createFilter(increment.itemUuid)).toArray()
                
                if let groupItem = results.first {
                    let incrementedGroupItem = groupItem.incrementQuantityCopy(increment.delta)
                    
                    realm.add(incrementedGroupItem, update: true)
                    
                    return incrementedGroupItem.quantity
                    
                } else {
                    QL3("Inventory item not found: \(increment.itemUuid)")
                    return nil
                }
            }
            
            }) {(updatedQuantityMaybe: Int?) in
                QL2("Calling handler")
                handler(updatedQuantityMaybe)
        }
    }
    
    // MARK: - Sync
    
    func clearGroupItemTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearGroupItemTombstonesForGroup(_ groupUuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilterWithGroup(groupUuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    func updateGroupItemLastUpdate(_ updateDict: [String: AnyObject], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateGroupItemLastUpdate(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateGroupItemLastUpdate(_ realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(GroupItem.self, value: updateDict, update: true)
    }
    
    func updateLastSyncTimeStamp(_ items: RemoteGroupItemsWithDependencies, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            for listItem in items.groupItems {
                realm.create(GroupItem.self, value: listItem.timestampUpdateDict, update: true)
            }
            for product in items.products {
                DBProv.productProvider.updateLastSyncTimeStampSync(realm, product: product)
            }
            for productCategory in items.productsCategories {
                realm.create(ProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for group in items.groups {
                DBProv.listItemGroupProvider.updateLastSyncTimeStampSync(realm, group: group)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateGroupItemWithIncrementResult(_ incrementResult: RemoteIncrementResult, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(GroupItem.self).filter(GroupItem.self.createFilter(incrementResult.uuid)).first) {
                
                // store the timestamp only if it matches with the current quantity. E.g. if user increments very quicky 1,2,3,4,5,6
                // we may receive the response from server for 1 when the database is already at 4 - so we don't want to store 1's timestamp for 4. When the user stops at 6 only the timestamp with the response with 6 quantity will be stored.
                if storedItem.quantity == incrementResult.updatedQuantity {
                    // Notes & todo see equivalent method for list items
                    if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                        
                        let updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                        realm.create(GroupItem.self, value: updateDict, update: true)
                        QL1("Updateded group item with increment result dict: \(updateDict)")
                        
                    } else {
                        QL3("Warning: got result with smaller timestamp: \(incrementResult), ignoring")
                    }
                } else {
                    QL1("Received increment result with outdated quantity: \(incrementResult.updatedQuantity)")
                }

            } else {
                QL3("Didn't find item for: \(incrementResult)")
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
}
