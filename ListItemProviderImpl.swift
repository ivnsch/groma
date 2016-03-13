//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

class ListItemProviderImpl: ListItemProvider {

    let dbProvider = RealmListItemProvider()
    let remoteProvider = RemoteListItemProvider()
    let memProvider = MemListItemProvider(enabled: true)

    func listItems(list: List, sortOrderByStatus: ListItemStatus, fetchMode: ProviderFetchModus = .Both, _ handler: ProviderResult<[ListItem]> -> ()) {

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
    
            dbListItems = dbListItems.sortedByOrder(sortOrderByStatus) // order is relative to section (0...n) so there will be repeated numbers.
            
            // we assume the database result is always == mem result, so if returned from mem already no need to return from db
            // TODO there's no need to load the items from db before doing the remote call (confirm this), since we assume memory == database it would be enough to compare 
            // the server result with memory. Load from db only when there's no memory cache.
            if !memListItemsMaybe.isSet {
                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbListItems))
            }
            
            self?.memProvider.overwrite(dbListItems)
            
            self?.remoteProvider.listItems(list: list) {[weak self] remoteResult in
                
                if let remoteListItems = remoteResult.successResult {
                    let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems, sortOrderByStatus: sortOrderByStatus)
                    
                    if (dbListItems != listItemsWithRelations.listItems) { // note: listItemsWithRelations.listItems is already sorted by order
                        self?.dbProvider.overwrite(listItemsWithRelations.listItems, listUuid: list.uuid, clearTombstones: true) {saved in
                            
                            if dbListItems.isEmpty // this is quick fix to - generally we want to avoid to reset the memory cache or return items to the handler once the list is loaded the first time (after opening), because switch to "done" and "stash" is very quick and it has to be consitent - things should not get lost. User will see background update result the next time the list is opened. But: The very first time user starts app on a device there may be items in the server already and in this case we want the bg update to be handled immediately - because of this we have this empty check. TODO review this it's not very clean.
                                || (fetchMode == .Both || fetchMode == .First) {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: listItemsWithRelations.listItems))
                                self?.memProvider.overwrite(listItemsWithRelations.listItems)
                            }
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
        
        self.dbProvider.remove(listItem, markForSync: true, handler: {[weak self] removed in
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
                    if result.success {
                        self?.dbProvider.clearListItemTombstone(listItem.uuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for: \(listItem)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(result, handler: {(result: ProviderResult<[Any]>) in
                            print("Error: Removing listItem: \(listItem)")
                        })
                    }
                }
            }
        })
    }

    
    func remove(list: List, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        remove(list.uuid, remote: remote, handler)
    }
    
    func remove(listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        memProvider.invalidate()
        self.dbProvider.remove(listUuid, markForSync: true) {[weak self] removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
            
            if remote {
                if removed {
                    self?.remoteProvider.remove(listUuid) {remoteResult in
                        if remoteResult.success {
                            self?.dbProvider.clearListTombstone(listUuid) {removeTombstoneSuccess in
                                if !removeTombstoneSuccess {
                                    QL4("Couldn't delete tombstone for list: \(listUuid)")
                                }
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[Any]>) in
                                QL4(remoteResult)
                            })
                        }
                    }
                }
            }
        }
    }
    
    func add(groupItems: [GroupItem], list: List, _ handler: ProviderResult<[ListItem]> -> ()) {
        let listItemPrototypes: [ListItemPrototype] = groupItems.map{ListItemPrototype(product: $0.product, quantity: $0.quantity, targetSectionName: $0.product.category.name)}
        self.add(listItemPrototypes, list: list, handler)
    }
    
    func addGroupItems(group: ListItemGroup, list: List, _ handler: ProviderResult<[ListItem]> -> ()) {
        Providers.listItemGroupsProvider.groupItems(group) {[weak self] result in
            if let groupItems = result.sucessResult {
                self?.add(groupItems, list: list, handler)
            } else {
                print("Error: ListItemProviderImpl.addGroupItems: Can't get group items for group: \(group)")
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
    
    // Note: status assumed to be .Todo as we can add list item input only to .Todo
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: ListItemStatusOrder?, _ handler: ProviderResult<ListItem> -> Void) {

        Providers.sectionProvider.mergeOrCreateSection(listItemInput.section, status: .Todo, possibleNewOrder: possibleNewSectionOrder, list: list) {[weak self] result in

            if let section = result.sucessResult {
                
                Providers.productProvider.mergeOrCreateProduct(listItemInput.name, productPrice: listItemInput.price, category: listItemInput.category, categoryColor: listItemInput.categoryColor, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand, store: listItemInput.store) {result in
            
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
        let listItemPrototype = ListItemPrototype(product: product, quantity: quantity, targetSectionName: sectionName)
        self.add(listItemPrototype, list: list, handler)
    }
    
    private func addSync(prototype: ListItemPrototype) {
    
    }
    
    func add(prototype: ListItemPrototype, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        
        add([prototype], list: list, note: note, order: orderMaybe) {result in
            if let addedListItems = result.sucessResult {
                
                if let addedListItem = addedListItems.first {
                    handler(ProviderResult(status: .Success, sucessResult: addedListItem))
                } else {
                    print("Error: ListItemProviderImpl.add:prototype: Invalid state: add returned success result but it's empty. Status (should be success): \(result.status)")
                    handler(ProviderResult(status: .Unknown))
                }
            } else {
                print("Error: ListItemProviderImpl.add:prototype: Add didn't return success result, status: \(result.status)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    // Adds list items to .Todo
    func add(prototypes: [ListItemPrototype], list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<[ListItem]> -> Void) {
        
        QL1("add prototypes: \(prototypes)")
        
        func getOrderForNewSection(existingListItems: Results<DBListItem>) -> Int {
            let sectionsOfItemsWithStatus: [DBSection] = existingListItems.collect({
                if $0.hasStatus(.Todo) {
                    return $0.section
                } else {
                    return nil
                }
            })
            return sectionsOfItemsWithStatus.distinctUsingEquatable().count
        }
        
        typealias BGResult = (success: Bool, listItems: [ListItem]) // helper to differentiate between nil result (db error) and nil listitem (the item was already returned from memory - don't return anything)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            
            if let weakSelf = self {
                let bgResultMaybe: BGResult? = syncedRet(weakSelf) {
                    do {
                        let memAddedListItemsMaybe = weakSelf.memProvider.addOrUpdateListItems(prototypes, status: .Todo, list: list, note: note)
                        if let addedListItems = memAddedListItemsMaybe {
                            dispatch_async(dispatch_get_main_queue(), {
                                // return in advance so our client is quick - the database update continues in the background
                                handler(ProviderResult(status: .Success, sucessResult: addedListItems))
                            })
                        }
                        
                        return weakSelf.dbProvider.doInWriteTransactionSync({realm in
                            
                            // even if we have the possibly updated item from mem cache, do always a fetch to db and use this item - to guarantee max. consistency.s
                            // theoretically the state in mem should match the state in db so this fetch should not be necessary, but for now let's be secure.
                            
                            // see if there's already a listitem for this product in the list - if yes only increment it
                            
                            let existingListItems = realm.objects(DBListItem).filter(DBListItem.createFilterList(list.uuid))
                            let existingListItemsDict: [String: DBListItem] = existingListItems.toDictionary{(DBProduct.nameBrandKey($0.product.name, brand: $0.product.brand), $0)}
                            
                            // Quick access for mem cache items - for some things we need to check if list items were added in the mem cache
                            let memoryCacheItemsDict: [String: ListItem]? = memAddedListItemsMaybe?.toDictionary{(DBProduct.nameBrandKey($0.product.name, brand: $0.product.brand), $0)}
                            
                            // Holds count of new items per section, which is incremented while we loop through prototypes
                            // we need this to determine the order of the items in the sections - which is the last index in existing items + new items count so far in section
                            var sectionCountNewItemsDict: [String: Int] = [:]
                            
                            var savedListItems: [ListItem] = []
                            
                            let dbList = ListMapper.dbWithList(list)
                            
                            for prototype in prototypes {
                                if var existingListItem = existingListItemsDict[DBProduct.nameBrandKey(prototype.product.name, brand: prototype.product.brand)] {
                                    
                                    existingListItem.increment(ListItemStatusQuantity(status: .Todo, quantity: prototype.quantity))
                                    
                                    // load section with given name or create a new one if it doesn't exist
                                    let section: DBSection = {
                                        realm.objects(DBSection).filter(DBSection.createFilter(prototype.targetSectionName, listUuid: list.uuid)).first ?? {
                                            let sectionOrder = orderMaybe ?? getOrderForNewSection(existingListItems)
                                            return DBSection(uuid: NSUUID().UUIDString, name: prototype.targetSectionName, list: dbList, todoOrder: sectionOrder, doneOrder: 0, stashOrder: 0)
                                        }()
                                    }()

                                    // for some reason it crashes in this line (yes here not when saving) with reason: 'Can't set primary key property 'uuid' to existing value '03F949BB-AE2A-427A-B49B-D53FA290977D'.' (this is the uuid of the list), no idea why, so doing a copy.
//                                    existingListItem.section = section
                                    existingListItem = existingListItem.copy(section: section)
                                    
                                    if let note = note {
                                        existingListItem.note = note
                                    }
                                    
                                    // let incrementedListItem = existingListItem.copy(quantity: existingListItem.quantity + 1)
                                    realm.add(existingListItem, update: true)
                                    
                                    let savedListItem = ListItemMapper.listItemWithDB(existingListItem)
                                    
                                    QL1("item exists, affter incrementent: \(savedListItem)")

                                    savedListItems.append(savedListItem)
                                    
                                    
                                } else { // item doesn't exist
                                    
//                                    // see if there's already a section for the new list item in the list, if not create a new one
//                                    let listItemsInList = realm.objects(DBListItem).filter(DBListItem.createFilter(list))
                                    let sectionName = prototype.targetSectionName
                                    let section = existingListItems.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                                        return SectionMapper.sectionWithDB(item.section)
                                        } ?? { // section not existent create a new one
                                            
                                            let sectionCount = getOrderForNewSection(existingListItems)
                                            
                                            // if we already created a new section in the memory cache use that one otherwise create (create case normally only if memcache is disabled)
                                            return memoryCacheItemsDict?[DBProduct.nameBrandKey(prototype.product.name, brand: prototype.product.brand)]?.section ?? Section(uuid: NSUUID().UUIDString, name: sectionName, list: list, order: ListItemStatusOrder(status: .Todo, order: sectionCount))
                                        }()
                                    
                                    // determine list item order and init/update the map with list items count / section as side effect (which is used to determine the order of the next item)
                                    let listItemOrder: Int = {
                                        if let sectionCount = sectionCountNewItemsDict[section.uuid] { // if already initialised (existing items count) increment 1 (for new item we are adding)
                                            let order = sectionCount + 1
                                            sectionCountNewItemsDict[section.uuid] = order
                                            return order
                                            
                                        } else { // init to existing count
                                            var existingCountInSection = 0
                                            // Note that currently we are doing this iteration even if we just created the section, where order is always 0. Not a big issue in our case but can be optimised (TODO?)
                                            for existingListItem in existingListItems {
                                                if existingListItem.section.uuid == section.uuid && existingListItem.hasStatus(.Todo) {
                                                    existingCountInSection++
                                                }
                                            }
                                            sectionCountNewItemsDict[section.uuid] = existingCountInSection
                                            return existingCountInSection
                                        }
                                    }()
                                    
                                    let uuid = memoryCacheItemsDict?[DBProduct.nameBrandKey(prototype.product.name, brand: prototype.product.brand)]?.uuid ?? NSUUID().UUIDString
                                    
                                    // create the list item and save it
                                    // memcache uuid: if we created a new listitem in memcache use this uuid so our data is consistent mem/db
                                    let listItem = ListItem(
                                        uuid: uuid,
                                        product: prototype.product,
                                        section: section,
                                        list: list,
                                        note: note,
                                        statusOrder: ListItemStatusOrder(status: .Todo, order: listItemOrder),
                                        statusQuantity: ListItemStatusQuantity(status: .Todo, quantity: prototype.quantity)
                                    )

                                    QL1("item doesn't exist, created: \(listItem)")
                                    
                                    let dbListItem = ListItemMapper.dbWithListItem(listItem)
                                    realm.add(dbListItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
                                    
                                    let savedListItem = ListItemMapper.listItemWithDB(dbListItem)
                                    savedListItems.append(savedListItem)
                                }
                            }
                            
                            return (success: true, listItems: savedListItems)
                        })
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if let bgResult = bgResultMaybe { // bg ran successfully
                        
                        if self?.memProvider.enabled ?? false {
                            // bgResult & mem enabled -> do nothing: added item was returned to handler already (after add to mem provider), no need to return it again
                            
                        } else {
                            // mem provider is not enabled - controller is waiting for result - return it
                            handler(ProviderResult(status: .Success, sucessResult: bgResult.listItems))
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
                        self?.remoteProvider.add(bgResult.listItems) {remoteResult in
                            if let remoteListItems = remoteResult.successResult {
                                self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
                                }
                            } else {
                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[ListItem]>) in
                                    QL4("Remote call no success: \(remoteResult)")
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
        
        self.listItems(list, sortOrderByStatus: status, fetchMode: .MemOnly) {result in // TODO review .First suitable here

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
                self.updateLocal(listItems, handler: handler, onFinishLocal: {[weak self] in
                    
                    if remote {
                        
                        self?.remoteProvider.updateStatus(listItems) {remoteResult in
                            
                            if let serverLastUpdateTimestamp = remoteResult.successResult {

                                // The batch update returns 1 timestamp for all the items. We generate here the timestamp update dicts for all the items with this timestamp.
                                let updateTimestampDicts = listItems.map{listItem in
                                    RemoteListItem.createTimestampUpdateDict(uuid: listItem.uuid, lastUpdate: serverLastUpdateTimestamp)
                                }
                                self?.dbProvider.updateListItemsLastSyncTimeStamps(updateTimestampDicts) {success in
                                }
                            } else {
                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                                    QL4("Remote call no success: \(remoteResult) items: \(listItems)")
                                    self?.memProvider.invalidate()
                                    handler(result)
                                })
                            }
                        }
                    }
                })
                
            } else {
                print("Error: didn't get listItems in updateBatchDone: \(result.status)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }

    // Helper for common code of status switch update and full update - the only difference of these method is the remote call, switch uses an optimised service.
    // The local call is in both cases a full update.
    // The local call could principially also be optimised for switch but don't see it's worth it, as we still have to update 6 fields so I assume just saving the whole object has about the same performance.
    private func updateLocal(listItems: [ListItem], remote: Bool = true, handler: ProviderResult<Any> -> Void, onFinishLocal: VoidFunction) {
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
          
            onFinishLocal()
        })
    }
    
    func update(listItems: [ListItem], remote: Bool = true, _ handler: ProviderResult<Any> -> ()) {
        
        self.updateLocal(listItems, handler: handler, onFinishLocal: {[weak self] in
            if remote {
                self?.remoteProvider.update(listItems) {remoteResult in
                    if let remoteListItems = remoteResult.successResult {
                        self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Remote call no success: \(remoteResult) items: \(listItems)")
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
                
                if let serverLastUpdateTimestamp = remoteResult.successResult {
                    
                    
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
                    let updateTimeStampDict = RemoteListItem.createTimestampUpdateDict(uuid: listItem.uuid, lastUpdate: serverLastUpdateTimestamp)
                    self?.dbProvider.updateListItemLastSyncTimeStamp(updateTimeStampDict) {success in
                    }
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                        QL4("Remote call no success: \(remoteResult) item: \(listItem)")
                        self?.memProvider.invalidate()
                        handler(result)
                    })
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