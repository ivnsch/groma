    //
//  RealmGlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs
    
class RealmGlobalProvider: RealmProvider {

    // TODO map db objects directly to dicts, mapping to our plain objects is not necessary
    func loadGlobalSync(_ isMatchSync: Bool, handler: @escaping ([String: AnyObject]?) -> Void) {
        
        withRealm({realm in

            let productCategories = realm.objects(ProductCategory.self).filter(ProductCategory.createFilterDirtyAndValid())
            let products = realm.objects(Product.self).filter(Product.createFilterDirtyAndValid())
            let storeProducts = realm.objects(DBStoreProduct.self).filter(DBStoreProduct.createFilterDirtyAndValid())
            let lists = realm.objects(List.self).filter(DBSyncable.dirtyFilter())
            let sections = realm.objects(DBSection.self).filter(DBSyncable.dirtyFilter())
            let listsItems = realm.objects(DBListItem.self).filter(DBSyncable.dirtyFilter())
            let inventories = realm.objects(DBInventory.self).filter(DBSyncable.dirtyFilter())
            let inventoryItems = realm.objects(InventoryItem.self).filter(DBSyncable.dirtyFilter())
            let groups = realm.objects(ProductGroup.self).filter(DBSyncable.dirtyFilter())
            let groupItems = realm.objects(GroupItem.self).filter(DBSyncable.dirtyFilter())
            let history = realm.objects(DBHistoryItem.self).filter(DBSyncable.dirtyFilter())

            let categoriesToSync = productCategories.map{$0.toDict()}
            let productsToSync = products.map{$0.toDict()}
            let storeProductsToSync = storeProducts.map{$0.toDict()}
            let listsToSync = lists.map{$0.toDict()}
            let sectionsToSync = sections.map{$0.toDict()}
            let listItemsToSync = listsItems.map{$0.toDict()}
            
            // For inventory we need to filter out inventories where I'm not authorised, otherwise the sync fails. The reason we have these inventories in the client is that they can be referenced by lists. A participant of a list doesn't necessarily have access to its associated inventory. But the list references it so we store it in "read only mode" (note that this is only about the inventory object, we of course don't get its items).
            let inventoriesToSync = inventories.filter{inventory in
                let sharedUsers = Array(inventory.users.map{SharedUserMapper.sharedUserWithDB($0)})
                // for now allow empty participants, this should be the case when the inventory was never shared (TODO confirm. If in all possible cases is guaranteed that the inventory has shared users we can remove this).
                return sharedUsers.isEmpty || sharedUsers.containsMe()
            }.map{$0.toDict()}
            let inventoryItemsToSync = inventoryItems.map{$0.toDict()}
            let groupsToSync = groups.map{$0.toDict()}
            let groupItemsToSync = groupItems.map{$0.toDict()}
            let historyToSync = history.map{$0.toDict()}
            
            let categoriesToRemove = realm.objects(DBRemoveProductCategory.self).map{$0.toDict()}
            let productsToRemove = realm.objects(ProductToRemove.self).map{$0.toDict()}
            let storeProductsToRemove = realm.objects(DBStoreProductToRemove.self).map{$0.toDict()}
            let listsToRemove = realm.objects(DBRemoveList.self).map{$0.toDict()}
            let sectionsToRemove = realm.objects(DBSectionToRemove.self).map{$0.toDict()}
            let listItemsToRemove = realm.objects(DBRemoveListItem.self).map{$0.toDict()}
            let inventoriesToRemove = realm.objects(DBRemoveInventory.self).map{$0.toDict()}
            let inventoryItemsToRemove = realm.objects(DBRemoveInventoryItem.self).map{$0.toDict()}
            let groupsToRemove = realm.objects(DBRemoveProductGroup.self).map{$0.toDict()}
            let groupItemsToRemove = realm.objects(DBRemoveGroupItem.self).map{$0.toDict()}
            let historyToRemove = realm.objects(DBRemoveHistoryItem.self).map{$0.toDict()}
            
            let categoriesDict = ["categories": categoriesToSync as AnyObject, "toRemove": categoriesToRemove as AnyObject]
            let productsDict = ["products": productsToSync as AnyObject, "toRemove": productsToRemove as AnyObject]
            let storeProductsDict = ["storeProducts": storeProductsToSync as AnyObject, "toRemove": storeProductsToRemove as AnyObject]
            let listsDict = ["lists": listsToSync as AnyObject, "toRemove": listsToRemove as AnyObject]
            let sectionsDict = ["sections": sectionsToSync as AnyObject, "toRemove": sectionsToRemove as AnyObject]
            let listItemsDict = ["listItems": listItemsToSync as AnyObject, "toRemove": listItemsToRemove as AnyObject]
            let inventoriesDict = ["inventories": inventoriesToSync as AnyObject, "toRemove": inventoriesToRemove as AnyObject]
            let inventoryItemsDict = ["inventoryItems": inventoryItemsToSync as AnyObject, "toRemove": inventoryItemsToRemove as AnyObject]
            let gropsDict = ["groups": groupsToSync as AnyObject, "toRemove": groupsToRemove as AnyObject]
            let groupItemsDict = ["groupItems": groupItemsToSync as AnyObject, "toRemove": groupItemsToRemove as AnyObject]
            let historyDict = ["historyItems": historyToSync as AnyObject, "toRemove": historyToRemove as AnyObject]
            
            var syncDict = [String: AnyObject]()
            syncDict["productCategories"] = categoriesDict as AnyObject
            syncDict["products"] = productsDict as AnyObject
            syncDict["storeProducts"] = storeProductsDict as AnyObject
            syncDict["lists"] = listsDict as AnyObject
            syncDict["sections"] = sectionsDict as AnyObject
            syncDict["listItems"] = listItemsDict as AnyObject
            syncDict["inventories"] = inventoriesDict as AnyObject
            syncDict["inventoryItems"] = inventoryItemsDict as AnyObject
            syncDict["groups"] = gropsDict as AnyObject
            syncDict["groupsItems"] = groupItemsDict as AnyObject
            syncDict["history"] = historyDict as AnyObject
            
            syncDict["isMatch"] = isMatchSync as AnyObject
            
            return syncDict
            
            }) { (globalSyncMaybe: [String: AnyObject]?) -> Void in
                if let globalSync = globalSyncMaybe {
                    handler(globalSync)
                    
                } else {
                    print("Error: RealmGlobalProvider.loadGlobalSync: couldn't load global sync.")
                    handler(nil)
                }
        }
    }
    
    func saveSyncResult(_ syncResult: RemoteSyncResult, handler: @escaping (Bool) -> Void) {

        // Maps an array of dictionaries(object representations from server) to an array of objects T by applying mapper to each dictionary
        // Returns, together with the array also a dictionary which maps a unique identifier of the object to the object, for quick access.
        func toObjs<T: DBSyncable>(_ dictArray: [[String: AnyObject]], mapper: ([String: AnyObject]) -> T, idExtractor: (T) -> String) -> ([T], [String: T]) {
            var objArray = [T]()
            var objDict = [String: T]()
            for dict in dictArray {
                let element = mapper(dict)
                objArray.append(element)
                objDict[idExtractor(element)] = element
            }
            return (objArray, objDict)
        }
        
        doInWriteTransaction({[weak self] realm in

            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // TODO!!!! write this code with proper optional handling and error logging
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            let (productCategoriesArr, productCategoriesDict): ([ProductCategory], [String: ProductCategory]) = toObjs(syncResult.productCategories, mapper: {ProductCategory.fromDict($0)}, idExtractor: {$0.uuid})
            
            let (productsArr, productsDict): ([Product], [String: Product]) = toObjs(syncResult.products, mapper: {Product.fromDict($0, category: productCategoriesDict[$0["categoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})

            let (storeProductsArr, storeProductsDict): ([DBStoreProduct], [String: DBStoreProduct]) = toObjs(syncResult.storeProducts, mapper: {DBStoreProduct.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!)}, idExtractor: {$0.uuid})

            let (inventoriesArr, inventoriesDict): ([DBInventory], [String: DBInventory]) = toObjs(syncResult.inventories, mapper: {DBInventory.fromDict($0)}, idExtractor: {$0.uuid})
            
            let (inventoryItemsArr, inventoryItemsDict): ([InventoryItem], [String: InventoryItem]) = toObjs(syncResult.inventoriesItems, mapper: {InventoryItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (listsArr, listsDict): ([List], [String: List]) = toObjs(syncResult.lists, mapper: {List.fromDict($0, inventory: inventoriesDict[$0["list"]!["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (sectionsArr, sectionsDict): ([DBSection], [String: DBSection]) = toObjs(syncResult.sections, mapper: {DBSection.fromDict($0, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (listItemsArr, listItemsDict): ([DBListItem], [String: DBListItem]) = toObjs(syncResult.listsItems, mapper: {DBListItem.fromDict($0, section: sectionsDict[$0["sectionUuid"]! as! String]!, product: storeProductsDict[$0["storeProductUuid"]! as! String]!, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            //        // TODO!!!! set BOTH group in groups items and group items in group Realm needs both set to save correctly ............ this is needed also for lists and inventories probably
            let (groupsArr, groupsDict): ([ProductGroup], [String: ProductGroup]) = toObjs(syncResult.groups, mapper: {ProductGroup.fromDict($0)}, idExtractor: {$0.uuid})
            let (groupItemsArr, groupItemsDict): ([GroupItem], [String: GroupItem]) = toObjs(syncResult.groupsItems, mapper: {GroupItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, group: groupsDict[$0["groupUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (historyItemsArr, historyItemsDict): ([DBHistoryItem], [String: DBHistoryItem]) = toObjs(syncResult.history, mapper: {DBHistoryItem.fromDict($0, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!, product: productsDict[$0["productUuid"] as! String]!)}, idExtractor: {$0.uuid})
            
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            self?.clearAllDataSync(realm)
            
            func saveObjs(_ objs: [Object]) {
                for obj in objs {
                    realm.add(obj, update: true)
                }
            }
            saveObjs(productCategoriesArr)
            saveObjs(productsArr)
            saveObjs(storeProductsArr)
            saveObjs(sectionsArr)
            saveObjs(inventoriesArr)
            saveObjs(inventoryItemsArr)
            saveObjs(listsArr)
            saveObjs(listItemsArr)
            saveObjs(groupsArr)
            saveObjs(groupItemsArr)
            saveObjs(historyItemsArr)
            
            
            return true
            }) { (successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)

                } else {
                    print("Error: RealmGlobalProvider.saveSyncResult: no success result")
                    handler(false)
                }
        }
    }
    
    func clearAllDataSync() {
        doInWriteTransactionSync() {[weak self] realm in
            self?.clearAllDataSync(realm)
        }
    }
    
    fileprivate func clearAllDataSync(_ realm: Realm) {
        realm.delete(realm.objects(GroupItem.self))
        realm.delete(realm.objects(DBListItem.self))
        realm.delete(realm.objects(InventoryItem.self))
        realm.delete(realm.objects(DBHistoryItem.self))
        
        realm.delete(realm.objects(DBSection.self))
        
        realm.delete(realm.objects(ProductGroup.self))
        realm.delete(realm.objects(List.self))
        realm.delete(realm.objects(DBInventory.self))
        
        realm.delete(realm.objects(DBStoreProduct.self))
        realm.delete(realm.objects(Product.self))
        realm.delete(realm.objects(ProductCategory.self))

        realm.delete(realm.objects(DBSharedUser.self))

        // tombstones
        realm.delete(realm.objects(DBRemoveGroupItem.self))
        realm.delete(realm.objects(DBRemoveListItem.self))
        realm.delete(realm.objects(DBRemoveInventoryItem.self))
        realm.delete(realm.objects(DBRemoveHistoryItem.self))

        realm.delete(realm.objects(DBSectionToRemove.self))
        
        realm.delete(realm.objects(DBRemoveProductGroup.self))
        realm.delete(realm.objects(DBRemoveList.self))
        realm.delete(realm.objects(DBRemoveInventory.self))

        realm.delete(realm.objects(DBStoreProductToRemove.self))
        realm.delete(realm.objects(ProductToRemove.self))
        realm.delete(realm.objects(DBRemoveProductCategory.self))

        realm.delete(realm.objects(DBRemoveSharedUser.self))
    }
    
    func clearAllData(_ handler: @escaping (Bool) -> Void) {
        
        doInWriteTransaction({[weak self] realm in
            
            self?.clearAllDataSync(realm)
            return true
            
            }) {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                    
                } else {
                    QL4("No success result")
                    handler(false)
                }
        }
    }
    
    func markAllDirty(_ handler: @escaping (Bool) -> Void) {
        
        func markObjsDirty<T: Object>(_ realm: Realm, obj: T.Type, idExtractor: (T) -> String) {
            for obj in realm.objects(T.self) {
                realm.create(T.self, value: ["uuid": idExtractor(obj), "dirty": true], update: true)
            }
        }
        
        func markAllDirtySync(_ realm: Realm) {
            markObjsDirty(realm, obj: GroupItem.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: DBListItem.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: InventoryItem.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: DBHistoryItem.self, idExtractor: {$0.uuid})
            
            markObjsDirty(realm, obj: DBSection.self, idExtractor: {$0.uuid})
            
            markObjsDirty(realm, obj: ProductGroup.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: List.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: DBInventory.self, idExtractor: {$0.uuid})

            markObjsDirty(realm, obj: DBStoreProduct.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: Product.self, idExtractor: {$0.uuid})
            markObjsDirty(realm, obj: ProductCategory.self, idExtractor: {$0.uuid})
            
//            this is not synced
//            markObjsDirty(realm, obj: DBSharedUser.self, idExtractor: {$0.uuid})
        }
        
        doInWriteTransaction({realm in
            markAllDirtySync(realm)
            return true
            
        }) {(successMaybe: Bool?) in
            if let success = successMaybe {
                handler(success)
                
            } else {
                QL4("No success result")
                handler(false)
            }
        }
    }
}
