    //
//  RealmGlobalProvider.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmGlobalProvider: RealmProvider {

    // TODO map db objects directly to dicts, mapping to our plain objects is not necessary
    func loadGlobalSync(handler: [String: AnyObject]? -> Void) {
        
        withRealm({realm in

            let productCategories = realm.objects(DBProductCategory).filter(DBSyncable.dirtyFilter())
            let products = realm.objects(DBProduct).filter(DBSyncable.dirtyFilter())
            let lists = realm.objects(DBList).filter(DBSyncable.dirtyFilter())
            let sections = realm.objects(DBSection).filter(DBSyncable.dirtyFilter())
            let listsItems = realm.objects(DBListItem).filter(DBSyncable.dirtyFilter())
            let inventories = realm.objects(DBInventory).filter(DBSyncable.dirtyFilter())
            let inventoryItems = realm.objects(DBInventoryItem).filter(DBSyncable.dirtyFilter())
            let groups = realm.objects(DBListItemGroup).filter(DBSyncable.dirtyFilter())
            let groupItems = realm.objects(DBGroupItem).filter(DBSyncable.dirtyFilter())
            let history = realm.objects(DBHistoryItem).filter(DBSyncable.dirtyFilter())

            let (categoriesToRemove, categoriesToSync) = productCategories.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (productsToRemove, productsToSync) = products.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (listsToRemove, listsToSync) = lists.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (sectionsToRemove, sectionsToSync) = sections.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (listItemsToRemove, listItemsToSync) = listsItems.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (inventoriesToRemove, inventoriesToSync) = inventories.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (inventoryItemsToRemove, inventoryItemsToSync) = inventoryItems.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (groupsToRemove, groupsToSync) = groups.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (groupItemsToRemove, groupItemsToSync) = groupItems.splitMap({$0.removed}, mapper: {$0.toDict()})
            let (historyToRemove, historyToSync) = history.splitMap({$0.removed}, mapper: {$0.toDict()})
            
            let categoriesDict = ["categories": categoriesToSync, "toRemove": categoriesToRemove]
            let productsDict = ["products": productsToSync, "toRemove": productsToRemove]
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
            syncDict["lists"] = listsDict
            syncDict["sections"] = sectionsDict
            syncDict["listItems"] = listItemsDict
            syncDict["inventories"] = inventoriesDict
            syncDict["inventoryItems"] = inventoryItemsDict
            syncDict["groups"] = gropsDict
            syncDict["groupsItems"] = groupItemsDict
            syncDict["history"] = historyDict
            
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

        func toTuple<T: DBSyncable>(dictArray: [[String: AnyObject]], mapper: [String: AnyObject] -> T, idExtractor: T -> String) -> ([T], [String: T]) {
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

            let (productCategoriesArr, productCategoriesDict): ([DBProductCategory], [String: DBProductCategory]) = toTuple(syncResult.productCategories, mapper: {DBProductCategory.fromDict($0)}, idExtractor: {$0.uuid})
            
            let m: [String: AnyObject] -> DBProduct = {(dict: [String: AnyObject]) in
                
                let cat = productCategoriesDict[dict["categoryUuid"]! as! String]!
                return DBProduct.fromDict(dict, category: cat)
                
            }
            let (productsArr, productsDict): ([DBProduct], [String: DBProduct]) = toTuple(syncResult.products, mapper: {DBProduct.fromDict($0, category: productCategoriesDict[$0["categoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})

            
            let (inventoriesArr, inventoriesDict): ([DBInventory], [String: DBInventory]) = toTuple(syncResult.inventories, mapper: {DBInventory.fromDict($0)}, idExtractor: {$0.uuid})
            
            // inventory items has different unique so we need adjusted code
            var inventoryItemsArr = [DBInventoryItem]()
            for dict in syncResult.inventoriesItems {
                let element = DBInventoryItem.fromDict(dict, product: productsDict[dict["productUuid"]! as! String]!, inventory: inventoriesDict[dict["inventoryUuid"]! as! String]!)
                inventoryItemsArr.append(element)
            }
            
            
            let (listsArr, listsDict): ([DBList], [String: DBList]) = toTuple(syncResult.lists, mapper: {DBList.fromDict($0, inventory: inventoriesDict[$0["list"]!["inventoryUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (sectionsArr, sectionsDict): ([DBSection], [String: DBSection]) = toTuple(syncResult.sections, mapper: {DBSection.fromDict($0, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (listItemsArr, listItemsDict): ([DBListItem], [String: DBListItem]) = toTuple(syncResult.listsItems, mapper: {DBListItem.fromDict($0, section: sectionsDict[$0["sectionUuid"]! as! String]!, product: productsDict[$0["productUuid"]! as! String]!, list: listsDict[$0["listUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            //        // TODO!!!! set BOTH group in groups items and group items in group Realm needs both set to save correctly ............ this is needed also for lists and inventories probably
            let (groupsArr, groupsDict): ([DBListItemGroup], [String: DBListItemGroup]) = toTuple(syncResult.groups, mapper: {DBListItemGroup.fromDict($0)}, idExtractor: {$0.uuid})
            let (groupItemsArr, groupItemsDict): ([DBGroupItem], [String: DBGroupItem]) = toTuple(syncResult.groupsItems, mapper: {DBGroupItem.fromDict($0, product: productsDict[$0["productUuid"]! as! String]!, group: groupsDict[$0["groupUuid"]! as! String]!)}, idExtractor: {$0.uuid})
            
            let (historyItemsArr, historyItemsDict): ([DBHistoryItem], [String: DBHistoryItem]) = toTuple(syncResult.history, mapper: {DBHistoryItem.fromDict($0, inventory: inventoriesDict[$0["inventoryUuid"]! as! String]!, product: productsDict[$0["productUuid"] as! String]!)}, idExtractor: {$0.uuid})
            
            self?.clearAllDataSync(realm)
            
            func saveObjs(objs: [Object]) {
                for obj in objs {
                    realm.add(obj, update: true)
                }
            }
            saveObjs(productCategoriesArr)
            saveObjs(productsArr)
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
        realm.delete(realm.objects(DBProductCategory))
        realm.delete(realm.objects(DBProduct))
        realm.delete(realm.objects(DBSection))
        realm.delete(realm.objects(DBSharedUser))
        realm.delete(realm.objects(DBInventory))
        realm.delete(realm.objects(DBInventoryItem))
        realm.delete(realm.objects(DBList))
        realm.delete(realm.objects(DBListItem))
        realm.delete(realm.objects(DBListItemGroup))
        realm.delete(realm.objects(DBGroupItem))
        realm.delete(realm.objects(DBHistoryItem))
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