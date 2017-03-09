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

public enum QuickAddItemSortBy {
    case alphabetic, fav
}


public struct AddListItemResult {
    public let listItem: ListItem
    public let section: Section
    public let isNewItem: Bool
    public let isNewSection: Bool
    public let listItemIndex: Int
    public let sectionIndex: Int
}

public struct UpdateListItemResult {
    public let listItem: ListItem
    public let replaced: Bool
    public let changedSection: Bool
}

public struct AddCartListItemResult {
    public let listItem: ListItem
    public let section: Section
    public let isNewItem: Bool
    public let isNewSection: Bool
    public let listItemIndex: Int
}

public struct MoveListItemResult {
    public let deletedSrcSection: Bool
}

public struct DeleteListItemResult {
    public let deletedSection: Bool
}

public struct SwitchListItemResult {
    public let deletedSection: Bool
}

public struct ListItemsCartStashAggregate {
    public let cartQuantity: Float
    public let cartPrice: Float
    public let stashQuantity: Float
    public let todoPrice: Float
}

class RealmListItemProvider: RealmProvider {
    
    /**
    Batch add/update of list items
    When used for add: incrementQuantity should be true, update: false. After clearing db (e.g. sync) also false (since there's nothing to increment)
    NOTE: Assumes all listItems belong to the same list (only the list of first list item is used for filtering)
    */
    func addOrIncrementListItems(_ listItems: [ListItem], updateSection: Bool = true, handler: @escaping ([ListItem]?) -> ()) {
        
        let listItems = listItems.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions
        
        doInWriteTransaction({[weak self] realm in
            self?.addOrIncrementListItemsSync(realm, listItems: listItems, updateSection: updateSection)
            }, finishHandler: {listItemsMaybe in
                handler(listItemsMaybe)
        })
    }
    
    func addOrIncrementListItemsSync(_ realm: Realm, listItems: [ListItem], updateSection: Bool = true) -> [ListItem] {
        var listItems = listItems
        
//        let existingListItems = realm.objects(ListItem.self).filter(ListItem.createFilterListItems(listItems))
        let existingListItems = listItems
        
        let uuidToListItemDict: [String: ListItem] = existingListItems.toDictionary{
            ($0.product.uuid, $0)
        }
        // merge list items with existing, in order to do update (increment quantity)
        // this means: use uuid of existing item, increment quantity, and for the rest copy fields of new item
        listItems = listItems.map {listItem in
            if let existingListItem = uuidToListItemDict[listItem.product.uuid] {
                return listItem.increment(existingListItem.todoQuantity, doneQuantity: existingListItem.doneQuantity, stashQuantity: existingListItem.stashQuantity)
            } else {
                return listItem
            }
        }
        
        for listItem in listItems {
            realm.add(listItem, update: true)
        }
        
        return listItems
    }
    
    func updateListItemsOrderLocal(_ orderUpdates: [RemoteListItemReorder], sections: [Section], status: ListItemStatus, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            
            // order update can change the section a list item is in, so we need to update the section too.
            let sectionDict = sections.toDictionary{($0.uuid, $0)}
            
            for orderUpdate in orderUpdates {
                if let section = sectionDict[orderUpdate.sectionUuid] {
                    realm.create(ListItem.self, value: orderUpdate.updateDict(status, dbSection: section), update: true)
                } else {
                    QL4("Invalid state, section object corresponding to uuid: \(orderUpdate.sectionUuid) was not found")
                }
            }
            
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                if let success = successMaybe {
                    if success {
                        Prov.listItemsProvider.invalidateMemCache()
                    }
                }
                handler(successMaybe ?? false)
        })
    }
    
    func storeRemoteListItemSwitchResult(_ statusUpdate: ListItemStatusUpdate, result: RemoteSwitchListItemResult, _ handler: @escaping (Bool) -> Void) {

        doInWriteTransaction({realm in

            let lastUpdate = result.lastUpdate
            
            let switchedItem = result.switchedItem
            let itemDict: [String: AnyObject] = [
                "uuid": switchedItem.uuid as AnyObject,
                "todoQuantity": switchedItem.todoQuantity as AnyObject,
                "doneQuantity": switchedItem.doneQuantity as AnyObject,
                "todoOrder": switchedItem.todoOrder as AnyObject,
                "doneOrder": switchedItem.doneOrder as AnyObject,
                "stashOrder": switchedItem.stashOrder as AnyObject,
                DBSyncable.lastUpdateFieldName: lastUpdate as AnyObject
            ]
            
            let srcOrderUpdateKey: String = {
                switch statusUpdate.src {
                case .todo: return "todoOrder"
                case .done: return "doneOrder"
                case .stash: return "stashOrder"
                }
            }()
            
            let srcItemsOrderDicts = result.itemOrderUpdates.map {item in
                return ["uuid": item.uuid as AnyObject,
                        srcOrderUpdateKey: item.order as AnyObject,
                        DBSyncable.lastUpdateFieldName: lastUpdate as AnyObject
                ]
            }
            
            let sectionsOrderDicts = result.sectionOrderUpdates.map {item in
                return ["uuid": item.uuid as AnyObject,
                        "todoOrder": item.todoOrder as AnyObject,
                        "doneOrder": item.doneOrder as AnyObject,
                        "stashOrder": item.stashOrder as AnyObject,
                        DBSyncable.lastUpdateFieldName: lastUpdate
                ]
            }

            realm.create(ListItem.self, value: itemDict, update: true)
            srcItemsOrderDicts.forEach {
                realm.create(ListItem.self, value: $0, update: true)
            }
            sectionsOrderDicts.forEach {
                realm.create(Section.self, value: $0, update: true)
            }
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO these are a bit weird, the data we store on switch all via rest and websockets should be the same? if we need same handling, needs server changes as the data sent is different
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func storeRemoteAllListItemSwitchResult(_ statusUpdate: ListItemStatusUpdate, result: RemoteSwitchAllListItemsResult, _ handler: @escaping (Bool) -> Void) {
        
        doInWriteTransaction({realm in
            
            let lastUpdate = result.lastUpdate
            
            func quantityKey(_ status: ListItemStatus) -> String {
                switch status {
                case .todo: return "todoQuantity"
                case .done: return "doneQuantity"
                case .stash: return "stashQuantity"
                }
            }
            func orderKey(_ status: ListItemStatus) -> String {
                switch status {
                case .todo: return "todoOrder"
                case .done: return "doneOrder"
                case .stash: return "stashOrder"
                }
            }
            
            result.items.forEach {item in
                let dict = ["uuid": item.uuid as AnyObject,
                            orderKey(statusUpdate.dst): item.dstOrder as AnyObject,
                            quantityKey(statusUpdate.dst): item.dstQuantity as AnyObject,
                            DBSyncable.lastUpdateFieldName: NSNumber(value: Int64(lastUpdate))
                ]
                realm.create(ListItem.self, value: dict, update: true)
            }
            
            result.sections.forEach {section in
                let dict = ["uuid": section.uuid as AnyObject,
                            orderKey(statusUpdate.dst): section.dstOrder as AnyObject,
                            DBSyncable.lastUpdateFieldName: NSNumber(value: Int64(lastUpdate))
                ]
                realm.create(Section.self, value: dict, update: true)
            }
            
            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    // For websockets we just refresh the timestamps. For rest response we update quantity+order, the reason for this is bc concurrency etc. maybe the items get a different order or quantity in the server and we update then the client immediately, sending the state in the response. For websockets we don't have time and chose the most quick implementation which is to send just the timestamp and update the switched client list items with this timestamp.
    func storeWebsocketAllListItemSwitchResult(_ listitems: [ListItem], lastUpdate: Int64, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            listitems.forEach {item in
                let dict = ["uuid": item.uuid as AnyObject,
                            DBSyncable.lastUpdateFieldName: NSNumber(value: Int64(lastUpdate))
                ]
                realm.create(ListItem.self, value: dict, update: true)
            }

            return true
            
            }, finishHandler: {(successMaybe: Bool?) in
                handler(successMaybe ?? false)
        })
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    func addListItem(_ status: ListItemStatus, product: StoreProduct, sectionNameMaybe: String?, sectionColorMaybe: UIColor?, quantity: Float, list: List, note noteMaybe: String? = nil, _ handler: @escaping (ListItem?) -> Void) {
        
        fatalError("Outdated (Unit refactoring)")
//        
//        // Fixes Realm acces in incorrect thread exceptions
//        let product = product.copy()
//        let list = list.copy()
//        
//        doInWriteTransaction({realm in
//            
//            return syncedRet(self) {
//                
//                // see if there's already a listitem for this product in the list - if yes only increment it
//                if let existingListItem = realm.objects(ListItem.self).filter(ListItem.createFilterWithQuantifiableProduct(name: product.product.product.item.name, unit: product.product.unit)).first {
//                    existingListItem.increment(ListItemStatusQuantity(status: status, quantity: quantity))
//                    
//                    // possible updates (when user submits a new list item using add edit product controller)
//                    if let sectionName = sectionNameMaybe {
//                        existingListItem.section.name = sectionName
//                    }
//                    if let note = noteMaybe {
//                        existingListItem.note = note
//                    }
//                    
//                    // TODO!! update sectionnaeme, note (for case where this is from add product with inputs)
//                    realm.add(existingListItem, update: true)
//                    return existingListItem
//                    
//                } else { // no list item for product in the list, create a new one
//                    
//                    // see if there's already a section for the new list item in the list, if not create a new one
//                    let listItemsInList = realm.objects(ListItem.self).filter(ListItem.createFilterList(list.uuid))
//                    let sectionName = sectionNameMaybe ?? product.product.product.item.category.name
//                    let sectionColor = sectionColorMaybe ?? product.product.product.item.category.color
//                    let section = listItemsInList.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
//                        return item.section
//                        } ?? {
//                            let sectionCount = Set(listItemsInList.map{$0.section}).count
//                            return Section(uuid: NSUUID().uuidString, name: sectionName, color: sectionColor, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
//                        }()
//                    
//                    
//                    // calculate list item order, which is at the end of it's section (==count of listitems in section). Note that currently we are doing this iteration even if we just created the section, where order is always 0. This if for clarity - can be optimised later (TODO)
//                    var listItemOrder = 0
//                    for existingListItem in listItemsInList {
//                        if existingListItem.section.uuid == section.uuid {
//                            listItemOrder += 1
//                        }
//                    }
//                    
//                    // create the list item and save it
//                    let listItem = ListItem(uuid: NSUUID().uuidString, product: product, section: section, list: list, statusOrder: ListItemStatusOrder(status: status, order: listItemOrder), statusQuantity: ListItemStatusQuantity(status: status, quantity: quantity))
//                    
//                    realm.add(listItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
//                    return listItem
//                }
//            }
//        }, finishHandler: {(savedListItemMaybe: ListItem?) in
//                handler(savedListItemMaybe)
//        })
    }

    // TODO do we really need status
    func loadListItems(_ list: List, status: ListItemStatus? = nil, handler: @escaping (Results<ListItem>?) -> Void) {
        loadListItems(list.uuid, status: status, handler: handler)
    }

    // TODO do we really need status
    func loadListItems(_ listUuid: String, status: ListItemStatus? = nil, handler: @escaping (Results<ListItem>?) -> Void) {
        
        let sortDescriptors: [SortDescriptor] = status.map {status in
            let sectionOrderFieldName = Section.orderFieldName(status)
            let listItemOrderFieldName = ListItem.orderFieldName(status)
            return [SortDescriptor(keyPath: sectionOrderFieldName, ascending: true), SortDescriptor(keyPath: listItemOrderFieldName, ascending: true)]
        } ?? []
        
        let filter = status.map {status in
            ListItem.createFilter(listUuid: listUuid, status: status)
        } ?? ListItem.createFilterList(listUuid)

        handler(loadSync(filter: filter, sortDescriptors: sortDescriptors))
    }
    
    func loadListItems(_ uuids: [String], handler: @escaping (Results<ListItem>?) -> Void) {
        handler(loadSync(filter: ListItem.createFilterForUuids(uuids), sortDescriptor: nil))
    }
    
    
    func listItems<T>(list: List, ingredient: Ingredient, mapper: @escaping (Results<ListItem>) -> T, _ handler: @escaping (T?) -> Void) {
        
        // Realm threads
        let list = list.copy()
        let ingredient = ingredient.copy()
        
        withRealm({realm -> T? in
            let listItems = realm.objects(ListItem.self).filter(ListItem.createFilterWithProductName(ingredient.item.name, listUuid: list.uuid))
            return mapper(listItems)

        }) {mappingResultMaybe in
            handler(mappingResultMaybe)
        }
    }
    
    func listItem(_ list: List, product: Product, handler: @escaping (ListItem?) -> Void) {
        handler(loadFirstSync(filter: ListItem.createFilter(list, product: product)))
    }
    
    func findListItem(_ uuid: String, _ handler: @escaping (ListItem?) -> Void) {
        handler(loadFirstSync(filter: ListItem.createFilter(uuid)))
    }

    func findListItemWithUnique(_ productName: String, productBrand: String, list: List, handler: @escaping (ListItem?) -> Void) {
        handler(loadFirstSync(filter: ListItem.createFilterUniqueInList(productName, productBrand: productBrand, list: list)))
    }

    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    func deletePossibleListItemWithUnique(_ productName: String, productBrand: String, notUuid: String, list: List, handler: @escaping (Bool) -> Void) {
        removeReturnCount(ListItem.createFilterUniqueInListNotUuid(productName, productBrand: productBrand, notUuid: notUuid, list: list), handler: {removedCountMaybe in
            if let removedCount = removedCountMaybe {
                if removedCount > 0 {
                    QL2("Found list item with same name+brand in list, deleted it. Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
                }
            } else {
                QL4("Remove didn't succeed: Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
            }

            handler(removedCountMaybe.map{$0 > 0} ?? false)
        }, objType: ListItem.self)
    }
    
    // Handler returns true if it deleted something, false if there was nothing to delete or an error ocurred.
    // TODO!!!!!!!!!!!!  messy implementation - if doOwnTransaction is false it shouldn't be possible to pass nil realm. Maybe it's actually not necessary to pass realm around when everything has to be in the same transaction(check this)
    func deletePossibleListItemWithUniqueSync(_ productName: String, productBrand: String, notUuid: String, list: List, realmData: RealmData?, doTransaction: Bool = true) -> Bool {
        
        func transactionContent(realm: Realm) -> Bool {
            return removeReturnCountSync(realm, pred: ListItem.createFilterUniqueInListNotUuid(productName, productBrand: productBrand, notUuid: notUuid, list: list), objType: ListItem.self).map {removedCount in
                if removedCount > 0 {
                    QL2("Found list item with same name+brand in list, deleted it. Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
                }
                return removedCount > 0
                } ?? {
                    QL4("Remove didn't succeed: Name: \(productName), brand: \(productBrand), list: {\(list.uuid), \(list.name)}")
                    return false
            }()
        }
        
        if doTransaction {
            return doInWriteTransactionSync(realmData: realmData) {realm in
                return transactionContent(realm: realm)
            } ?? false
        } else {
            if let realm = realmData?.realm {
                return transactionContent(realm: realm)
            } else {
                QL4("Invalid state: when do own transaction == false a realm should be passed")
                return false
            }
        }
    }
    
    // hm...
    func loadAllListItems(_ handler: @escaping (Results<ListItem>?) -> Void) {
        handler(loadSync(filter: nil))
    }
    
    func remove(_ listItem: ListItem, markForSync: Bool, token: RealmToken?, handler: @escaping (Bool) -> ()) {
        remove(listItem.uuid, listUuid: listItem.list.uuid, sectionUuid: listItem.section.uuid, markForSync: markForSync, token: token, handler: handler)
    }

    func remove(_ listItemUuid: String, listUuid: String, sectionUuid sectionUuidMaybe: String? = nil, markForSync: Bool, token: RealmToken?, handler: @escaping (Bool) -> ()) {

        let tokens = token.map{[$0.token]} ?? []
        
        let successMaybe = doInWriteTransactionSync(withoutNotifying: tokens, realm: token?.realm, {realm -> Bool in
            
            let result = realm.objects(ListItem.self).filter(ListItem.createFilter(listItemUuid))
            
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
        })
        
        handler(successMaybe ?? false)
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
//            realm.delete(realm.objects(Section).filter(ListItem.createFilter(listItemUuid)))
//            
//            let sectionUuidMaybeAfterTryRetrieve: String? = sectionUuidMaybe ?? {
//                return realm.objects(ListItem).filter(ListItem.createFilter(listItemUuid)).first?.section.uuid
//                }()
//            
//            additionalActions?(realm)
//            
//            // remove the section if it's now empty
//            if let sectionUuid = sectionUuidMaybeAfterTryRetrieve {
//                DBProv.sectionProvider.removeSectionIfEmptySync(realm, sectionUuid: sectionUuid)
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
    
    func updateListItems(_ listItems: [ListItem], handler: @escaping (Bool) -> Void) {
        
        handler(doInWriteTransactionSync {realm in
            return updateListItemsSync(realm, listItems: listItems)
        } ?? false)

    }
    
    func updateListItemsSync(_ realm: Realm, listItems: [ListItem]) -> Bool {
        for listItem in listItems {
            realm.add(listItem, update: true)
        }

        return true
    }
    
    func overwrite(_ listItems: [ListItem], listUuid: String, clearTombstones: Bool, handler: @escaping (Bool) -> ()) {
        let dbListItems: [ListItem] = listItems.map{$0.copy()} // Fixes Realm acces in incorrect thread exceptions
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilterForList(listUuid))} : nil
        self.overwrite(dbListItems, deleteFilter: ListItem.createFilterList(listUuid), resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    /**
    Gets list items count with a certain status in a certain list
    */
    func listItemCount(_ status: ListItemStatus, list: List, handler: @escaping (Int?) -> Void) {
        
        let listCopy = list.copy() // Fixes Realm acces in incorrect thread exceptions
        
        let finished: (Int?) -> Void = {result in
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
        DispatchQueue.global(qos: .background).async {
            do {
                let realm = try Realm()
                let listItems = realm.objects(ListItem.self).filter(ListItem.createFilterList(listCopy.uuid))
                let count = listItems.filter{$0.hasStatus(status)}.count
                finished(count)
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished(nil) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
    }
    
    // TODO Asynchronous. dispatch_async + lock inside for some reason didn't work correctly (tap 10 times on increment, only shows 4 or so (after refresh view controller it's correct though), maybe use serial queue?
    // TODO probably remove TODO above, outdated
    // TODO remove status parameter we don't use this anymore (list item itself belongs to a status)
    func incrementListItem(_ item: ListItem, delta: Float, status: ListItemStatus, handler: @escaping (ListItem?) -> Void) {
        let listItemMaybe: ListItem? = doInWriteTransactionSync {realm in
            item.quantity = item.quantity + delta
            return item
        }
        
        handler(listItemMaybe)
    }

    // TODO!!!!!!!!!!!!!!!!!!!! is this used? if not remove. Implementation doesn't work correctly, it removes sections or list items as "side effect"
    func incrementListItem(_ increment: ItemIncrement, status: ListItemStatus, handler: @escaping (ListItem?) -> Void) {
        QL4("Outdated")
        
        doInWriteTransaction({(realm: Realm) -> String? in

            return syncedRet(self) {

                let listItems = realm.objects(ListItem.self).filter(ListItem.createFilter(increment.itemUuid)).toArray()
                
                if let listItem = listItems.first {
                    let incrementedListitem = listItem.increment(ListItemStatusQuantity(status: status, quantity: increment.delta))
                    
                    realm.add(incrementedListitem, update: true)

                    return incrementedListitem.uuid
                    
                } else {
                    QL3("List item not found: \(increment)")
                    return nil
                }
            }


        }) { (listItemUuidMaybe) -> Void in
            guard let listItemUuid = listItemUuidMaybe else {QL4("No uuid"); handler(nil); return}
            
            do {
                if let listItem = try Realm().object(ofType: ListItem.self, forPrimaryKey: listItemUuid) {
                    handler(listItem)
                    
                } else {
                    QL4("Unexpected: No item for uuid: \(listItemUuid)")
                    handler(nil)
                }
            } catch let e {
                QL4("Error: \(e), getting item for uuid: \(listItemUuidMaybe)")
                handler(nil)
            }
        }
    }
    
    // MARK: - Sync

    func clearListItemTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func clearListItemTombstonesForList(_ listUuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBRemoveListItem.self, DBRemoveListItem.createFilterForList(listUuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // TODO! is this method still necessary? we have global sync now
    func saveListsSyncResult(_ syncResult: RemoteListWithListItemsSyncResult, handler: @escaping (Bool) -> ()) {
        
        doInWriteTransaction({realm in
            
            let inventories = realm.objects(List.self)
            let inventoryItems = realm.objects(ListItem.self)
            let sections = realm.objects(Section.self)

            realm.delete(inventories)
            realm.delete(inventoryItems)
            realm.delete(sections)
            // we don't delete the products because these are referenced also by inventory items and maybe also other things in the future
            
            // save inventories
            let lists = ListMapper.listsWithRemote(syncResult.lists)
            let remoteInventories = lists
            for remoteInventory in remoteInventories {
                let dbInventory = remoteInventory
                realm.add(dbInventory, update: true)
            }
            
            // save inventory items
            for listItemsSyncResult in syncResult.listItemsSyncResults {
                
                let listItemsWithRelations = ListItemMapper.listItemsWithRemote(listItemsSyncResult.listItems, sortOrderByStatus: nil)
                
                for product in listItemsWithRelations.products {
                    realm.add(product, update: true) // since we don't delete products (see comment above) we do update
                }
                
                for section in listItemsWithRelations.sections {
//                    let dbSection = SectionMapper.dbWithSection(section)
                    realm.add(section, update: true)
                }
                
                for listItem in listItemsWithRelations.listItems {
                    realm.add(listItem, update: true)

                }
            }
            
            return true
            
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateListItemWithIncrementResult(_ incrementResult: RemoteListItemIncrementResult, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let storedItem = (realm.objects(ListItem.self).filter(ListItem.createFilter(incrementResult.uuid)).first) {
                
                // store the timestamp only if it matches with the current quantity. E.g. if user increments very quicky 1,2,3,4,5,6
                // we may receive the response from server for 1 when the database is already at 4 - so we don't want to store 1's timestamp for 4. When the user stops at 6 only the timestamp with the response with 6 quantity will be stored.
                if storedItem.quantityForStatus(incrementResult.status) == incrementResult.updatedQuantity {
                    
                    // TODO review now that we check for quantity (above) maybe this check is unnecessary
                    // If 2 items have the same timestamp (were updated in the same millisecond), we choose the one arriving latest, so we use <= instead of only <. If we used only < we would ignore all possible further updates with equal timestamps. The reason for this is that, being imposible to know the order since the timestamp is equal, all what's left is assume the latest to arrive was the latest update, which is somewhat better than assuming it was not. --- IF the item we store is still the wrong one, which is unlikely but can happen, it will likely be corrected soon by the background update done in view did appear in list items. The only situation I can currently think about where this causes to lose an update, is if, after updating with the wrong quantity, the user goes offline, in this case the data will not be "corrected" by downloading it again from the server and in the next sync it will be uploaded. ---> TODO! fix - this is most likely a server only fix, sometimes the server log of the repeated timestamp shows also repeated quantity (but the quantity in the db is still correct), meaning that the read operations after the updates of each of these items seem to be executed "together" reading only the last update result (so the write+read of each increment is not isolated - for 2 increments, instead of write+read,write+read we get write+write,read+read), in other cases the log shows actually different quantities with the same timestamp meaning the updates were written with the same timestamp. This last situation is also a bit strange since the database is using milliseconds, probably the operations are grouped together or something such that they are executed almost simustaneously.
                    if (storedItem.lastServerUpdate <= incrementResult.lastUpdate) {
                        
                        let updateDict: [String: AnyObject] = DBSyncable.timestampUpdateDict(incrementResult.uuid, lastServerUpdate: incrementResult.lastUpdate)
                        realm.create(ListItem.self, value: updateDict, update: true)
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
    
    
    func updateListItemLastSyncTimeStamp(_ updateDict: [String: AnyObject], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateListItemLastSyncTimeStamp(realm, updateDict: updateDict)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    func updateListItemsLastSyncTimeStamps(_ updateDicts: [[String: AnyObject]], handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            for updateDict in updateDicts {
                self?.updateListItemLastSyncTimeStamp(realm, updateDict: updateDict)
            }
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func updateListItemLastSyncTimeStamp(_ realm: Realm, updateDict: [String: AnyObject]) {
        realm.create(ListItem.self, value: updateDict, update: true)
    }
    
    func updateLastSyncTimeStamp(_ listItems: RemoteListItems, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self]realm in
            for listItem in listItems.listItems {
                self?.updateListItemLastSyncTimeStamp(realm, updateDict: listItem.timestampUpdateDict)
            }
            for product in listItems.products {
                realm.create(Product.self, value: product.timestampUpdateDict, update: true)
            }
            for productCategory in listItems.productsCategories {
                realm.create(ProductCategory.self, value: productCategory.timestampUpdateDict, update: true)
            }
            for section in listItems.sections {
                realm.create(Section.self, value: section.timestampUpdateDict, update: true)
            }
            DBProv.listProvider.updateLastSyncTimeStampSync(realm, lists: listItems.lists)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }

    
    func updateLastSyncTimeStamp(_ product: RemoteProduct, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({[weak self] realm in
            self?.updateLastSyncTimeStampSync(realm, product: product)
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // FIXME repeated method with RealmProductGroupProvider
    func updateLastSyncTimeStampSync(_ realm: Realm, product: RemoteProduct) {
        realm.create(Product.self, value: product.timestampUpdateDict, update: true)
    }
    
    func updateStore(_ oldName: String, newName: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            let dbProducts = realm.objects(StoreProduct.self).filter(StoreProduct.createFilterStore(oldName))
            for dbProduct in dbProducts {
                dbProduct.store = newName
                realm.add(dbProduct, update: true)
            }
            return true
            }, finishHandler: {savedMaybe in
                handler(savedMaybe ?? false)
        })
    }
    
    func removeStore(_ name: String, _ handler: @escaping (Bool) -> Void) {
        updateStore(name, newName: "", handler)
    }
    
    fileprivate func updateTimestampsSync(_ realm: Realm, listItems: [ListItem], lastUpdate: Int64) {
        for listItem in listItems {
            realm.create(ListItem.self, value: ListItem.timestampUpdateDict(listItem.uuid, lastUpdate: lastUpdate), update: true)
        }
    }

    fileprivate func updateTimestampsSync(_ realm: Realm, items: [InventoryItemWithHistoryItem], lastUpdate: Int64) {
        for item in items {
            realm.create(InventoryItem.self, value: DBSyncable.timestampUpdateDict(item.inventoryItem.uuid, lastServerUpdate: lastUpdate), update: true)
            realm.create(HistoryItem.self, value: DBSyncable.timestampUpdateDict(item.historyItem.uuid, lastServerUpdate: lastUpdate), update: true)
        }
    }
    
    func storeBuyCartResult(_ listItems: [ListItem], inventoryWithHistoryItems: [InventoryItemWithHistoryItem], lastUpdate: Int64, handler: @escaping (Bool) -> Void) {
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
    func buyCart(_ listUuid: String, switchedItems: [ListItem], inventory: DBInventory, itemInputs: [ProductWithQuantityInput], remote: Bool, _ handler: @escaping (ProviderResult<[InventoryItemWithHistoryItem]>) -> Void) {
        doInWriteTransaction({realm in
            
            let items = DBProv.inventoryItemProvider.addOrIncrementInventoryItemsWithProductSync(realm, itemInputs: itemInputs, inventory: inventory, dirty: remote)
            
            _ = DBProv.listItemProvider.updateListItemsSync(realm, listItems: switchedItems)
            
            return items
            
            }) {(itemsMaybe: [InventoryItemWithHistoryItem]?) in
            if let items = itemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: items))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // MARK: - Sync
    
    
    func toListItemProtoypes(inputs: [ListItemInput], status: ListItemStatus, list: List) -> ProvResult<[ListItemPrototype], DatabaseError>  {
        
        let listItemPrototypes = inputs.map {input -> ProvResult<ListItemPrototype, DatabaseError> in
            
            let sectionResult = DBProv.sectionProvider.mergeOrCreateSectionSync(input.section, sectionColor: input.sectionColor, status: status, possibleNewOrder: nil, list: list, realmData: nil)
            let quantifiableProductResult = DBProv.productProvider.mergeOrCreateQuantifiableProductSync(prototype: input.toProductPrototype(), updateCategory: true, save: false)
            
            return sectionResult.join(result: quantifiableProductResult).map {(tuple, quantifiableProduct) in
                ListItemPrototype(product: quantifiableProduct, quantity: input.quantity, targetSectionName: tuple.section.name, targetSectionColor: tuple.section.color, storeProductInput: nil)
            }
        }
        
        return ProvResult<ListItemPrototype, DatabaseError>.seq(results: listItemPrototypes)
    }

    
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // New

    public func add(listItem: ListItem, section: Section, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: section.realm) {realm -> Bool in
            section.listItems.append(listItem)
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func update(listItem: ListItem, listItemInput: ListItemInput, listItems: RealmSwift.List<ListItem>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        let successMaybe = doInWriteTransactionSync(withoutNotifying: [notificationToken], realm: listItems.realm) {realm -> Bool in
//            listItem.name = input.name
//            listItem.color = input.color
            // TODO!!!!!!!!!!!!!!!!!!!!!!!!!
            return true
        }
        handler(successMaybe ?? false)
    }
    
    public func delete(index: Int, listItems: RealmSwift.List<ListItem>, notificationToken: NotificationToken, _ handler: @escaping (Bool) -> Void) {
        // TODO!!!!!!!!!!!!!!! realm data or remove this method (there's a delete in new part)
//        handler(deleteSync(index: index, listItems: listItems, notificationToken: realmData.notificationToken))
    }
    
    // TODO!!!!!!!!!!!!!!! either remove this or remove listItems paremeter (are in section now)
    func add(quantifiableProduct: QuantifiableProduct, store: String, section: Section, list: List, quantity: Float, status: ListItemStatus, listItems: RealmSwift.List<ListItem>, notificationToken: NotificationToken, _ handler: @escaping ((listItem: ListItem, isNew: Bool)?) -> Void) {
        // TODO!!!!!!!!!!!!!!! realm data or remove this method (there's a delete in new part)
//        if let result = addSync(quantifiableProduct: quantifiableProduct, store: store, list: list, quantity: quantity, status: status, notificationToken: realmData.notificationToken) {
//            handler((result.listItem, result.isNewItem))
//        } else {
//            handler(nil)
//        }
    }
    
    func increment(_ listItem: ListItem, quantity: Float, notificationToken: NotificationToken, realm: Realm, _ handler: @escaping (Float?) -> Void) {
        handler(incrementSync(listItem, quantity: quantity, realmData: RealmData(realm: realm, token: notificationToken)))
    }
    
    // MARK: - Sync
    
    func incrementSync(_ listItem: ListItem, quantity: Float, realmData: RealmData?, doTransaction: Bool = true) -> Float? {
        
        func transactionContent() -> Float {
            listItem.incrementQuantity(quantity)
            return listItem.quantity
        }
        
        if doTransaction {
            return doInWriteTransactionSync(realmData: realmData) {realm -> Float in
                return transactionContent()
            }
        } else {
            return transactionContent()
        }
    }
    
    // TODO maybe remove references to section, list of list items so we don't have to pass them here
    // price: only used when product doesn't exist. price == nil means use default value to initialize price.
    fileprivate func createSync(_ quantifiableProduct: QuantifiableProduct, store: String, price: Float?, section: Section, list: List, quantity: Float, note: String?, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        let storeProduct = DBProv.storeProductProvider.storeProductSync(quantifiableProduct, store: store) ?? StoreProduct.createDefault(quantifiableProduct: quantifiableProduct, store: store, price: price)
        return createSync(storeProduct, section: section, list: list, quantity: quantity, note: note, realmData: realmData, doTransaction: doTransaction)
    }
    
    // TODO maybe remove references to section, list of list items so we don't have to pass them here
    fileprivate func createSync(_ storeProduct: StoreProduct, section: Section, list: List, quantity: Float, note: String?, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        // TODO note? we use separate methods for quick add/form
        let listItem = ListItem(uuid: UUID().uuidString, product: storeProduct, section: section, list: list, note: note, quantity: quantity)
        return createSync(listItem, section: section, realmData: realmData, doTransaction: doTransaction)
    }
    
    fileprivate func createSync(_ listItem: ListItem, section: Section, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        
        func transactionContent(realm: Realm) -> Bool {
            realm.add(listItem, update: true)
            section.listItems.append(listItem)
            return true
        }
        
        let successMaybe: Bool? = {
            if doTransaction {
                return doInWriteTransactionSync(realmData: realmData) {realm -> Bool in
                    return transactionContent(realm: realm)
                }
            } else {
                if let realm = realmData?.realm {
                    return transactionContent(realm: realm)
                } else {
                    QL4("Invalid state: should be executed in existing transaction but didn't pass a realm")
                    return nil
                }
            }
        }()

        return (successMaybe ?? false) ? listItem : nil
    }
    
    /// Quick add / form
    /// price set when used in form
    func addSync(quantifiableProduct: QuantifiableProduct, store: String, price: Float?, list: List, quantity: Float, note: String?, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> (AddListItemResult)? {
        
        refresh()
        
        switch DBProv.sectionProvider.mergeOrCreateSectionSync(quantifiableProduct.product.item.category.name, sectionColor: quantifiableProduct.product.item.category.color, status: status, possibleNewOrder: nil, list: list, realmData: realmData, doTransaction: doTransaction) {
            
        case .ok(let sectionResult):
            
            let section = sectionResult.section
            
            let existingListItemMaybe = section.listItems.filter(ListItem.createFilter(quantifiableProductUnique: quantifiableProduct.unique)).first
            
            if let existingListItem = existingListItemMaybe, let listItemIndex = section.listItems.index(of: existingListItem) {
                let quantityMaybe = incrementSync(existingListItem, quantity: quantity, realmData: realmData, doTransaction: doTransaction)
                if quantityMaybe != nil {
                    
                    return AddListItemResult(listItem: existingListItem, section: section, isNewItem: false, isNewSection: sectionResult.isNew, listItemIndex: listItemIndex, sectionIndex: sectionResult.index)
                    //return (listItem: existingListItem, isNew: false, isNewSection: isNewSection)
                } else {
                    QL4("Couldn't increment existing list item")
                    return nil
                }
                
            } else { // new list item
                
                
                print("list items before create list item: \(section.listItems.count)")
                
                // TODO section, list - see note on create
                if let createdListItem = createSync(quantifiableProduct, store: store, price: price, section: section, list: list, quantity: quantity, note: note, realmData: realmData, doTransaction: doTransaction) {
                    
                    print("list items after create list item: \(section.listItems.count)")
                    
                    
                    return AddListItemResult(listItem: createdListItem, section: section, isNewItem: true, isNewSection: sectionResult.isNew, listItemIndex: section.listItems.count - 1, sectionIndex: sectionResult.index)
                } else {
                    QL4("Couldn't create list item, quantifiableProduct: \(quantifiableProduct)")
                    return nil
                }
            }
         
            case .err(let error):
                QL4("Error: \(error), quantifiableProduct: \(quantifiableProduct.uuid):\(quantifiableProduct.product.item.name)")
                return nil
        }
    }
    
    
    /// Input form
    func addSync(listItemInput: ListItemInput, list: List, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> AddListItemResult? {

        switch DBProv.productProvider.mergeOrCreateQuantifiableProductSync(prototype: listItemInput.toProductPrototype(), updateCategory: true, save: false, realmData: realmData, doTransaction: doTransaction) {
            
        case .ok(let quantifiableProduct):
            return addSync(quantifiableProduct: quantifiableProduct, store: list.store ?? "", price: listItemInput.storeProductInput.price, list: list, quantity: listItemInput.quantity, note: listItemInput.note, status: status, realmData: realmData, doTransaction: doTransaction)

        case .err(let error):
            QL4("Couldn't add/update quantifiable product: \(error)")
            return nil
        }
    }
    
    /// Input form / recipes
    func addSync(listItemInputs: [ListItemInput], list: List, status: ListItemStatus, realmData: RealmData?, doTransaction: Bool = true) -> [(listItem: ListItem, isNew: Bool)]? {
        
        //guard let listItemsRealm = listItems.realm else {QL4("List items have no realm"); return nil}
        
        var addedListItems = [(listItem: ListItem, isNew: Bool)]()
        
        doInWriteTransactionSync(withoutNotifying: realmData.map{[$0.token]} ?? [], realm: nil) {realm in
            
            for listItemInput in listItemInputs {
                if let result = addSync(listItemInput: listItemInput, list: list, status: status, realmData: realmData, doTransaction: false) {
                    addedListItems.append((result.listItem, result.isNewItem))
                } else {
                    QL4("Couldn't add list item for input: \(listItemInput), list: \(list.uuid)::\(list.name), status: \(status). Skipping") // we could also break instead of skip but why not skip
                }
            }
        }

        return addedListItems
    }

    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Cart
    
    /// Quick add
    func addToCartSync(quantifiableProduct: QuantifiableProduct, store: String, list: List, quantity: Float, realmData: RealmData?, doTransaction: Bool = true) -> (AddCartListItemResult)? {

        switch DBProv.sectionProvider.mergeOrCreateSectionSync(quantifiableProduct.product.item.category.name, sectionColor: quantifiableProduct.product.item.category.color, possibleNewOrder: nil, list: list, realmData: realmData) {
            
        case .ok(let sectionResult):
            
            let section = sectionResult.section
            
            let existingListItemMaybe = list.doneListItems.filter(ListItem.createFilter(quantifiableProductUnique: quantifiableProduct.unique)).first
            
            if let existingListItem = existingListItemMaybe, let listItemIndex = list.doneListItems.index(of: existingListItem) {
                let quantityMaybe = incrementSync(existingListItem, quantity: quantity, realmData: realmData, doTransaction: doTransaction)
                if quantityMaybe != nil {
                    
                    return AddCartListItemResult(listItem: existingListItem, section: section, isNewItem: false, isNewSection: sectionResult.isNew, listItemIndex: listItemIndex)
                    //return (listItem: existingListItem, isNew: false, isNewSection: isNewSection)
                } else {
                    QL4("Couldn't increment existing list item")
                    return nil
                }
                
            } else { // new list item
                
                
                print("list items before create list item: \(section.listItems.count)")
                
                // TODO section, list - see note on create
                if let createdListItem = createCartSync(quantifiableProduct, store: store, price: nil, section: section, list: list, quantity: quantity, realmData: realmData, doTransaction: doTransaction) {
                    
                    print("list items after create list item: \(section.listItems.count)")
                    
                    
                    // WARNING: quick impl: listItemIndex 0 assumes createCartSync inserts item at 0
                    return AddCartListItemResult(listItem: createdListItem, section: section, isNewItem: true, isNewSection: sectionResult.isNew, listItemIndex: 0)
                } else {
                    QL4("Couldn't create list item, quantifiableProduct: \(quantifiableProduct)")
                    return nil
                }
            }
            
        case .err(let error):
            QL4("Error: \(error), quantifiableProduct: \(quantifiableProduct.uuid):\(quantifiableProduct.product.item.name)")
            return nil
        }
    }
    
    
    // TODO maybe remove references to section, list of list items so we don't have to pass them here
    // price: only used when product doesn't exist. price == nil means use default value to initialize price.
    fileprivate func createCartSync(_ quantifiableProduct: QuantifiableProduct, store: String, price: Float?, section: Section, list: List, quantity: Float, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        let storeProduct = DBProv.storeProductProvider.storeProductSync(quantifiableProduct, store: store) ?? StoreProduct.createDefault(quantifiableProduct: quantifiableProduct, store: store, price: price)
        return createCartSync(storeProduct, section: section, list: list, quantity: quantity, realmData: realmData, doTransaction: doTransaction)
    }
    
    fileprivate func createCartSync(_ storeProduct: StoreProduct, section: Section, list: List, quantity: Float, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        // TODO note? we use separate methods for quick add/form
        let listItem = ListItem(uuid: UUID().uuidString, product: storeProduct, section: section, list: list, note: nil, quantity: quantity)
        return createCartSync(listItem, list: list, realmData: realmData, doTransaction: doTransaction)
    }
    
    fileprivate func createCartSync(_ listItem: ListItem, list: List, realmData: RealmData?, doTransaction: Bool = true) -> ListItem? {
        
        func transactionContent(realm: Realm) -> Bool {
            realm.add(listItem, update: true)
            list.doneListItems.insert(listItem, at: 0) // in cart we pre-pend
            return true
        }
        
        let successMaybe: Bool? = {
            if doTransaction {
                return doInWriteTransactionSync(realmData: realmData) {realm -> Bool in
                    return transactionContent(realm: realm)
                }
            } else {
                if let realm = realmData?.realm {
                    return transactionContent(realm: realm)
                } else {
                    QL4("Invalid state: should be executed in existing transaction but didn't pass a realm")
                    return nil
                }
            }
        }()
        
        return (successMaybe ?? false) ? listItem : nil
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    
    
    /// Internal (switch)
    // TODO!!!!!!!!! do we need to pass Realm around everywhere so notificationToken works?
    /// used in switch status, where we already have a list item and just want to move it to a different status (todo/done/stash). Parameter listItems -> dst list items TODO rename
    // NOTE: section --> target section
    func addSync(listItem: ListItem, section: Section, list: List, quantity: Float, realmData: RealmData, doTransaction: Bool = true) -> (listItem: ListItem, isNew: Bool)? {
        
//        guard let listItemsRealm = section.listItems.realm else {QL4("List items have no realm"); return nil}
        
        let existingListItemMaybe = section.listItems.filter(ListItem.createFilter(quantifiableProductUnique: listItem.product.product.unique)).first // we should be able to use the uuid of the store product or quantifiable product too, but let's for now stick to the semantic unique for consistency and since it's the easiest to reason about. (TODO review this)
        
        if let existingListItem = existingListItemMaybe {
            let quantityMaybe = incrementSync(existingListItem, quantity: quantity, realmData: realmData, doTransaction: doTransaction)
            if quantityMaybe != nil {
                return (listItem: existingListItem, isNew: false)
            } else {
                QL4("Couldn't increment existing list item")
                return nil
            }
            
        } else {
            let createdListItem = createSync(listItem, section: section, realmData: realmData, doTransaction: doTransaction)
            return createdListItem.map{(listItem: $0, isNew: true)}
        }
    }
    
    // TODO maybe remove references to section, list of list items so we don't have to pass them here
    fileprivate func create(_ storeProduct: StoreProduct, section: Section, list: List, quantity: Float, note: String?, realmData: RealmData, _ handler: @escaping (ListItem?) -> Void) {
        handler(createSync(storeProduct, section: section, list: list, quantity: quantity, note: note, realmData: realmData))
    }
    
    func update(_ listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, realmData: RealmData) -> ProvResult<UpdateListItemResult, DatabaseError> {
        
        func doInTransaction() ->  ProvResult<UpdateListItemResult, DatabaseError> {
            
            let foundAndDeletedListItem = DBProv.listItemProvider.deletePossibleListItemWithUniqueSync(listItemInput.name, productBrand: listItemInput.brand, notUuid: updatingListItem.uuid, list: list, realmData: realmData, doTransaction: false)
            
            // update or create section
            let sectionResult = DBProv.sectionProvider.mergeOrCreateSectionSync(listItemInput.section, sectionColor: listItemInput.sectionColor, possibleNewOrder: nil, list: list, realmData: realmData, doTransaction: false)
            
            var changedSection = false
            
            sectionResult.onOk {res in
                // If the item was assigned a new section
                if !res.section.same(updatingListItem.section) {
                    
                    // 1. Move list item to new section
                    _ = updatingListItem.section.listItems.remove(updatingListItem)
                    res.section.listItems.append(updatingListItem)
                    
                    if status == .todo { // There's no List<Section> for status other than .todo
                        // 2. If section is new, add it to list. We check also if the list contains it (it may be that section is old but not in list, at least in current status -- TODO review this, theoretically when the section is not anymore in list+status it should be removed. This is "just in case".
                        if res.isNew || !list.sections(status: status).contains(res.section) {
                            list.sections(status: status).append(res.section)
                        }
                    }
                    
                    // 3. Delete old section if empty
                    if updatingListItem.section.listItems.isEmpty {
                        realmData.realm.delete(updatingListItem.section)
                    }
                    
                    changedSection = true
                }
            }
            
            // update or create quantifiable product and dependencies
            let productResult = DBProv.productProvider.mergeOrCreateQuantifiableProductSync(prototype: listItemInput.toProductPrototype(), updateCategory: true, save: false, realmData: realmData, doTransaction: false)
            
            func onHasSectionAndProduct(sectionResult: AddSectionPlainResult, product: QuantifiableProduct) -> UpdateListItemResult {
                
                // update list item
                updatingListItem.product.price = listItemInput.storeProductInput.price
                updatingListItem.product.product = product
                updatingListItem.section = sectionResult.section
                updatingListItem.note = listItemInput.note ?? ""
                updatingListItem.quantity = listItemInput.quantity
                
                return UpdateListItemResult(listItem: updatingListItem, replaced: foundAndDeletedListItem, changedSection: changedSection)
            }
            
            let joinResult = sectionResult.join(result: productResult).map{sectionResult, product in
                onHasSectionAndProduct(sectionResult: sectionResult, product: product)
            }
            
            return joinResult
        }
        
        return doInWriteTransactionSync(realmData: realmData) {realm in
            return doInTransaction()
        } ?? .err(.unknown)
    }

    public func deleteSync(indexPath: IndexPath, status: ListItemStatus, list: List, realmData: RealmData) -> DeleteListItemResult? {
        let sections = list.sections(status: status)
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realmData.realm) {realm -> DeleteListItemResult? in
            
            let section = sections[indexPath.section]
            section.listItems.remove(objectAtIndex: indexPath.row)
            
            if self.deleteSectionIfEmpty(sections: list.sections(status: status), section: section) {
                return DeleteListItemResult(deletedSection: true)
            } else {
                return DeleteListItemResult(deletedSection: false)
            }
        }
    }
    
    /// Returns if section was empty and removed. Note both section not empty and error removing return false.
    /// NOTE: Has to be executed in a write transaction
    fileprivate func deleteSectionIfEmpty(sections: RealmSwift.List<Section>, section: Section) -> Bool {
        if section.listItems.isEmpty {
            if let sectionIndex = sections.index(of: section) {
                sections.remove(objectAtIndex: sectionIndex)
                return true
            } else {
                QL4("Invalid state: Src section isn't in the list: srcSection: \(section), sections: \(sections)")
                return false
            }
        } else {
            return false
        }
    }
    
    public func move(from: IndexPath, to: IndexPath, status: ListItemStatus, list: List, realmData: RealmData) -> MoveListItemResult? {

        let srcSection = list.sections(status: status)[from.section]
        let dstSection = list.sections(status: status)[to.section]
        
        let listItem = srcSection.listItems[from.row]
        
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realmData.realm) {realm -> MoveListItemResult? in

            // delete from src section
            srcSection.listItems.remove(objectAtIndex: from.row)
            
            dstSection.listItems.insert(listItem, at: to.row)
            
            if srcSection != dstSection {
                listItem.section = dstSection
            }

            if srcSection.listItems.isEmpty {
                if let sectionIndex = list.sections(status: status).index(of: srcSection) {
                    list.sections(status: status).remove(objectAtIndex: sectionIndex)
                    return MoveListItemResult(deletedSrcSection: true)
                } else {
                    QL4("Invalid state: Src section isn't in the list: srcSection: \(srcSection), status: \(status), list: \(list)")
                    return nil
                }
            }
            
            return MoveListItemResult(deletedSrcSection: false)
        }
    }
    
    
    public func calculateCartStashAggregate(listUuid: String) -> ListItemsCartStashAggregate? {
        
        guard let list = DBProv.listProvider.loadListSync(listUuid) else {
            QL4("couldn't load list with uuid: \(listUuid)")
            return nil
        }
        let (totalCartQuantity, totalCartPrice) = list.doneListItems.reduce((0, Float(0))) {sum, listItem in
            (sum.0 + listItem.quantity, sum.1 + listItem.totalPrice())
        }
        
        let totalStashQuantity = list.stashListItems.reduce(0) {sum, listItem in
            sum + listItem.quantity
        }
        
        
        let totalTodoPrice = list.todoSections.reduce(0) {sum, section in
            return sum + section.listItems.reduce(0) {sectionSum, listItem in
                sectionSum + listItem.totalPrice()
            }
        }
        
        return ListItemsCartStashAggregate(cartQuantity: totalCartQuantity, cartPrice: totalCartPrice, stashQuantity: totalStashQuantity, todoPrice: totalTodoPrice)
    }
    
    // MARK: - Buy

    func buyCart(list: List, realmData: RealmData) -> Bool {
        
        let inventory = list.inventory
        
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realmData.realm) {realm -> Bool? in
            
            // NOTE: maybe we can pass a block to add the inventory item for each list item to switchCartOrStashToTodoSync instead of iterating through the list items again
            
            let productWithQuantityInputs = list.doneListItems.toArray().map{ProductWithQuantityInput(product: $0.product, quantity: $0.quantity)}
            _ = DBProv.inventoryItemProvider.addOrIncrementInventoryItemsWithProductSync(realm, itemInputs: productWithQuantityInputs, inventory: inventory, dirty: true)

            // For now we move items back to the todo list - stash ("backstore") may be too complicated to grasp for users at least for the first releases, especially with the current design.
            return self.switchCartOrStashToTodoSync(cartOrStashListItems: list.doneListItems, list: list, realmData: realmData, doTransaction: false)
            
        } ?? false
    }
    
    
    // MARK: - Switch
    
    func switchTodoToCartSync(listItem: ListItem, from: IndexPath, realmData: RealmData) -> SwitchListItemResult? {
        
        guard let realm = listItem.section.realm else {QL4("No realm"); return nil}
        
        let list = listItem.list // TODO!!!!!!!!! do we still want to keep references to list and sections in list item? does this work correctly?
        
        let srcSection = listItem.section

        
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realm) {(realm) -> SwitchListItemResult? in
      
            list.doneListItems.insert(listItem, at: 0)
            
            // delete from src section
            srcSection.listItems.remove(objectAtIndex: from.row)
            
            if self.deleteSectionIfEmpty(sections: list.todoSections, section: srcSection) {
                return SwitchListItemResult(deletedSection: true)
            } else {
                return SwitchListItemResult(deletedSection: false)
            }
        }
    }

    // TODO!!!!!!!!!!!!!!!!!!! remove this, duplicate, only needed in buy
    func switchCartToStashSync(listItems: [ListItem], list: List, realmData: RealmData) -> Bool {
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realmData.realm) {realm -> Bool? in
            for listItem in listItems {
                list.stashListItems.append(listItem)
            }
            list.doneListItems.removeAll()
            return true
            
        } ?? false
    }

    func switchStashToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData) -> Bool {
        let list = listItem.list // TODO!!!!!!!!! do we still want to keep references to list and sections in list item? does this work correctly?
        
        return switchCartOrStashToTodoSync(listItem: listItem, from: from, cartOrStashListItems: list.stashListItems, realmData: realmData)
    }

    func switchCartToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData) -> Bool {
        let list = listItem.list // TODO!!!!!!!!! do we still want to keep references to list and sections in list item? does this work correctly?
        
        return switchCartOrStashToTodoSync(listItem: listItem, from: from, cartOrStashListItems: list.doneListItems, realmData: realmData)
    }

    
    // TODO do we need list item parameter or is "from" enough
    func switchSync(listItem: ListItem, from: IndexPath, srcStatus: ListItemStatus, dstStatus: ListItemStatus, realmData: RealmData) -> SwitchListItemResult? {
        
        guard let realm = listItem.section.realm else {QL4("No realm"); return nil}
        
        let list = listItem.list // TODO!!!!!!!!! do we still want to keep references to list and sections in list item? does this work correctly?
        
        let srcSection = listItem.section
        
        guard let dstSection = DBProv.sectionProvider.getOrCreate(name: listItem.section.name, color: listItem.section.color, list: list, status: dstStatus, notificationToken: realmData.token, realm: realm) else {QL4("Invalid state - couldn't get or create section"); return nil}
        
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realm) {(realm) -> SwitchListItemResult? in
            
            // append/increment in dst section
            if self.addSync(listItem: listItem, section: dstSection, list: list, quantity: listItem.quantity, realmData: realmData, doTransaction: false) == nil {
                QL4("Add sync returned nil, exit")
                return nil // interrupt transaction
            }
            
            // delete from src section
            srcSection.listItems.remove(objectAtIndex: from.row)
            
            if self.deleteSectionIfEmpty(sections: list.sections(status: srcStatus), section: srcSection) {
                return SwitchListItemResult(deletedSection: true)
            } else {
                return SwitchListItemResult(deletedSection: false)
            }
        }
    }
    
    fileprivate func switchCartOrStashToTodoSync(cartOrStashListItems: RealmSwift.List<ListItem>, list: List, realmData: RealmData, doTransaction: Bool) -> Bool {
        
        func transactionContent() -> Bool {
            
            for listItem in cartOrStashListItems {
                
                guard let dstSection = DBProv.sectionProvider.getOrCreate(name: listItem.section.name, color: listItem.section.color, list: list, status: .todo, notificationToken: realmData.token, realm: realmData.realm, doTransaction: false) else {QL4("Invalid state - couldn't get or create section"); return false}
                
                // append/increment in dst section
                if self.addSync(listItem: listItem, section: dstSection, list: list, quantity: listItem.quantity, realmData: realmData, doTransaction: false) == nil {
                    QL4("Add sync returned nil, exit")
                    return false // interrupt transaction
                }
                
                
                // delete from src list items
                cartOrStashListItems.remove(objectAtIndex: 0)
            }
            return true
        }
        
        let success: Bool = {
           
            if doTransaction {
                return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realmData.realm) {realm -> Bool? in
                    return transactionContent()
                } ?? false
                
            } else {
                return transactionContent()
            }
            
        }()
       
        return success
    }
    
    fileprivate func switchCartOrStashToTodoSync(listItem: ListItem, from: IndexPath, cartOrStashListItems: RealmSwift.List<ListItem>, realmData: RealmData) -> Bool {
        guard let realm = listItem.section.realm else {QL4("No realm"); return false}
        
        let list = listItem.list // TODO!!!!!!!!! do we still want to keep references to list and sections in list item? does this work correctly?
        
        guard let dstSection = DBProv.sectionProvider.getOrCreate(name: listItem.section.name, color: listItem.section.color, list: list, status: .todo, notificationToken: realmData.token, realm: realm) else {QL4("Invalid state - couldn't get or create section"); return false}
        
        return doInWriteTransactionSync(withoutNotifying: [realmData.token], realm: realm) {realm -> Bool? in
            
            // append/increment in dst section
            if self.addSync(listItem: listItem, section: dstSection, list: list, quantity: listItem.quantity, realmData: realmData, doTransaction: false) == nil {
                QL4("Add sync returned nil, exit")
                return nil // interrupt transaction
            }
            
            // delete from src list items
            cartOrStashListItems.remove(objectAtIndex: from.row)
            
            return true
            
        } ?? false
    }
}
