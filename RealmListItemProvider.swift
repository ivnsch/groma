//
//  RealmListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 16/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

enum QuickAddItemSortBy {
    case Alphabetic, Fav
}

class RealmListItemProvider: RealmProvider {
    
    func saveListItem(listItem: ListItem, updateSuggestions: Bool = true, incrementQuantity: Bool, handler: ListItem -> ()) {
        saveListItems([listItem], incrementQuantity: incrementQuantity) {listItemsMaybe in
            if let listItems = listItemsMaybe {
                if let listItem = listItems.first {
                    handler(listItem)
                } else {
                    // FIXME for now not calling the handler if error happen, but to be correct the handler should get optional list item.
                    print("Error: RealmListItemProvider: saveListItem: returned empty array after (maybe) saving: \(listItem)")
                }
            } else {
                // FIXME for now not calling the handler if error happen, but to be correct the handler should get optional list item.
                print("Error: RealmListItemProvider: saveListItem: returned nil array after (maybe) saving: \(listItem)")
            }
        }
    }
    
    /**
    Batch add/update of list items
    When used for add: incrementQuantity should be true, update: false. After clearing db (e.g. sync) also false (since there's nothing to increment)
    NOTE: Assumes all listItems belong to the same list (only the list of first list item is used for filtering)
    */
    func saveListItems(var listItems: [ListItem], updateSuggestions: Bool = true, incrementQuantity: Bool, updateSection: Bool = true, handler: [ListItem]? -> ()) {
        doInWriteTransaction({realm in
           
            // if we want to increment if item with same product name exists
            // Note that we always want this except when saveListItems is called after having cleared the database, e.g. (currently) on server sync, or when doing an update
            if incrementQuantity {
                // get all existing list items with product names using IN query
                // Note we don't query brand here because we use the result just as a look up dictionary (by uuid) and name+brand query is a subset of name query, so all the products we need will be contained in this query.
                let existingListItems = realm.objects(DBListItem).filter(DBListItem.createFilter(listItems))
                
                let uuidToDBListItemDict: [String: DBListItem] = existingListItems.toDictionary{
                    ($0.product.uuid, $0)
                }
                // merge list items with existing, in order to do update (increment quantity)
                // this means: use uuid of existing item, increment quantity, and for the rest copy fields of new item
                listItems = listItems.map {listItem in
                    if let existingDBListItem = uuidToDBListItemDict[listItem.product.uuid] {
                        return listItem.increment(existingDBListItem.todoQuantity, doneQuantity: existingDBListItem.doneQuantity, stashQuantity: existingDBListItem.stashQuantity)
                    } else {
                        return listItem
                    }
                }
            }
            
            for listItem in listItems {

                // TODO possible to use batch save here?
                let dbListItem = ListItemMapper.dbWithListItem(listItem)
                realm.add(dbListItem, update: true)
                
                if updateSuggestions {
                    DBProviders.productProvider.saveProductSuggestionHelper(realm, product: listItem.product) // TODO still needed?
                    
                    let sectionSuggestion = SectionSuggestionMapper.dbWithSection(listItem.section)
                    realm.add(sectionSuggestion, update: true)
                }
                
            }
            return listItems
            
            }, finishHandler: {listItemsMaybe in
                handler(listItemsMaybe)
        })
    }
    
    
    func addListItem(status: ListItemStatus, product: Product, sectionNameMaybe: String?, quantity: Int, list: List, note noteMaybe: String? = nil, _ handler: ListItem? -> Void) {
        
        doInWriteTransaction({realm in
            return syncedRet(self) {
                
                // see if there's already a listitem for this product in the list - if yes only increment it
                if let existingListItem = realm.objects(DBListItem).filter(DBListItem.createFilterWithProductName(product.name)).first {
                    existingListItem.increment(ListItemStatusQuantity(status: status, quantity: quantity))
                    
                    // possible updates (when user submits a new list item using add edit product controller)
                    if let sectionName = sectionNameMaybe {
                        existingListItem.section.name = sectionName
                    }
                    if let note = noteMaybe {
                        existingListItem.note = note
                    }
                    
                    // TODO!! update sectionnaeme, note (for case where this is from add product with inputs)
                    realm.add(existingListItem, update: true)
                    return ListItemMapper.listItemWithDB(existingListItem)
                    
                } else { // no list item for product in the list, create a new one
                    
                    // see if there's already a section for the new list item in the list, if not create a new one
                    let listItemsInList = realm.objects(DBListItem).filter(DBListItem.createFilterList(list.uuid))
                    let sectionName = sectionNameMaybe ?? product.category.name
                    let section = listItemsInList.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                        return SectionMapper.sectionWithDB(item.section)
                        } ?? {
                            let sectionCount = Set(listItemsInList.map{$0.section}).count
                            return Section(uuid: NSUUID().UUIDString, name: sectionName, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
                        }()
                    
                    
                    // calculate list item order, which is at the end of it's section (==count of listitems in section). Note that currently we are doing this iteration even if we just created the section, where order is always 0. This if for clarity - can be optimised later (TODO)
                    var listItemOrder = 0
                    for existingListItem in listItemsInList {
                        if existingListItem.section.uuid == section.uuid {
                            listItemOrder++
                        }
                    }
                    
                    // create the list item and save it
                    let listItem = ListItem(uuid: NSUUID().UUIDString, product: product, section: section, list: list, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: quantity))
                    
                    let dbListItem = ListItemMapper.dbWithListItem(listItem)
                    realm.add(dbListItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
                    return ListItemMapper.listItemWithDB(dbListItem)
                }
            }
        }, finishHandler: {(savedListItemMaybe: ListItem?) in
                handler(savedListItemMaybe)
        })
    }

    
    func loadListItems(list: List, handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, filter: DBListItem.createFilterList(list.uuid), handler: handler)
    }
    
    func listItem(list: List, product: Product, handler: ListItem? -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.loadFirst(mapper, filter: DBListItem.createFilter(list, product: product), handler: handler)
    }
    
    func findListItem(uuid: String, _ handler: ListItem? -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.loadFirst(mapper, filter: DBListItem.createFilter(uuid), handler: handler)
    }
    
    // hm...
    func loadAllListItems(handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func remove(listItem: ListItem, markForSync: Bool, handler: Bool -> ()) {
        remove(listItem.uuid, listUuid: listItem.list.uuid, markForSync: markForSync, handler: handler)
    }
    
    func remove(listItemUuid: String, listUuid: String, markForSync: Bool, handler: Bool -> ()) {
        
        let additionalActions: (Realm -> Void)? = markForSync ? {realm in
            // TODO!!!! lastServerUpdate? what should it be? do we need this here?
            let toRemoveListItem = DBRemoveListItem(uuid: listItemUuid, listUuid: listUuid, lastServerUpdate: NSDate())
            realm.add(toRemoveListItem, update: true)
            } : nil
        
        self.remove(DBListItem.createFilter(listItemUuid), handler: handler, objType: DBListItem.self, additionalActions: additionalActions)
    }
    
    // TODO remove this method? Or if it's still needed, pass only list items, all the dependencies are in list items already
    // TODO do we really need ListItemsWithRelations here, maybe convenience holder made sense only for coredata?
    func saveListItems(listItemsWithRelations: ListItemsWithRelations, handler: Bool -> ()) {
        
        //        let dbProducts = listItemsWithRelations.products.map{self.toDBProduct($0)}
        //        let dbSections = listItemsWithRelations.sections.map{self.toDBSection($0)}
        //        let dbLists = listItemsWithRelations.lists.map{self.toDBList($0)}
        //
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        //            let realm = Realm()
        //            realm.write {
        //
        //                for dbProduct in dbProducts {
        //                    realm.add(dbProduct)
        //                }
        //            }
        //            dispatch_async(dispatch_get_main_queue(), {
        //                handler(true)
        //            })
        //        })
        
        let dbListItems = listItemsWithRelations.listItems.map{ListItemMapper.dbWithListItem($0)}
        self.saveObjs(dbListItems, update: true) {listItemsMaybe in
            handler(true)
        }
    }
    
    func updateListItems(listItems: [ListItem], handler: Bool -> ()) {
        saveListItems(listItems, incrementQuantity: false, updateSection: false) {updatedListItemsMaybe in
            if let updatedListItems = updatedListItemsMaybe {
                if listItems.count == updatedListItems.count {
                    handler(true)
                } else {
                    print("Error: RealmListItemProvider: updateListItems: list items count != updated items count. list items: \(listItems), updated: \(updatedListItemsMaybe)")
                    handler(false)
                }
            } else {
                print("Error: RealmListItemProvider: saveListItem: returned nil array after (maybe) saving: \(updatedListItemsMaybe)")
                handler(false)
            }
        }
    }
    
    func overwrite(listItems: [ListItem], listUuid: String, clearTombstones: Bool, handler: Bool -> ()) {
        let dbListItems = listItems.map{ListItemMapper.dbWithListItem($0)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilterForList(listUuid))} : nil
        self.overwrite(dbListItems, deleteFilter: DBListItem.createFilterList(listUuid), resetLastUpdateToServer: true, additionalActions: additionalActions, handler: handler)
    }
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(status: ListItemStatus, list: List, handler: Int? -> Void) {
        let finished: Int? -> Void = {result in
            dispatch_async(dispatch_get_main_queue(), {
                handler(result)
            })
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                let listItems = realm.objects(DBListItem).filter(DBListItem.createFilterList(list.uuid))
                let count = listItems.filter{$0.hasStatus(status)}.count
                finished(count)
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished(nil) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        })
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    func incrementTodoListItem(item: ListItem, delta: Int, handler: Bool -> Void) {
        incrementTodoListItem(ItemIncrement(delta: delta, itemUuid: item.uuid), handler: handler)
    }
    
    // TODO!!!! remote?
    func incrementTodoListItem(increment: ItemIncrement, handler: Bool -> Void) {
        
        do {
            //        synced(self)  {
            
            // load
            let realm = try Realm()
            let results = realm.objects(DBListItem).filter(DBListItem.createFilter(increment.itemUuid))
            //        results = results.filter(NSPredicate(format: DBInventoryItem.createFilter(item.product, item.inventory), argumentArray: []))
            let objs: [DBListItem] = results.toArray(nil)
            let dbInventoryItems = objs.map{ListItemMapper.listItemWithDB($0)}
            let listItemMaybe = dbInventoryItems.first
            
            if let listItem = listItemMaybe {
                // increment
                let incrementedListitem = listItem.copy(note: nil, todoQuantity: listItem.todoQuantity + increment.delta)
                
                // convert to db object
                let dbIncrementedInventoryitem = ListItemMapper.dbWithListItem(incrementedListitem)
                
                // save
                try realm.write {
                    for obj in objs {
                        obj.lastUpdate = NSDate()
                        realm.add(dbIncrementedInventoryitem, update: true)
                    }
                }
                
                handler(true)
                
                
            } else {
                print("Info: RealmListItemProvider.incrementTodoListItem: List item not found: \(increment)")
                handler(false)
            }
            //        }
            
        } catch let e {
            QL4("Realm error: \(e)")
            handler(false)
        }
    }
    
    // MARK: - Sync

    func clearListItemTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearListItemTombstonesForList(listUuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilterForList(listUuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // TODO! is this method still necessary? we have global sync now
    func saveListsSyncResult(syncResult: RemoteListWithListItemsSyncResult, handler: Bool -> ()) {
        
        doInWriteTransaction({realm in
            
            let inventories = realm.objects(DBList)
            let inventoryItems = realm.objects(DBListItem)
            let sections = realm.objects(DBSection)

            realm.delete(inventories)
            realm.delete(inventoryItems)
            realm.delete(sections)
            // we don't delete the products because these are referenced also by inventory items and maybe also other things in the future
            
            // save inventories
            let lists = ListMapper.listsWithRemote(syncResult.lists)
            let remoteInventories = lists
            for remoteInventory in remoteInventories {
                let dbInventory = ListMapper.dbWithList(remoteInventory)
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for listItemsSyncResult in syncResult.listItemsSyncResults {
                
                let listItemsWithRelations = ListItemMapper.listItemsWithRemote(listItemsSyncResult.listItems, sortOrderByStatus: nil)
                
                for product in listItemsWithRelations.products {
                    let dbProduct = ProductMapper.dbWithProduct(product)
                    realm.add(dbProduct, update: true) // since we don't delete products (see comment above) we do update
                }
                
                for section in listItemsWithRelations.sections {
                    let dbSection = SectionMapper.dbWithSection(section)
                    realm.add(dbSection, update: true)
                }
                
                for listItem in listItemsWithRelations.listItems {
                    let dbInventoryItem = ListItemMapper.dbWithListItem(listItem)
                    realm.add(dbInventoryItem, update: true)

                }
            }
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateListItemLastSyncTimeStamp(updateDict: [String: AnyObject], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateListItemLastSyncTimeStamp(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    func updateListItemsLastSyncTimeStamps(updateDicts: [[String: AnyObject]], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            for updateDict in updateDicts {
                self?.updateListItemLastSyncTimeStamp(realm, updateDict: updateDict)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateListItemLastSyncTimeStamp(realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(DBListItem.self, value: updateDict, update: true)
    }
    
    func updateLastSyncTimeStamp(listItems: RemoteListItems, handler: Bool -> Void) {
        doInWriteTransaction({[weak self]realm in
            for listItem in listItems.listItems {
                self?.updateListItemLastSyncTimeStamp(realm, updateDict: listItem.timestampUpdateDict)
            }
            for product in listItems.products {
                realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in listItems.productsCategories {
                realm.create(DBProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for section in listItems.sections {
                realm.create(DBSection.self, value: section.timestampUpdateDict, update: true)
            }
            DBProviders.listProvider.updateLastSyncTimeStampSync(realm, lists: listItems.lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    
    func updateLastSyncTimeStamp(product: RemoteProduct, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, product: product)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // FIXME repeated method with RealmListItemGroupProvider
    func updateLastSyncTimeStampSync(realm: Realm, product: RemoteProduct) {
        realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
    }
}
