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
    func loadGlobalSync(isMatchSync: Bool, handler: [String: AnyObject]? -> Void) {
        
        withRealm({realm in

            let productCategories = realm.objects(DBProductCategory).filter(DBSyncable.dirtyFilter())
            let products = realm.objects(DBProduct).filter(DBSyncable.dirtyFilter())
            let storeProducts = realm.objects(DBStoreProduct).filter(DBSyncable.dirtyFilter())
            let lists = realm.objects(DBList).filter(DBSyncable.dirtyFilter())
            let sections = realm.objects(DBSection).filter(DBSyncable.dirtyFilter())
            let listsItems = realm.objects(DBListItem).filter(DBSyncable.dirtyFilter())
            let inventories = realm.objects(DBInventory).filter(DBSyncable.dirtyFilter())
            let inventoryItems = realm.objects(DBInventoryItem).filter(DBSyncable.dirtyFilter())
            let groups = realm.objects(DBListItemGroup).filter(DBSyncable.dirtyFilter())
            let groupItems = realm.objects(DBGroupItem).filter(DBSyncable.dirtyFilter())
            let history = realm.objects(DBHistoryItem).filter(DBSyncable.dirtyFilter())

            let categoriesToSync = productCategories.map{$0.toDict()}
            let productsToSync = products.map{$0.toDict()}
            let storeProductsToSync = storeProducts.map{$0.toDict()}
            let listsToSync = lists.map{$0.toDict()}
            let sectionsToSync = sections.map{$0.toDict()}
            let listItemsToSync = listsItems.map{$0.toDict()}
            
            // For inventory we need to filter out inventories where I'm not authorised, otherwise the sync fails. The reason we have these inventories in the client is that they can be referenced by lists. A participant of a list doesn't necessarily have access to its associated inventory. But the list references it so we store it in "read only mode" (note that this is only about the inventory object, we of course don't get its items).
            let inventoriesToSync = inventories.filter{inventory in
                let sharedUsers = inventory.users.map{SharedUserMapper.sharedUserWithDB($0)}
                // for now allow empty participants, this should be the case when the inventory was never shared (TODO confirm. If in all possible cases is guaranteed that the inventory has shared users we can remove this).
                return sharedUsers.isEmpty || sharedUsers.containsMe()
            }.map{$0.toDict()}
            let inventoryItemsToSync = inventoryItems.map{$0.toDict()}
            let groupsToSync = groups.map{$0.toDict()}
            let groupItemsToSync = groupItems.map{$0.toDict()}
            let historyToSync = history.map{$0.toDict()}
            
            let categoriesToRemove = realm.objects(DBRemoveProductCategory).map{$0.toDict()}
            let productsToRemove = realm.objects(DBProductToRemove).map{$0.toDict()}
            let storeProductsToRemove = realm.objects(DBStoreProductToRemove).map{$0.toDict()}
            let listsToRemove = realm.objects(DBRemoveList).map{$0.toDict()}
            let sectionsToRemove = realm.objects(DBSectionToRemove).map{$0.toDict()}
            let listItemsToRemove = realm.objects(DBRemoveListItem).map{$0.toDict()}
            let inventoriesToRemove = realm.objects(DBRemoveInventory).map{$0.toDict()}
            let inventoryItemsToRemove = realm.objects(DBRemoveInventoryItem).map{$0.toDict()}
            let groupsToRemove = realm.objects(DBRemoveListItemGroup).map{$0.toDict()}
            let groupItemsToRemove = realm.objects(DBRemoveGroupItem).map{$0.toDict()}
            let historyToRemove = realm.objects(DBRemoveHistoryItem).map{$0.toDict()}
            
            let categoriesDict = ["categories": categoriesToSync, "toRemove": categoriesToRemove]
            let productsDict = ["products": productsToSync, "toRemove": productsToRemove]
            let storeProductsDict = ["storeProducts": storeProductsToSync, "toRemove": storeProductsToRemove]
            let listsDict = ["lists": listsToSync, "toRemove": listsToRemove]
            let sectionsDict = ["sections": sectionsToSync, "toRemove": sectionsToRemove]
            let listItemsDict = ["listItems": listItemsToSync, "toRemove": listItemsToRemove]
            let inventoriesDict = ["inventories": inventoriesToSync, "toRemove": inventoriesToRemove]
            let inventoryItemsDict = ["inventoryItems": inventoryItemsToSync, "toRemove": inventoryItemsToRemove]
            let gropsDict = ["groups": groupsToSync, "toRemove": groupsToRemove]
            let groupItemsDict = ["groupItems": groupItemsToSync, "toRemove": groupItemsToRemove]
            let historyDict = ["historyItems": historyToSync, "toRemove": historyToRemove]
            
            var syncDict = [String: AnyObject]()
            syncDict["productCategories"] = categoriesDict
            syncDict["products"] = productsDict
            syncDict["storeProducts"] = storeProductsDict
            syncDict["lists"] = listsDict
            syncDict["sections"] = sectionsDict
            syncDict["listItems"] = listItemsDict
            syncDict["inventories"] = inventoriesDict
            syncDict["inventoryItems"] = inventoryItemsDict
            syncDict["groups"] = gropsDict
            syncDict["groupsItems"] = groupItemsDict
            syncDict["history"] = historyDict
            
            syncDict["isMatch"] = isMatchSync
            
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
    
    func saveSyncResult(syncResult: RemoteSyncResult, handler: Bool -> Void) {

        // Maps an array of dictionaries(object representations from server) to an array of objects T by applying mapper to each dictionary
        // Returns, together with the array also a dictionary which maps a unique identifier of the object to the object, for quick access.
        func toObjs<T: DBSyncable>(dictArray: [[String: AnyObject]], mapper: [String: AnyObject] -> T, idExtractor: T -> String) -> ([T], [String: T]) {
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
            
            let (productCategoriesArr, productCategoriesDict): ([DBProductCategory], [String: DBProductCategory]) = toObjs(syncResult.productCategories, mapper: {DBProductCategory.fromDict($0)}, idExtractor: {$0.uuid})
            
            let (productsArr, productsDict): ([DBProduct], [String: DBProduct]) = toObjs(syncResult.products, mapper: {DBProduct.fromDict($0, category: productCategoriesDict[$0["categoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})

            let (storeProductsArr, storeProductsDict): ([DBStoreProduct], [String: DBStoreProduct]) = toObjs(syncResult.storeProducts, mapper: {DBStoreProduct.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!)}, idExtractor: {$0.uuid})

            let (inventoriesArr, inventoriesDict): ([DBInventory], [String: DBInventory]) = toObjs(syncResult.inventories, mapper: {DBInventory.fromDict($0)}, idExtractor: {$0.uuid})
            
            let (inventoryItemsArr, inventoryItemsDict): ([DBInventoryItem], [String: DBInventoryItem]) = toObjs(syncResult.inventoriesItems, mapper: {DBInventoryItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (listsArr, listsDict): ([DBList], [String: DBList]) = toObjs(syncResult.lists, mapper: {DBList.fromDict($0, inventory: inventoriesDict[$0["list"]!["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (sectionsArr, sectionsDict): ([DBSection], [String: DBSection]) = toObjs(syncResult.sections, mapper: {DBSection.fromDict($0, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (listItemsArr, listItemsDict): ([DBListItem], [String: DBListItem]) = toObjs(syncResult.listsItems, mapper: {DBListItem.fromDict($0, section: sectionsDict[$0["sectionUuid"]! as! String]!, product: storeProductsDict[$0["storeProductUuid"]! as! String]!, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            //        // TODO!!!! set BOTH group in groups items and group items in group Realm needs both set to save correctly ............ this is needed also for lists and inventories probably
            let (groupsArr, groupsDict): ([DBListItemGroup], [String: DBListItemGroup]) = toObjs(syncResult.groups, mapper: {DBListItemGroup.fromDict($0)}, idExtractor: {$0.uuid})
            let (groupItemsArr, groupItemsDict): ([DBGroupItem], [String: DBGroupItem]) = toObjs(syncResult.groupsItems, mapper: {DBGroupItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, group: groupsDict[$0["groupUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (historyItemsArr, historyItemsDict): ([DBHistoryItem], [String: DBHistoryItem]) = toObjs(syncResult.history, mapper: {DBHistoryItem.fromDict($0, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!, product: productsDict[$0["productUuid"] as! String]!)}, idExtractor: {$0.uuid})
            
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            
            self?.clearAllDataSync(realm)
            
            func saveObjs(objs: [Object]) {
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
    
    private func clearAllDataSync(realm: Realm) {
        realm.delete(realm.objects(DBGroupItem))
        realm.delete(realm.objects(DBListItem))
        realm.delete(realm.objects(DBInventoryItem))
        realm.delete(realm.objects(DBHistoryItem))
        
        realm.delete(realm.objects(DBSection))
        
        realm.delete(realm.objects(DBListItemGroup))
        realm.delete(realm.objects(DBList))
        realm.delete(realm.objects(DBInventory))
        
        realm.delete(realm.objects(DBStoreProduct))
        realm.delete(realm.objects(DBProduct))
        realm.delete(realm.objects(DBProductCategory))

        realm.delete(realm.objects(DBSharedUser))

        // tombstones
        realm.delete(realm.objects(DBRemoveGroupItem))
        realm.delete(realm.objects(DBRemoveListItem))
        realm.delete(realm.objects(DBRemoveInventoryItem))
        realm.delete(realm.objects(DBRemoveHistoryItem))

        realm.delete(realm.objects(DBSectionToRemove))
        
        realm.delete(realm.objects(DBRemoveListItemGroup))
        realm.delete(realm.objects(DBRemoveList))
        realm.delete(realm.objects(DBRemoveInventory))

        realm.delete(realm.objects(DBStoreProductToRemove))
        realm.delete(realm.objects(DBProductToRemove))
        realm.delete(realm.objects(DBRemoveProductCategory))

        realm.delete(realm.objects(DBRemoveSharedUser))
    }
    
    func clearAllData(handler: Bool -> Void) {
        
        doInWriteTransaction({[weak self] realm in
            
            self?.clearAllDataSync(realm)
            return true
            
            }) {(successMaybe: Bool?) in
                if let success = successMaybe {
                    handler(success)
                    
                } else {
                    print("Error: RealmGlobalProvider.clearAllData: no success result")
                    handler(false)
                }
        }
    }
}