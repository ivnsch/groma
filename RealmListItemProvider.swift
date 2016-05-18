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
    
    /**
    Batch add/update of list items
    When used for add: incrementQuantity should be true, update: false. After clearing db (e.g. sync) also false (since there's nothing to increment)
    NOTE: Assumes all listItems belong to the same list (only the list of first list item is used for filtering)
    */
    func addOrIncrementListItems(listItems: [ListItem], updateSection: Bool = true, handler: [ListItem]? -> ()) {
        doInWriteTransaction({[weak self] realm in
            self?.addOrIncrementListItemsSync(realm, listItems: listItems, updateSection: updateSection)
            }, finishHandler: {listItemsMaybe in
                handler(listItemsMaybe)
        })
    }
    
    func addOrIncrementListItemsSync(realm: Realm, var listItems: [ListItem], updateSection: Bool = true) -> [ListItem] {
        
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
        
        for listItem in listItems {
            let dbListItem = ListItemMapper.dbWithListItem(listItem)
            realm.add(dbListItem, update: true)
        }
        
        return listItems
    }
    
    func updateListItemsOrderLocal(orderUpdates: [RemoteListItemReorder], sections: [Section], status: ListItemStatus, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            
            // order update can change the section a list item is in, so we need to update the section too.
            let dbSections = sections.map{SectionMapper.dbWithSection($0)}
            let dbSectionDict = dbSections.toDictionary{($0.uuid, $0)}
            
            for orderUpdate in orderUpdates {
                if let dbSection = dbSectionDict[orderUpdate.sectionUuid] {
                    realm.create(DBListItem.self, value: orderUpdate.updateDict(status, dbSection: dbSection), update: true)
                } else {
                    QL4("Invalid state, section object corresponding to uuid: \(orderUpdate.sectionUuid) was not found")
                }
            }
            
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                if let success = successMaybe {
                    if success {
                        Providers.listItemsProvider.invalidateMemCache()
                    }
                }
                handler(successMaybe ?? false)
        })
    }
    
    func storeRemoteListItemSwitchResult(statusUpdate: ListItemStatusUpdate, result: RemoteSwitchListItemResult, _ handler: Bool -> Void) {

        doInWriteTransaction({realm in

            let lastUpdate = result.lastUpdate
            
            let switchedItem = result.switchedItem
            let itemDict = ["uuid": switchedItem.uuid, "todoQuantity": switchedItem.todoQuantity, "doneQuantity": switchedItem.doneQuantity, "todoOrder": switchedItem.todoOrder, "doneOrder": switchedItem.doneOrder, "stashOrder": switchedItem.stashOrder, DBSyncable.lastUpdateFieldName: lastUpdate]
            
            let srcOrderUpdateKey: String = {
                switch statusUpdate.src {
                case .Todo: return "todoOrder"
                case .Done: return "doneOrder"
                case .Stash: return "stashOrder"
                }
            }()
            
            let srcItemsOrderDicts = result.itemOrderUpdates.map {item in
                return ["uuid": item.uuid, srcOrderUpdateKey: item.order, DBSyncable.lastUpdateFieldName: lastUpdate]
            }
            
            let sectionsOrderDicts = result.sectionOrderUpdates.map {item in
                return ["uuid": item.uuid, "todoOrder": item.todoOrder, "doneOrder": item.doneOrder, "stashOrder": item.stashOrder, DBSyncable.lastUpdateFieldName: lastUpdate]
            }

            realm.create(DBListItem.self, value: itemDict, update: true)
            srcItemsOrderDicts.forEach {
                realm.create(DBListItem.self, value: $0, update: true)
            }
            sectionsOrderDicts.forEach {
                realm.create(DBSection.self, value: $0, update: true)
            }
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO these are a bit weird, the data we store on switch all via rest and websockets should be the same? if we need same handling, needs server changes as the data sent is different
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func storeRemoteAllListItemSwitchResult(statusUpdate: ListItemStatusUpdate, result: RemoteSwitchAllListItemsResult, _ handler: Bool -> Void) {
        
        doInWriteTransaction({realm in
            
            let lastUpdate = result.lastUpdate
            
            func quantityKey(status: ListItemStatus) -> String {
                switch status {
                case .Todo: return "todoQuantity"
                case .Done: return "doneQuantity"
                case .Stash: return "stashQuantity"
                }
            }
            func orderKey(status: ListItemStatus) -> String {
                switch status {
                case .Todo: return "todoOrder"
                case .Done: return "doneOrder"
                case .Stash: return "stashOrder"
                }
            }
            
            result.items.forEach {item in
                let dict = ["uuid": item.uuid, orderKey(statusUpdate.dst): item.dstOrder, quantityKey(statusUpdate.dst): item.dstQuantity, DBSyncable.lastUpdateFieldName: NSNumber(longLong: Int64(lastUpdate))]
                realm.create(DBListItem.self, value: dict, update: true)
            }
            
            result.sections.forEach {section in
                let dict = ["uuid": section.uuid, orderKey(statusUpdate.dst): section.dstOrder, DBSyncable.lastUpdateFieldName: NSNumber(longLong: Int64(lastUpdate))]
                realm.create(DBSection.self, value: dict, update: true)
            }
            
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    // For websockets we just refresh the timestamps. For rest response we update quantity+order, the reason for this is bc concurrency etc. maybe the items get a different order or quantity in the server and we update then the client immediately, sending the state in the response. For websockets we don't have time and chose the most quick implementation which is to send just the timestamp and update the switched client list items with this timestamp.
    func storeWebsocketAllListItemSwitchResult(listitems: [ListItem], lastUpdate: Int64, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            listitems.forEach {item in
                let dict = ["uuid": item.uuid, DBSyncable.lastUpdateFieldName: NSNumber(longLong: Int64(lastUpdate))]
                realm.create(DBListItem.self, value: dict, update: true)
            }

            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    func addListItem(status: ListItemStatus, product: StoreProduct, sectionNameMaybe: String?, sectionColorMaybe: UIColor?, quantity: Int, list: List, note noteMaybe: String? = nil, _ handler: ListItem? -> Void) {
        
        doInWriteTransaction({realm in
            return syncedRet(self) {
                
                // see if there's already a listitem for this product in the list - if yes only increment it
                if let existingListItem = realm.objects(DBListItem).filter(DBListItem.createFilterWithProductName(product.product.name)).first {
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
                    let sectionName = sectionNameMaybe ?? product.product.category.name
                    let sectionColor = sectionColorMaybe ?? product.product.category.color
                    let section = listItemsInList.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                        return SectionMapper.sectionWithDB(item.section)
                        } ?? {
                            let sectionCount = Set(listItemsInList.map{$0.section}).count
                            return Section(uuid: NSUUID().UUIDString, name: sectionName, color: sectionColor, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
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
        loadListItems(list.uuid, handler: handler)
    }

    func loadListItems(listUuid: String, handler: [ListItem] -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, filter: DBListItem.createFilterList(listUuid), handler: handler)
    }
    
    func loadListItems(uuids: [String], handler: [ListItem] -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, filter: DBListItem.createFilterForUuids(uuids), handler: handler)
    }
    
    func listItem(list: List, product: Product, handler: ListItem? -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.loadFirst(mapper, filter: DBListItem.createFilter(list, product: product), handler: handler)
    }
    
    func findListItem(uuid: String, _ handler: ListItem? -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.loadFirst(mapper, filter: DBListItem.createFilter(uuid), handler: handler)
    }

    func findListItemWithUnique(productName: String, productBrand: String, list: List, handler: ListItem? -> Void) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.loadFirst(mapper, filter: DBListItem.createFilterUniqueInList(productName, productBrand: productBrand, list: list), handler: handler)
    }

    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    func deletePossibleListItemWithUnique(productName: String, productBrand: String, notUuid: String, list: List, handler: Bool -> Void) {
        removeReturnCount(DBListItem.createFilterUniqueInListNotUuid(productName, productBrand: productBrand, notUuid: notUuid, list: list), handler: {removedCountMaybe in
            if let removedCount = removedCountMaybe {
                if removedCount > 0 {
                    QL2("Found list item with same name+brand in list, deleted it. Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
                }
            } else {
                QL4("Remove didn't succeed: Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
            }

            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: DBListItem.self)
    }
    
    // hm...
    func loadAllListItems(handler: [ListItem] -> ()) {
        let mapper = {ListItemMapper.listItemWithDB($0)}
        self.load(mapper, handler: handler)
    }
    
    func remove(listItem: ListItem, markForSync: Bool, handler: Bool -> ()) {
        remove(listItem.uuid, listUuid: listItem.list.uuid, sectionUuid: listItem.section.uuid, markForSync: markForSync, handler: handler)
    }

    func remove(listItemUuid: String, listUuid: String, sectionUuid sectionUuidMaybe: String? = nil, markForSync: Bool, handler: Bool -> ()) {

        doInWriteTransaction({realm in
            
            let result = realm.objects(DBListItem).filter(DBListItem.createFilter(listItemUuid))
            
            if markForSync { // add tombstone
                if let dbListItem = result.first {
                    let toRemoveListItem = DBRemoveListItem(dbListItem)
                    realm.add(toRemoveListItem, update: true)
                } else {
                    QL3("Trying to add tombstone for not existing list item") // if this is because we received a websocket notification and maybe list item was deleted in the meantime, it's ok. Should happen not very frequently though.
                }
            }

            // delete item
            realm.delete(result)
            return true
            
            }) { (successMaybe: Bool?) -> Void in
                handler(successMaybe ?? false)
        }
    }
// This removes the section when after removing a list item the section is empty. After some thought we prefer to not use this, since removing all the list items in the section doesn't necessarily mean that the user wants to delete the section also. User is always able to delete section directly, or delete it from autosuggestions. This also relates with reorder - here we also don't remove empty sections (section can become empty during reordering when user moves items from one section to another), in this case it has a ux reason, this way the header stays in the table and user can still move items to it, even if it's empty. So to keep things consistent we just don't remove the section in all cases and leave to the user to directly remove it if this is desired. Note that switching status isn't mentioned, while we can leave a section empty in one status, it will be not empty in the dst target status as we are switching the item to it so a section will never be completely empty here.
//    func remove(listItemUuid: String, listUuid: String, sectionUuid sectionUuidMaybe: String? = nil, markForSync: Bool, handler: Bool -> ()) {
//        
//        let additionalActions: (Realm -> Void)? = markForSync ? {realm in
//            // TODO!!!! lastServerUpdate? what should it be? do we need this here?
//            let toRemoveListItem = DBRemoveListItem(uuid: listItemUuid, listUuid: listUuid, lastServerUpdate: 0)
//            realm.add(toRemoveListItem, update: true)
//            } : nil
//        
//        doInWriteTransaction({realm in
//            realm.delete(realm.objects(DBSection).filter(DBListItem.createFilter(listItemUuid)))
//            
//            let sectionUuidMaybeAfterTryRetrieve: String? = sectionUuidMaybe ?? {
//                return realm.objects(DBListItem).filter(DBListItem.createFilter(listItemUuid)).first?.section.uuid
//                }()
//            
//            additionalActions?(realm)
//            
//            // remove the section if it's now empty
//            if let sectionUuid = sectionUuidMaybeAfterTryRetrieve {
//                DBProviders.sectionProvider.removeSectionIfEmptySync(realm, sectionUuid: sectionUuid)
//                return true
//            } else {
//                QL4("Warning/maybe error: Section of list item to be removed was not found in database") // with websockets this can happen, though it should be rare - we receive a message to remove a list item just after user removed the section. If we see this log frequently though, it's likely something else/an actual error.
//                return false
//            }
//            
//            }) { (successMaybe: Bool?) -> Void in
//                handler(successMaybe ?? false)
//        }
//    }
    
    func updateListItems(listItems: [ListItem], handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            return self?.updateListItemsSync(realm, listItems: listItems)
            }, finishHandler: {listItemsMaybe in
                handler(listItemsMaybe ?? false)
        })
    }
    
    func updateListItemsSync(realm: Realm, listItems: [ListItem]) -> Bool {
        for listItem in listItems {
            let dbListItem = ListItemMapper.dbWithListItem(listItem)
            realm.add(dbListItem, update: true)
        }

        return true
    }
    
    func overwrite(listItems: [ListItem], listUuid: String, clearTombstones: Bool, handler: Bool -> ()) {
        let dbListItems = listItems.map{ListItemMapper.dbWithListItem($0)}
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilterForList(listUuid))} : nil
        self.overwrite(dbListItems, deleteFilter: DBListItem.createFilterList(listUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
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
    func incrementListItem(item: ListItem, delta: Int, status: ListItemStatus, handler: ListItem? -> Void) {
        incrementListItem(ItemIncrement(delta: delta, itemUuid: item.uuid), status: status, handler: handler)
    }

    func incrementListItem(increment: ItemIncrement, status: ListItemStatus, handler: ListItem? -> Void) {

        doInWriteTransaction({realm in

            return syncedRet(self) {

                let dbListItems = realm.objects(DBListItem).filter(DBListItem.createFilter(increment.itemUuid)).toArray()
                let listItems = dbListItems.map{ListItemMapper.listItemWithDB($0)}
                
                if let listItem = listItems.first {
                    let incrementedListitem = listItem.increment(ListItemStatusQuantity(status: status, quantity: increment.delta))
                    
                    let dbIncrementedItem = ListItemMapper.dbWithListItem(incrementedListitem)
                    
                    realm.add(dbIncrementedItem, update: true)

                    return incrementedListitem
                    
                } else {
                    QL3("List item not found: \(increment)")
                    return nil
                }
            }


        }) { (statusQuantityMaybe) -> Void in
                handler(statusQuantityMaybe)
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
    
    func updateListItemWithIncrementResult(incrementResult: RemoteListItemIncrementResult, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(DBListItem).filter(DBListItem.createFilter(incrementResult.uuid)).first) {
                
                // store the timestamp only if it matches with the current quantity. E.g. if user increments very quicky 1,2,3,4,5,6
                // we may receive the response from server for 1 when the database is already at 4 - so we don't want to store 1's timestamp for 4. When the user stops at 6 only the timestamp with the response with 6 quantity will be stored.
                if storedItem.quantityForStatus(incrementResult.status) == incrementResult.updatedQuantity {
                    
                    // TODO review now that we check for quantity (above) maybe this check is unnecessary
                    // If 2 items have the same timestamp (were updated in the same millisecond), we choose the one arriving latest, so we use <= instead of only <. If we used only < we would ignore all possible further updates with equal timestamps. The reason for this is that, being imposible to know the order since the timestamp is equal, all what's left is assume the latest to arrive was the latest update, which is somewhat better than assuming it was not. --- IF the item we store is still the wrong one, which is unlikely but can happen, it will likely be corrected soon by the background update done in view did appear in list items. The only situation I can currently think about where this causes to lose an update, is if, after updating with the wrong quantity, the user goes offline, in this case the data will not be "corrected" by downloading it again from the server and in the next sync it will be uploaded. ---> TODO! fix - this is most likely a server only fix, sometimes the server log of the repeated timestamp shows also repeated quantity (but the quantity in the db is still correct), meaning that the read operations after the updates of each of these items seem to be executed "together" reading only the last update result (so the write+read of each increment is not isolated - for 2 increments, instead of write+read,write+read we get write+write,read+read), in other cases the log shows actually different quantities with the same timestamp meaning the updates were written with the same timestamp. This last situation is also a bit strange since the database is using milliseconds, probably the operations are grouped together or something such that they are executed almost simustaneously.
                    if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                        
                        let updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                        realm.create(DBListItem.self, value: updateDict, update: true)
                        QL1("Updateded list item with increment result dict: \(updateDict)")
                        
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
    
    func updateStore(oldName: String, newName: String, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(DBStoreProduct).filter(DBStoreProduct.createFilterStore(oldName))
            for dbProduct in dbProducts {
                dbProduct.store = newName
                realm.add(dbProduct, update: true)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func removeStore(name: String, _ handler: Bool -> Void) {
        updateStore(name, newName: "", handler)
    }
    
    private func updateTimestampsSync(realm: Realm, listItems: [ListItem], lastUpdate: Int64) {
        for listItem in listItems {
            realm.create(DBListItem.self, value: DBListItem.timestampUpdateDict(listItem.uuid, lastUpdate: lastUpdate), update: true)
        }
    }

    private func updateTimestampsSync(realm: Realm, items: [InventoryItemWithHistoryItem], lastUpdate: Int64) {
        for item in items {
            realm.create(DBInventoryItem.self, value: DBSyncable.timestampUpdateDict(item.inventoryItem.uuid, lastServerUpdate: lastUpdate), update: true)
            realm.create(DBHistoryItem.self, value: DBSyncable.timestampUpdateDict(item.historyItem.uuid, lastServerUpdate: lastUpdate), update: true)
        }
    }
    
    func storeBuyCartResult(listItems: [ListItem], inventoryWithHistoryItems: [InventoryItemWithHistoryItem], lastUpdate: Int64, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateTimestampsSync(realm, listItems: listItems, lastUpdate: lastUpdate)
            self?.updateTimestampsSync(realm, items: inventoryWithHistoryItems, lastUpdate: lastUpdate)
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    // adds inventory/history items and stores the switched list items in a transaction
    // Note "switched"ListItems -> The status of the passed list items is expected to be already updated, this transaction just saves them to the db.
    func buyCart(listUuid: String, switchedItems: [ListItem], inventory: Inventory, itemInputs: [ProductWithQuantityInput], remote: Bool, _ handler: ProviderResult<[InventoryItemWithHistoryItem]> -> Void) {
        doInWriteTransaction({realm in
            
            let items = DBProviders.inventoryItemProvider.addOrIncrementInventoryItemsWithProductSync(realm, itemInputs: itemInputs, inventory: inventory, dirty: remote)
            
            DBProviders.listItemProvider.updateListItemsSync(realm, listItems: switchedItems)
            
            return items
            
            }) {(itemsMaybe: [InventoryItemWithHistoryItem]?) in
            if let items = itemsMaybe {
                handler(ProviderResult(status: .Success, sucessResult: items))
            } else {
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
}
