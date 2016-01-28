//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class ListItemProviderImpl: ListItemProvider {

    let dbProvider = RealmListItemProvider()
    let remoteProvider = RemoteListItemProvider()
    let memProvider = MemListItemProvider(enabled: true)

    func listItems(list: List, fetchMode: ProviderFetchModus = .Both, _ handler: ProviderResult<[ListItem]> -> ()) {

        let memListItemsMaybe = memProvider.listItems(list)
        if let memListItems = memListItemsMaybe {
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: memListItems))
            if fetchMode == .MemOnly || fetchMode == .First {
                return
            }
        }

        self.dbProvider.loadListItems(list, handler: {[weak self] (var dbListItems) in

            // reorder items by position
            // TODO ? a possible optimization is to save the list to local db sorted instead of having order field, see http://stackoverflow.com/questions/25023826/reordering-realm-io-data-in-tableview-with-swift
            // the server still needs (internally at least) the order column
            // TODO another optimization is to do the server items sorting in the server
            
            dbListItems = dbListItems.sortedByOrder() // order is relative to section (0...n) so there will be repeated numbers.
            
            // we assume the database result is always == mem result, so if returned from mem already no need to return from db
            // TODO there's no need to load the items from db before doing the remote call (confirm this), since we assume memory == database it would be enough to compare 
            // the server result with memory. Load from db only when there's no memory cache.
            if !memListItemsMaybe.isSet {
                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbListItems))
            }
            
            self?.memProvider.overwrite(dbListItems)
            
            self?.remoteProvider.listItems(list: list) {[weak self] remoteResult in
                
                if let remoteListItems = remoteResult.successResult {
                    let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems)
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (dbListItems != listItemsWithRelations.listItems) { // note: listItemsWithRelations.listItems is already sorted by order
                        // TODO this should OVERWRITE the items not just "save"
                        self?.dbProvider.saveListItems(listItemsWithRelations) {saved in
                            
                            if fetchMode == .Both || fetchMode == .First {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: listItemsWithRelations.listItems))
                            }
                            self?.memProvider.overwrite(listItemsWithRelations.listItems)
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                }
            }
        })
    }
    
    func remove(listItem: ListItem, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        let memUpdated = memProvider.removeListItem(listItem)
        if memUpdated {
            handler(ProviderResult(status: ProviderStatusCode.Success))
        }
        
        self.dbProvider.remove(listItem, handler: {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            if remote {
                self?.remoteProvider.remove(listItem) {result in
                    if !result.success {
                        DefaultRemoteErrorHandler.handle(result, handler: {(result: ProviderResult<[Any]>) in
                            print("Error: Removing listItem: \(listItem)")
                        })
                    }
                }
            }
        })
    }

    
    func remove(list: List, _ handler: ProviderResult<Any> -> ()) {
        memProvider.invalidate()
        self.dbProvider.remove(list) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }

    func add(groupItems: [GroupItem], list: List, _ handler: ProviderResult<[ListItem]> -> ()) {
        
        listItems(list, fetchMode: .MemOnly) {[weak self] result in // get listitems - we need this to determine the order of the new items
            
            if let currentListItems = result.sucessResult {
                
                // TODO! check if count is really being incremented (maybe tuple immutable?)
                var currentSectionNameToSectionAndContainedListItemsCount = currentListItems.groupBySection().map{($0.name, (section: $0, count: $1.count))}
                
                var listItems: [ListItem] = []
                var sectionCount = currentSectionNameToSectionAndContainedListItemsCount.count // neeeded to set order field in possible new sections
                
                for groupItem in groupItems {
                    // append new listitem at the end of section
                    let count = currentSectionNameToSectionAndContainedListItemsCount[groupItem.product.category.name]?.count ?? 0
                    let order = count // order is the same as index: if no elements -> order 0, if 1 elements -> order 0, 1, etc.
                    currentSectionNameToSectionAndContainedListItemsCount[groupItem.product.category.name]?.count = count + 1 // we inserted an item, increment (or insert, if section doesn't exist yet) count
                    
                    // create a section if there's is no section in the list yet with same name as category
                    let section: Section = {
                        currentSectionNameToSectionAndContainedListItemsCount[groupItem.product.category.name]?.section ?? {

                            // we are appending a new section to the existing sections in the list, increment section count so next new section has correct order
                            sectionCount++
                            
                            // section order -> append at the end -> section count (currentSectionNameToSectionAndContainedListItemsCount.count is section count)
                            return Section(uuid: NSUUID().UUIDString, name: groupItem.product.category.name, order: currentSectionNameToSectionAndContainedListItemsCount.count)
                        }()
                    }()
                    
                    // Note: we add always to Todo list - it's not possible and it doesn't make sense to add group items to cart & stash
                    let listItem = ListItem(uuid: NSUUID().UUIDString, product: groupItem.product, section: section, list: list, statusOrder: ListItemStatusOrder(status: .Todo, order: order), statusQuantity: ListItemStatusQuantity(status: .Todo, quantity: groupItem.quantity))
                    listItems.append(listItem)
                }
                
                self?.add(listItems) {result in
                    handler(result)
                }
                
            } else {
                print("Error: Can't add groups: Could not get listitems.")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func add(listItems: [ListItem], remote: Bool = true, _ handler: ProviderResult<[ListItem]> -> ()) {

        let addedListItemsMaybe = memProvider.addListItems(listItems)
        if let addedListItems = addedListItemsMaybe {
            handler(ProviderResult(status: .Success, sucessResult: addedListItems))
        }
        
        // TODO review carefully what happens if adding fails after memory cache is updated
        dbProvider.saveListItems(listItems, incrementQuantity: true) {[weak self] savedListItemsMaybe in // currently the item returned by server is identically to the one we sent, so we just save our local item
            if let savedListItems = savedListItemsMaybe {
                if !addedListItemsMaybe.isSet { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                    handler(ProviderResult(status: .Success, sucessResult: savedListItems))
                }
                
                if remote {
                    // TODO review following comment now that we changed to do first database and then server
                    // for now do remote first. Imagine we do coredata first, user adds the list and then a lot of items to it and server fails. The list with all items will be lost in next sync.
                    // we can do special handling though, like show an error message when server fails and remove the list which was just added, and/or retry server. Or use a flag "synched = false" which tells us that these items should not be removed on sync, similar to items which were added offline. Etc.
                    // TODO review that sending savedListItems is enough for possible update case (increment) to work correctly. Will the server always have correct uuids etc.
                    self?.remoteProvider.add(savedListItems) {remoteResult in
                        
                        if let remoteListItems = remoteResult.successResult {
                            
                            self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
                                if !success {
                                    // TODO! the timestamp is stored in server (remote was success) say "3"
                                    // but it couldn't be saved in the items. Items, have e.g. no timestamp yet or "1"
                                    // this means: when we try to sync the items the next time it will not work as 1 < 3, and they'll be overwritten.
                                    // this overwrite is a loss of data only when after the update we updated more data locally.
                                    // since we don't have currently timestamp check for "little sync" (?), the next time we do a little update the timestamp may work and problem is solved
                                    // so problem is only: possible new local updates (most probably offline) to item are reverted on "big sync".
                                    // how do we handle this? possibilities:
                                    // 1. retry - still need to decide what we do if retry fails
                                    // 2. delete local items 
                                    // 3. update items with a "special mark" that will make item skip timestamp check on server, problem is updates of other users/devices may be overwritten.
                                    // 4. ignore
                                    // more possibilities?
                                    // for now we chose ignore - doesn't look like a super critical issue. Some *possible* updates *may* be reverted, and only if the timestamp update fails which is unlikely so this should almost never happen. And if it happens user just loses some data in big sync, not critical.
                                    // But TODO! we have to send this error message to hockey, it's important to know if it happens.
                                    print("Error: ListItemProviderImpl.add: Error updating last update timestamps")
                                }
                            }
                            
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[ListItem]>) in
                                self?.memProvider.invalidate()
                                print("Error: ListItemProviderImpl.add: adding listItem in remote: \(listItems), result: \(remoteResult)")
                                handler(result)
                            })
                        }
                    }
                }

            } else {
                self?.memProvider.invalidate()
                print("Error: ListItemProviderImpl.add: saving listItem to db: \(listItems)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }

        }
    }
    
    func add(listItem: ListItem, remote: Bool = true, _ handler: ProviderResult<ListItem> -> ()) {
        add([listItem]) {result in
            if let listItems = result.sucessResult {
                if let listItem = listItems.first {
                    handler(ProviderResult(status: .Success, sucessResult: listItem))
                    
                } else {
                    print("Error: add listitem returned success result but it's an empty array. ListItem: \(listItem)")
                    handler(ProviderResult(status: .Unknown))
                }
                
            } else {
                print("Error: add listitem didn't succeed, listItem: \(listItem), result: \(result)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: Int?, _ handler: ProviderResult<ListItem> -> Void) {

        Providers.sectionProvider.mergeOrCreateSection(listItemInput.section, possibleNewOrder: possibleNewSectionOrder, list: list) {[weak self] result in

            if let section = result.sucessResult {
                
                Providers.productProvider.mergeOrCreateProduct(listItemInput.name, productPrice: listItemInput.price, category: listItemInput.category, categoryColor: listItemInput.categoryColor, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand) {result in
            
                    if let product = result.sucessResult {
                    
                        self?.addListItem(product, section: section, quantity: listItemInput.quantity, list: list, note: listItemInput.note, order: orderMaybe, handler)

                    } else {
                        print("Error fetching product: \(result.status)")
                        handler(ProviderResult(status: .DatabaseUnknown))
                    }
                }
            } else {
                print("Error fetching section: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    

    // Adds list item with todo status
    func addListItem(product: Product, sectionName: String, quantity: Int, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        
        typealias BGResult = (success: Bool, listItem: ListItem) // helper to differentiate between nil result (db error) and nil listitem (the item was already returned from memory - don't return anything)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            
            if let weakSelf = self {
                let bgResultMaybe: BGResult? = syncedRet(weakSelf) {
                    do {
                        let memAddedListItemMaybe = weakSelf.memProvider.addOrUpdateListItem(product, sectionNameMaybe: sectionName, status: .Todo, quantity: quantity, list: list, note: note)
                        if let addedListItem = memAddedListItemMaybe {
                            dispatch_async(dispatch_get_main_queue(), {
                                // return in advance so our client is quick - the database update continues in the background
                                handler(ProviderResult(status: .Success, sucessResult: addedListItem))
                            })
                        }
                        
                        return weakSelf.dbProvider.doInWriteTransactionSync({realm in
                            
                            // even if we have the possibly updated item from mem cache, do always a fetch to db and use this item - to guarantee max. consistency.s
                            // theoretically the state in mem should match the state in db so this fetch should not be necessary, but for now let's be secure.
                            
                            // see if there's already a listitem for this product in the list - if yes only increment it
                            if let existingListItem = realm.objects(DBListItem).filter(DBListItem.createFilter(list, product: product)).first {
                                existingListItem.increment(ListItemStatusQuantity(status: .Todo, quantity: quantity))
                                
                                // possible updates (when user submits a new list item using add edit product controller)
                                //                if let sectionName = section.name {
                                existingListItem.section.name = sectionName
                                //                }
                                if let note = note {
                                    existingListItem.note = note
                                }
                                
                                // let incrementedListItem = existingListItem.copy(quantity: existingListItem.quantity + 1)
                                // TODO!! update sectionnaeme, note (for case where this is from add product with inputs)
                                realm.add(existingListItem, update: true)
                                let savedListItem = ListItemMapper.listItemWithDB(existingListItem)
                                
                                return (success: true, listItem: savedListItem)
                                
                            } else { // no list item for product in the list, create a new one
                                
                                // see if there's already a section for the new list item in the list, if not create a new one
                                let listItemsInList = realm.objects(DBListItem).filter(DBListItem.createFilter(list))
                                //                let sectionName = sectionNameMaybe ?? product.category
                                let sectionName = sectionName ?? product.category.name
                                let section = listItemsInList.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                                    return SectionMapper.sectionWithDB(item.section)
                                    } ?? { // section not existent create a new one
                                        let sectionCount = Set(listItemsInList.map{$0.section}).count
                                        
                                        // if we already created a new section in the memory cache use that one otherwise create (create case normally only if memcache is disabled)
                                        return memAddedListItemMaybe?.section ?? Section(uuid: NSUUID().UUIDString, name: sectionName, order: sectionCount)
                                    }()
                                
                                
                                // calculate list item order, which is at the end of it's section (==count of listitems in section). Note that currently we are doing this iteration even if we just created the section, where order is always 0. This if for clarity - can be optimised later (TODO)
                                var listItemOrder = 0
                                for existingListItem in listItemsInList {
                                    if existingListItem.section.uuid == section.uuid {
                                        listItemOrder++
                                    }
                                }
                                
                                // create the list item and save it
                                // memcache uuid: if we created a new listitem in memcache use this uuid so our data is consistent mem/db
                                let listItem = ListItem(
                                    uuid: memAddedListItemMaybe?.uuid ?? NSUUID().UUIDString,
                                    product: product,
                                    section: section,
                                    list: list,
                                    note: note,
                                    statusOrder: ListItemStatusOrder(status: .Todo, order: listItemOrder),
                                    statusQuantity: ListItemStatusQuantity(status: .Todo, quantity: quantity)
                                )
                                
                                let dbListItem = ListItemMapper.dbWithListItem(listItem)
                                realm.add(dbListItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
                                let savedListItem = ListItemMapper.listItemWithDB(dbListItem)
                                
                                return (success: true, listItem: savedListItem)
                            }
                        })
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), {

                    if let bgResult = bgResultMaybe { // bg ran successfully
                        
                        if self?.memProvider.enabled ?? false {
                            // bgResult & mem enabled -> do nothing: added item was returned to handler already (after add to mem provider), no need to return it again
                            
                        } else {
                            // mem provider is not enabled - controller is waiting for result - return it
                            handler(ProviderResult(status: .Success, sucessResult: bgResult.listItem))
                        }
                        
//                        if let addedListItem = bgResult.listItem { // bg returned a list item
//                            handler(ProviderResult(status: .Success, sucessResult: bgResult.addedListItem))
//
//                        
//                        } else {
//                            // bg was successful but didn't return a list item, this happens when the item was returned from the memory cache
//                            // in this case we do nothing - the client already has the added object
//                        }
                        
                        
                        // add to server
                        self?.remoteProvider.add(bgResult.listItem) {remoteResult in
                            if !remoteResult.success {
                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<ListItem>) in
                                    print("Error: adding listItem in remote: \(bgResult.listItem), result: \(remoteResult)")
                                    self?.memProvider.invalidate()
                                    handler(result)
                                })
                            }
                        }
                        
                        
                    } else { // there was a database error
                        handler(ProviderResult(status: .DatabaseUnknown))
                    }
                })
            }
        })
    }

    func addListItem(product: Product, section: Section, quantity: Int, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        // for now call the other func, which will fetch the section again... review if this is bad for performance otherwise let like this
        addListItem(product, sectionName: section.name, quantity: quantity, list: list, note: note, order: orderMaybe, handler)
    }

    func switchStatus(listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        self.listItems(list, fetchMode: .MemOnly) {result in // TODO review .First suitable here

            if let storedListItems = result.sucessResult {
            
                // Update done and order field - by changing "done" we are moving list items from one tableview to another
                // we append the items at the end of the section (order == section.count)
                var sectionsDict = storedListItems.sectionCountDict(status)
                for listItem in listItems {
                    listItem.switchStatusQuantityMutable(status1, targetStatus: status)
                    if let sectionCount = sectionsDict[listItem.section] {
                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: sectionCount))
                        sectionsDict[listItem.section]!++ // we are adding an item to section - increment count for possible next item
                        
                    } else { // item's section is not in target list - set order 0 (first item in section) and add section to the dictionary
                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: 0))
                        sectionsDict[listItem.section] = 1 // we are adding an item to section - items count is 1
                    }
                }
                
                // persist changes
                self.update(listItems, remote: remote, handler)
                
            } else {
                print("Error: didn't get listItems in updateBatchDone: \(result.status)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func update(listItems: [ListItem], remote: Bool = true, _ handler: ProviderResult<Any> -> ()) {
        let memUpdated = memProvider.updateListItems(listItems)
        if memUpdated {
            handler(ProviderResult(status: .Success))
        }

        self.dbProvider.updateListItems(listItems, handler: {[weak self] saved in
            if saved {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            
            if remote {
                self?.remoteProvider.update(listItems) {result in
                    if !result.success {
                        DefaultRemoteErrorHandler.handle(result, handler: {(result: ProviderResult<Any>) in
                            print("Error: Updating listItems: \(listItems), result: \(result)")
                            self?.memProvider.invalidate()
                            handler(result)
                        })
                    }
                }
            }
        })
    }
    
    func update(listItem: ListItem, remote: Bool = true, _ handler: ProviderResult<Any> -> ()) {
        update([listItem], remote: remote, handler)
    }
    
    func increment(listItem: ListItem, delta: Int, _ handler: ProviderResult<Any> -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.increment(listItem, quantity: ListItemStatusQuantity(status: .Todo, quantity: delta))
        if memIncremented {
            handler(ProviderResult(status: .Success))
        }
        
        dbProvider.incrementTodoListItem(listItem, delta: delta) {[weak self] saved in
            
            if !memIncremented { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if saved {
                    handler(ProviderResult(status: .Success))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
            
            //            print("SAVED DB \(item)(+delta) in local db. now going to update remote")
            
            self?.remoteProvider.incrementListItem(listItem, delta: delta) {remoteResult in
                
                if remoteResult.success {
                    
//                    //                    print("SAVED REMOTE will revert delta now in local db for \(item.product.name), with delta: \(-delta)")
//                    
//                    // Now that the item was updated in server, set back delta in local database
//                    // Note we subtract instead of set to 0, to handle possible parallel requests correctly
//                    self?.dbInventoryProvider.incrementInventoryItem(listItem, delta: -delta, onlyDelta: true) {saved in
//                        
//                        if saved {
//                            //                            self?.findInventoryItem(item) {result in
//                            //                                if let newitem = result.sucessResult {
//                            //                                    print("3. CONFIRM incremented item: \(item) + \(delta) == \(newitem)")
//                            //                                }
//                            //                            }
//                            
//                        } else {
//                            print("Error: couln't save remote list item")
//                        }
//                        
//                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                        print("Error incrementing item: \(listItem) in remote, result: \(remoteResult)")
                        // if there's a not connection related server error, invalidate cache
                        self?.memProvider.invalidate()
                        handler(remoteResult)
                    }
                }
            }
        }
    }
    
    func syncListItems(list: List, handler: (ProviderResult<Any>) -> ()) {
        
        memProvider.invalidate()
        
        self.dbProvider.loadListItems(list) {dbListItems in
        
            let (toAddOrUpdate, toRemove) = SyncUtils.toSyncListItems(dbListItems)
            
            self.remoteProvider.syncListItems(list, listItems: toAddOrUpdate, toRemove: toRemove) {remoteResult in
                
                // save first the products, then the sections, then the listitems
                // note that sync will overwrite the listitems but it will not remove products or sections
                // products particularly is a bit complex since they are referenced also by inventory items, so they should be removed only when they are not referenced from anywhere
                // a possible approach to solve this could be regular cleanup operations, this can be serverside or in the client, or both
                // serverside we would do the cleanups (cronjob?), and make client's sync such that *everything* is synced and overwritten, paying attention not to recreate products etc. which were removed in the server by the cronjob. TODO think about this. For now letting some garbage in the client's db is not critical, our app doesn't handle a lot of data generally
                // in the server this is more important, since a little garbage from each client sums up. But for now also ignored.
                
                if let syncResult = remoteResult.successResult, items = syncResult.items.first {
                    // Note: next line: flatMap filters out possible optionals (in normal case no optionals are expected)
                    let products: [Product] = items.products.flatMap{ProductMapper.productWithRemote($0, categoriesDict: items.productsCategoriesDict)}
                    self.dbProvider.saveProducts(products) {productSaved in
                        if productSaved {
                            
                            self.dbProvider.saveSections(items.sections.map{SectionMapper.SectionWithRemote($0)}) {sectionsSaved in
                                if sectionsSaved {
                                    
                                    // for now overwrite all. In the future we should do a timestamp check here also for the case that user does an update while the sync service is being called
                                    // since we support background sync, this should not be neglected
                                    
                                    let listItemsWithRelations = ListItemMapper.listItemsWithRemote(items)
                                    let serverListItems = listItemsWithRelations.listItems.map{ListItemMapper.dbWithListItem($0)}
                                    self.dbProvider.overwrite(serverListItems) {success in
                                        if success {
                                            handler(ProviderResult(status: .Success))
                                        } else {
                                            handler(ProviderResult(status: .DatabaseSavingError))
                                        }
                                        return
                                    }
                                    
                                } else {
                                    print("Error: database: couldn't save section")
                                    handler(ProviderResult(status: .DatabaseSavingError))
                                }
                            }
                        } else {
                            print("Error: database: couldn't save section")
                            handler(ProviderResult(status: .DatabaseSavingError))
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                }
            }
        }
    }
    
    func invalidateMemCache() {
        memProvider.invalidate()
    }
    
//    func firstList(handler: Try<List> -> ()) {
//        
//        func createList(name: String, #handler: Try<List> -> ()) {
//            let list = List(id: NSUUID().UUIDString, name: name)
//            self.add(list, handler: {try in
//                if let savedList = try.success {
//                    PreferencesManager.savePreference(PreferencesManagerKey.listId, value: NSString(string: savedList.id))
//                    handler(Try(savedList))
//                }
//            })
//        }
//
//        if let listId:String = PreferencesManager.loadPreference(PreferencesManagerKey.listId) {
//            self.list(listId, handler: {try in
//                if let list = try.success {
//                    handler(Try(list))
//                }
//
//            })
//            
//        } else {
//            createList(Constants.defaultListIdentifier, handler: {try in
//                if let list = try.success {
//                    handler(Try(list))
//                }
//            })
//        }
//    }
    
    

    
    func listItemCount(status: ListItemStatus, list: List, fetchMode: ProviderFetchModus = .First, _ handler: ProviderResult<Int> -> Void) {
        let countMaybe = memProvider.listItemCount(.Stash, list: list)
        if let count = countMaybe {
            handler(ProviderResult(status: .Success, sucessResult: count))
            if fetchMode == .MemOnly {
                return
            }
        }
        
        dbProvider.listItemCount(status, list: list) {dbCountMaybe in
            if let dbCount = dbCountMaybe {
                // if for some reason the count in db is different than in memory return it again so the interface can update
                // (only used for fetchmode .Both)
                if (countMaybe.map{$0 != dbCount} ?? true) {
                    handler(ProviderResult(status: .Success, sucessResult: dbCount))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
}