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
    
    func groupItems(group: ListItemGroup, sortBy: InventorySortBy, handler: [GroupItem] -> Void) {
        let mapper = {GroupItemMapper.groupItemWith($0)}
        self.load(mapper, filter: DBGroupItem.createFilterGroup(group.uuid), handler: handler)
    }
    
    func add(groupItem: GroupItem, dirty: Bool, handler: Bool -> Void) {
        addOrUpdate(groupItem, dirty: dirty, handler: handler)
    }
    
    func addOrIncrement(groupItems: [GroupItem], dirty: Bool, handler: Bool -> Void) {
        
        func addOrIncrement(groupItems: [GroupItem]) -> Bool {
            do {
                // load items
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                
                let items = loadSync(realm, mapper: mapper, filter: DBGroupItem.createFilterGroupItemsUuids(groupItems))
                // decide if add/increment
                let dict: [String: GroupItem] = items.toDictionary{($0.uuid, $0)}
                let newOrIncrementedGroupItems: [DBGroupItem] = groupItems.map {groupItem in
                    let item: GroupItem = {
                        if let storedGroupItem = dict[groupItem.uuid] { // item exists - update existing one with incremented copy
                            return storedGroupItem.incrementQuantityCopy(groupItem.quantity)
                        } else { // item doesn't exist - create a new one
                            return groupItem
                        }
                    }()
                    return GroupItemMapper.dbWith(item, dirty: dirty)
                }
                //save
                saveObjsSync(newOrIncrementedGroupItems, update: true)
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(success: Bool) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItems)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(false)
            }
            })
    }
    
    func addOrIncrement(groupItem: GroupItem, dirty: Bool, handler: GroupItem? -> Void) {
        
        func addOrIncrement(item: GroupItem) -> GroupItem? {
            do {
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                // TODO!! why looking here for unique instead of uuid? when add group item with product we should be able to find the product using only the uuid?
                if let item = loadSync(realm, mapper: mapper, filter: DBGroupItem.createFilterGroupAndProductName(groupItem.group.uuid, productName: groupItem.product.name, productBrand: groupItem.product.brand)).first {
                    let incremented = item.incrementQuantityCopy(groupItem.quantity)
                    let dbItem = GroupItemMapper.dbWith(incremented, dirty: dirty)
                    saveObjSync(dbItem, update: true)
                    return incremented
                } else {
                    let dbItem = GroupItemMapper.dbWith(groupItem, dirty: dirty)
                    saveObjSync(dbItem, update: true)
                    return groupItem
                }
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return nil // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(groupItemMaybe: GroupItem?) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(groupItemMaybe)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItem)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(nil)
            }
        })
    }
    
    func update(groupItem: GroupItem, dirty: Bool, handler: Bool -> Void) {
        addOrUpdate(groupItem, dirty: dirty, handler: handler)
    }
    
    func addOrUpdate(groupItem: GroupItem, dirty: Bool, handler: Bool -> Void) {
        let dbObj = GroupItemMapper.dbWith(groupItem, dirty: dirty)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(groupItem: GroupItem, markForSync: Bool, handler: Bool -> Void) {
        removeGroupItem(groupItem.uuid, markForSync: markForSync, handler: handler)
    }
    
    func removeGroupItem(uuid: String, markForSync: Bool, handler: Bool -> Void) {
        // Needs custom handling because we need the lastUpdate server timestamp and for this we have to retrieve the item from db
        self.doInWriteTransaction({realm in
            if let itemToRemove = realm.objects(DBGroupItem).filter(DBGroupItem.createFilter(uuid)).first {
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
    
    // Expected to be executed in do/catch and write block
    func removeGroupItemsForGroupSync(realm: Realm, groupUuid: String, markForSync: Bool) -> Bool {
        let dbGroupItems = realm.objects(DBGroupItem).filter(DBGroupItem.createFilterGroup(groupUuid))
        for dbGroupItem in dbGroupItems {
            removeGroupItemSync(realm, dbGroupItem: dbGroupItem, markForSync: markForSync)
        }
        return true
    }

    func removeGroupItemsForProductSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let dbGroupItems = realm.objects(DBGroupItem).filter(DBGroupItem.createFilterProduct(productUuid))
        for dbGroupItem in dbGroupItems {
            removeGroupItemSync(realm, dbGroupItem: dbGroupItem, markForSync: markForSync)
        }
        return true
    }
    
    func removeGroupItemSync(realm: Realm, dbGroupItem: DBGroupItem, markForSync: Bool) {
        if markForSync {
            let toRemoveGroupItem = DBRemoveGroupItem(dbGroupItem)
            realm.add(toRemoveGroupItem, update: true)
        }
        realm.delete(dbGroupItem)
    }
    
    func overwrite(items: [GroupItem], groupUuid: String, clearTombstones: Bool, handler: Bool -> Void) {
        let dbObjs = items.map{GroupItemMapper.dbWith($0, dirty: !clearTombstones)} // assumption - clear tombstones means it comes from server. Comes from server -> !dirty
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilterWithGroup(groupUuid))} : nil
        self.overwrite(dbObjs, deleteFilter: DBGroupItem.createFilterGroup(groupUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    // Copied from realm list item provider (which is copied from inventory item provider) refactor?
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    func incrementGroupItem(item: GroupItem, delta: Int, dirty: Bool, handler: Int? -> Void) {
        incrementGroupItem(ItemIncrement(delta: delta, itemUuid: item.uuid), dirty: dirty, handler: handler)
    }
    
    func incrementGroupItem(increment: ItemIncrement, dirty: Bool, handler: Int? -> Void) {
        
        doInWriteTransaction({realm in
            
            syncedRet(self) {
                
                let results = realm.objects(DBGroupItem).filter(DBGroupItem.createFilter(increment.itemUuid)).toArray()
                let dbGroupItems = results.map{GroupItemMapper.groupItemWith($0)}
                
                if let groupItem = dbGroupItems.first {
                    let incrementedGroupItem = groupItem.incrementQuantityCopy(increment.delta)
                    
                    let dbIncrementedGroupItem = GroupItemMapper.dbWith(incrementedGroupItem, dirty: dirty)
                    
                    realm.add(dbIncrementedGroupItem, update: true)
                    
                    return dbIncrementedGroupItem.quantity
                    
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
    
    func clearGroupItemTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearGroupItemTombstonesForGroup(groupUuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveGroupItem.self, DBRemoveGroupItem.createFilterWithGroup(groupUuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    func updateGroupItemLastUpdate(updateDict: [String: AnyObject], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateGroupItemLastUpdate(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateGroupItemLastUpdate(realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(DBGroupItem.self, value: updateDict, update: true)
    }
    
    func updateLastSyncTimeStamp(items: RemoteGroupItemsWithDependencies, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            for listItem in items.groupItems {
                realm.create(DBGroupItem.self, value: listItem.timestampUpdateDict, update: true)
            }
            for product in items.products {
                DBProviders.productProvider.updateLastSyncTimeStampSync(realm, product: product)
            }
            for productCategory in items.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for group in items.groups {
                DBProviders.listItemGroupProvider.updateLastSyncTimeStampSync(realm, group: group)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateGroupItemWithIncrementResult(incrementResult: RemoteIncrementResult, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(DBGroupItem).filter(DBGroupItem.createFilter(incrementResult.uuid)).first) {
                
                // store the timestamp only if it matches with the current quantity. E.g. if user increments very quicky 1,2,3,4,5,6
                // we may receive the response from server for 1 when the database is already at 4 - so we don't want to store 1's timestamp for 4. When the user stops at 6 only the timestamp with the response with 6 quantity will be stored.
                if storedItem.quantity == incrementResult.updatedQuantity {
                    // Notes & todo see equivalent method for list items
                    if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                        
                        let updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                        realm.create(DBGroupItem.self, value: updateDict, update: true)
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
