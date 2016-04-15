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

    // MARK: - Get
    
    func listItems(list: List, sortOrderByStatus: ListItemStatus, fetchMode: ProviderFetchModus = .Both, _ handler: ProviderResult<[ListItem]> -> ()) {

        let memListItemsMaybe = memProvider.listItems(list)
        if let memListItems = memListItemsMaybe {
            // Sorting is for the case the list items order was updated (either with reorder or switch status) it's a bit easier right now to put the sorting here TODO resort when storing in mem cache
            let memSortedListItems = memListItems.sortedByOrder(sortOrderByStatus)
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: memSortedListItems))
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
    
    // This is currently used only to retrieve possible product's list item on receiving a websocket notification with a product update
    func listItem(product: Product, list: List, _ handler: ProviderResult<ListItem?> -> ()) {
        DBProviders.listItemProvider.listItem(list, product: product) {listItemMaybe in
            if let listItem = listItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: listItem))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    // MARK: -
    
    func remove(listItem: ListItem, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        removeListItem(listItem.uuid, listUuid: listItem.list.uuid, remote: remote, handler)
    }

    func removeListItem(listItemUuid: String, listUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        let memUpdated = memProvider.removeListItem(listUuid, uuid: listItemUuid)
        if memUpdated {
            handler(ProviderResult(status: ProviderStatusCode.Success))
        }
        
        // remote -> markForSync: if we want to call remote it means we want to mark item for sync.
        self.dbProvider.remove(listItemUuid, listUuid: listUuid, markForSync: remote, handler: {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .Success))
                }
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
                self?.memProvider.invalidate()
            }
            if remote {
                self?.remoteProvider.removeListItem(listItemUuid) {result in
                    if result.success {
                        self?.dbProvider.clearListItemTombstone(listItemUuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for: \(listItemUuid)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(result, handler: {(result: ProviderResult<[Any]>) in
                            print("Error: Removing listItem: \(listItemUuid)")
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
        DBProviders.listProvider.remove(listUuid, markForSync: true) {[weak self] removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
            
            if remote {
                if removed {
                    self?.remoteProvider.remove(listUuid) {remoteResult in
                        if remoteResult.success {
                            DBProviders.listProvider.clearListTombstone(listUuid) {removeTombstoneSuccess in
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
    
    func add(groupItems: [GroupItem], status: ListItemStatus, list: List, _ handler: ProviderResult<[ListItem]> -> ()) {
        let listItemPrototypes: [ListItemPrototype] = groupItems.map{ListItemPrototype(product: $0.product, quantity: $0.quantity, targetSectionName: $0.product.category.name, targetSectionColor: $0.product.category.color)}
        self.add(listItemPrototypes, status: status, list: list, handler)
    }
    
    func addGroupItems(group: ListItemGroup, status: ListItemStatus, list: List, _ handler: ProviderResult<[ListItem]> -> ()) {
        Providers.listItemGroupsProvider.groupItems(group) {[weak self] result in
            if let groupItems = result.sucessResult {
                self?.add(groupItems, status: status, list: list, handler)
            } else {
                print("Error: ListItemProviderImpl.addGroupItems: Can't get group items for group: \(group)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO these services now are only for the websockets - and websocket call is commented. We just added status parameter to all the add-calls, do we need it here also? Do we have to change sth in the backend? In any case these services probably need to be rewritten now, these services where implemented at the very beginning for sth different and "reused" for websockets. For example it may be that we don't need the increment functionality for websockets.
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Note: status assumed to be .Todo as we can add list item input only to .Todo
    func add(listItemInput: ListItemInput, status: ListItemStatus, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: ListItemStatusOrder?, _ handler: ProviderResult<ListItem> -> Void) {
        sectionAndProductForAddUpdate(listItemInput, list: list, possibleNewSectionOrder: possibleNewSectionOrder) {[weak self] result in
            if let (section, product) = result.sucessResult {
                self?.addListItem(product, status: status, section: section, quantity: listItemInput.quantity, list: list, note: listItemInput.note, order: orderMaybe, handler)
            } else {
                QL4("Error fetching section and/or product: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    // Updates list item
    // We load product and section from db identified by uniques and update and link to them, instead of updating directly the product and section of the item
    // The reason for this, is that if we udpate a part of the unique say the product's brand, we have to look if a product with the new unique exist and link to that one - otherwise we may end with 2 products (or sections) with the same semantic unique (but different uuids) and this is invalid, among others it causes an error in the server. 
    // NOTE: for now assumes that the store is not updated (the app doesn't allow to edit the store of a list item). This means that we don't look if a store product with the name-brand-store exists and link to that one if it does like we do with product or category. We just update the current store product. TODO review this
    func update(listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, _ remote: Bool, _ handler: ProviderResult<ListItem> -> Void) {
        sectionAndProductForAddUpdate(listItemInput, list: list, possibleNewSectionOrder: nil) {[weak self] result in
            if let (section, product) = result.sucessResult {
                
                let storeProduct = StoreProduct(uuid: updatingListItem.product.product.uuid, price: listItemInput.price, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, store: updatingListItem.list.store ?? "", product: product) // possible store product update
                
                let listItem = ListItem(
                    uuid: updatingListItem.uuid,
                    product: storeProduct,
                    section: section,
                    list: list,
                    note: listItemInput.note,
                    statusOrder: ListItemStatusOrder(status: status, order: updatingListItem.order(status)),
                    statusQuantity: ListItemStatusQuantity(status: status, quantity: listItemInput.quantity)
                )
                
                self?.update([listItem], remote: remote) {result in
                    if result.success {
                        handler(ProviderResult(status: .Success, sucessResult: listItem))
                    } else {
                        QL4("Error updating list item: \(result)")
                        handler(ProviderResult(status: result.status))
                    }
                }
            } else {
                QL4("Error fetching section and/or product: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    private func sectionAndProductForAddUpdate(listItemInput: ListItemInput, list: List, possibleNewSectionOrder: ListItemStatusOrder?, _ handler: ProviderResult<(Section, Product)> -> Void) {
        Providers.sectionProvider.mergeOrCreateSection(listItemInput.section, sectionColor: listItemInput.sectionColor, status: .Todo, possibleNewOrder: possibleNewSectionOrder, list: list) {result in
            
            if let section = result.sucessResult {
                
                // updateCategory: false: we don't touch product's category from list items - our inputs affect only the section. We use them though to create a category in the case a category with the section's name doesn't exists already. A product needs a category and it's logical to simply default this to the section if it doesn't exist, instead of making user enter a second input for the category. From user's perspective, most times category = section.
                //Providers.productProvider.mergeOrCreateProduct(listItemInput.name, productPrice: listItemInput.price, category: listItemInput.section, categoryColor: listItemInput.sectionColor, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand, store: listItemInput.store, updateCategory: false)
                Providers.productProvider.mergeOrCreateProduct(listItemInput.name, category: listItemInput.section, categoryColor: listItemInput.sectionColor, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand, updateCategory: false) {result in
                    
                    if let product = result.sucessResult {
                        handler(ProviderResult(status: .Success, sucessResult: (section, product)))
                        
                    } else {
                        QL4("Error fetching product: \(result.status)")
                        handler(ProviderResult(status: .DatabaseUnknown))
                    }
                }
            } else {
                QL4("Error fetching section: \(result.status)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    

    // Adds list item with todo status
    func addListItem(product: Product, status: ListItemStatus, sectionName: String, sectionColor: UIColor, quantity: Int, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        let listItemPrototype = ListItemPrototype(product: product, quantity: quantity, targetSectionName: sectionName, targetSectionColor: sectionColor)
        self.add(listItemPrototype, status: status, list: list, handler)
    }
    
    private func addSync(prototype: ListItemPrototype) {
    
    }
    
    func add(prototype: ListItemPrototype, status: ListItemStatus, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        
        add([prototype], status: status, list: list, note: note, order: orderMaybe) {result in
            if let addedListItems = result.sucessResult {
                
                if let addedListItem = addedListItems.first {
                    handler(ProviderResult(status: .Success, sucessResult: addedListItem))
                } else {
                    print("Error: ListItemProviderImpl.add:prototype: Invalid state: add returned success result but it's empty. Status (should be success): \(result.status)")
                    handler(ProviderResult(status: .Unknown))
                }
            } else {
                print("Error: ListItemProviderImpl.add:prototype: Add didn't return success result, status: \(result.status)")
                handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
            }
        }
    }
    
    // Adds list items to .Todo
    func add(prototypes: [ListItemPrototype], status: ListItemStatus, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<[ListItem]> -> Void) {
        
        func getOrderForNewSection(existingListItems: Results<DBListItem>) -> Int {
            let sectionsOfItemsWithStatus: [DBSection] = existingListItems.collect({
                if $0.hasStatus(status) {
                    return $0.section
                } else {
                    return nil
                }
            })
            return sectionsOfItemsWithStatus.distinctUsingEquatable().count
        }
        
        typealias BGResult = (success: Bool, listItems: [ListItem]) // helper to differentiate between nil result (db error) and nil listitem (the item was already returned from memory - don't return anything)
        
        dbProvider.withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
            
            return syncedRet(weakSelf) {
        
                let storePrototypes: [StoreListItemPrototype] = {
                    let existingStoreProducts = DBProviders.storeProductProvider.storeProductsSync(prototypes.map{$0.product}, store: list.store ?? "") ?? {
                        QL4("An error ocurred fetching store products, array is nil")
                        return [] // maybe we should exit from method here - for now only error log and return empty array
                        }()
                    let existingStoreProductsDict = existingStoreProducts.toDictionary{($0.product.uuid, $0)}
                    return prototypes.map {prototype in
                        let storeProduct = existingStoreProductsDict[prototype.product.uuid] ?? {
                            let storeProduct = StoreProduct(uuid: NSUUID().UUIDString, price: 1, baseQuantity: 1, unit: StoreProductUnit.None, store: list.store ?? "", product: prototype.product)
                            QL1("Store product doesn't exist, created: \(storeProduct)")
                            return storeProduct
                            }()
                        return StoreListItemPrototype(product: storeProduct, quantity: prototype.quantity, targetSectionName: prototype.targetSectionName, targetSectionColor: prototype.targetSectionColor)
                    }
                }()
                
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                // TODO interaction with mem provider is a bit finicky and messy here, if performance is ok and everything works correctly maybe we should do all the logic here and pass only the final list item to the mem provider. The initial idea I think was to put the logic to "upsert" listitem/section in mem provider in order to call handler with the result as soon as possible. This may have had another reasons besides only performance. Review this.
                
                // Fetch the section or create a new one if it doesn't exist. Note that this could be/was previously done in the memory provider, which helps a bit with performance as we don't have to read from the database. But we can have sections that are not referenced by any list item (in all status), so they are not in mem provider which has only list items. When sections are left empty after deleting list items or moving items to other sections, we don't delete the sections. So we now retrieve/create section here and pass it to mem provider together with the prototype.
                let prototypesWithSections: [(StoreListItemPrototype, Section)] = storePrototypes.map {prototype in
                    let existingSectionMaybe = realm.objects(DBSection).filter(DBSection.createFilter(prototype.targetSectionName, listUuid: list.uuid)).first.map {dbSection in
                        SectionMapper.sectionWithDB(dbSection)
                    }
                    let section = existingSectionMaybe ?? Section(uuid: NSUUID().UUIDString, name: prototype.targetSectionName, color: prototype.targetSectionColor, list: list, order: ListItemStatusOrder(status: status, order: 0)) // NOTE: order for new section is overwritten in mem provider!
                    
                    return (prototype, section)
                }
                
                
                let memAddedListItemsMaybe = weakSelf.memProvider.addOrUpdateListItems(prototypesWithSections, status: status, list: list, note: note)
                if let addedListItems = memAddedListItemsMaybe {
                    dispatch_async(dispatch_get_main_queue(), {
                        // return in advance so our client is quick - the database update continues in the background
                        handler(ProviderResult(status: .Success, sucessResult: addedListItems))
                    })
                }
                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                
                
                return weakSelf.dbProvider.doInWriteTransactionSync({realm in
                    
                    // even if we have the possibly updated item from mem cache, do always a fetch to db and use this item - to guarantee max. consistency.s
                    // theoretically the state in mem should match the state in db so this fetch should not be necessary, but for now let's be secure.
                    
                    // see if there's already a listitem for this product in the list - if yes only increment it
                    
                    let existingListItems = realm.objects(DBListItem).filter(DBListItem.createFilterList(list.uuid))
                    let existingListItemsDict: [String: DBListItem] = existingListItems.toDictionary{(DBStoreProduct.nameBrandStoreKey($0.product.product.name, brand: $0.product.product.brand, store: $0.product.store), $0)}
                    
                    // Quick access for mem cache items - for some things we need to check if list items were added in the mem cache
                    let memoryCacheItemsDict: [String: ListItem]? = memAddedListItemsMaybe?.toDictionary{(DBStoreProduct.nameBrandStoreKey($0.product.product.name, brand: $0.product.product.brand, store: $0.product.store), $0)}
                    
                    // Holds count of new items per section, which is incremented while we loop through prototypes
                    // we need this to determine the order of the items in the sections - which is the last index in existing items + new items count so far in section
                    var sectionCountNewItemsDict: [String: Int] = [:]
                    
                    var savedListItems: [ListItem] = []
                    
                    let dbList = ListMapper.dbWithList(list)
                    
                    for prototype in storePrototypes {
                        if var existingListItem = existingListItemsDict[DBStoreProduct.nameBrandStoreKey(prototype.product.product.name, brand: prototype.product.product.brand, store: prototype.product.store)] {
                            
                            existingListItem.increment(ListItemStatusQuantity(status: status, quantity: prototype.quantity))
                            
                            // load section with given name or create a new one if it doesn't exist
                            let section: DBSection = {
                                realm.objects(DBSection).filter(DBSection.createFilter(prototype.targetSectionName, listUuid: list.uuid)).first ?? {
                                    let sectionOrder = orderMaybe ?? getOrderForNewSection(existingListItems)
                                    let newSection = DBSection(uuid: NSUUID().UUIDString, name: prototype.targetSectionName, bgColorHex: prototype.targetSectionColor.hexStr, list: dbList, order: ListItemStatusOrder(status: status, order: sectionOrder))
                                    QL1("Section: \(prototype.targetSectionName) doesn't exist, creating a new one. uuid: \(newSection.uuid), in list: \(list.uuid)")
                                    return newSection
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
                            
                            // see if there's already a section for the new list item in the list, if not create a new one
                            //                        let listItemsInList = realm.objects(DBListItem).filter(DBListItem.createFilter(list))
                            let sectionName = prototype.targetSectionName
                            let section = existingListItems.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
                                return SectionMapper.sectionWithDB(item.section)
                                } ?? { // section not existent create a new one
                                    
                                    let sectionCount = getOrderForNewSection(existingListItems)
                                    
                                    // if we already created a new section in the memory cache use that one otherwise create (create case normally only if memcache is disabled)
                                    return memoryCacheItemsDict?[DBStoreProduct.nameBrandStoreKey(prototype.product.product.name, brand: prototype.product.product.brand, store: prototype.product.store)]?.section ?? Section(uuid: NSUUID().UUIDString, name: sectionName, color: prototype.targetSectionColor, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
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
                                        if existingListItem.section.uuid == section.uuid && existingListItem.hasStatus(status) {
                                            existingCountInSection++
                                        }
                                    }
                                    sectionCountNewItemsDict[section.uuid] = existingCountInSection
                                    return existingCountInSection
                                }
                            }()
                            
                            let uuid = memoryCacheItemsDict?[DBStoreProduct.nameBrandStoreKey(prototype.product.product.name, brand: prototype.product.product.brand, store: prototype.product.store)]?.uuid ?? NSUUID().UUIDString
                            
                            
                            // create the list item and save it
                            // memcache uuid: if we created a new listitem in memcache use this uuid so our data is consistent mem/db
                            let listItem = ListItem(
                                uuid: uuid,
                                product: prototype.product,
                                section: section,
                                list: list,
                                note: note,
                                statusOrder: ListItemStatusOrder(status: status, order: listItemOrder),
                                statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.quantity)
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
            
        }) {[weak self] (bgResultMaybe: BGResult?) -> Void in
                
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
        }
    }

    func addListItem(product: Product, status: ListItemStatus, section: Section, quantity: Int, list: List, note: String? = nil, order orderMaybe: Int? = nil, _ handler: ProviderResult<ListItem> -> Void) {
        // for now call the other func, which will fetch the section again... review if this is bad for performance otherwise let like this
        addListItem(product, status: status, sectionName: section.name, sectionColor: section.color, quantity: quantity, list: list, note: note, order: orderMaybe, handler)
    }
    
    // Common code for update single and batch list items switch status (in case of single listItems contains only 1 element)
    private func switchStatusInsertInDst(listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: (switchedItems: [ListItem], storedItems: [ListItem])? -> Void) {
        
        self.listItems(list, sortOrderByStatus: status, fetchMode: .MemOnly) {result in // TODO review .First suitable here
            
            if let storedListItems = result.sucessResult {
                
                // Update quantity and order field - by changing quantity we are moving list items from one status to another
                // we append the items at the end of the dst section (order == section.count)
                var dstSectionsDict = storedListItems.sectionCountDict(status)
                for listItem in listItems {
                    
                    let listItemOrderInDstStatus: Int? = listItem.hasStatus(status) ? listItem.order(status) : nil // catch this before switching quantity
                    
                    listItem.switchStatusQuantityMutable(status1, targetStatus: status)
                    if let sectionCount = dstSectionsDict[listItem.section] { // TODO rename this sounds like count of sections but it's count of list item in sections

                        // If there's already a list item in the target status don't update order. If there's not, set order to last item in section
                        let listItemOrder: Int = listItemOrderInDstStatus ?? sectionCount
                        
                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: listItemOrder))
                        dstSectionsDict[listItem.section]!++ // we are adding an item to section - increment count for possible next item
                        
                    } else { // item's section is not in target status - set order 0 (first item in section) and add section to the dictionary
                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: 0))
                        // update order such that section is appended at the end
                        listItem.section.updateOrderMutable(ListItemStatusOrder(status: status, order: dstSectionsDict.count))
                        dstSectionsDict[listItem.section] = 1 // we are adding an item to section - items count is 1
                    }
                    // this is not really necessary, but for consistency - reset order to 0 in the src status.
                    listItem.updateOrderMutable(ListItemStatusOrder(status: status1, order: 0))
                    
//                    QL2("List item after status update: \(listItem.quantityDebugDescription)")
                }
                
                handler((switchedItems: listItems, storedItems: storedListItems))
        
            } else {
                QL4("Didn't get listItems: \(result.status), can't switch")
                handler(nil)
            }
        }
    }

    func switchStatus(listItem: ListItem, list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        
//        QL2("Switching status from \(listItem.product.product.name) from status \(status1) to \(status)")
        
        switchStatusInsertInDst([listItem], list: list, status1: status1, status: status, remote: remote) {switchResult in
            
            if let (switchedItems, storedListItems) = switchResult { // here switchedItems is a 1 element array, containing the switched listItem
                
                // Update src items order. We have to shift the followers in the same section or, if the section is empty after we switch item the order of the follower sections - for simplicity we just update the order field of all src list items and sections.
                let allItemsToUpdate: [ListItem] = {
                    if let switchedItem = switchedItems.first {
                        var items = storedListItems
                        items.update(switchedItem) // Update switched item in this array such that it's count in src is 0 and reorder works correctly
                        items.sortAndUpdateOrderFieldsMutating(status1) // This filters and sorts by src status, iterates through them setting order to index.
                        return switchedItems + items // Add again the switched list item to the array (it's lost when we filter by src status)
                    } else {
                        QL4("Invalid state: there should be a switched list item")
                        return switchedItems
                    }
                }()
                
//                QL2("After switching: \(listItem.product.product.name), writing updated items to db: \(allItemsToUpdate)")
                
                // Persist changes. If mem cached is enabled this calls handler directly after mem cache is updated and does db update in the background.
                self.updateLocal(allItemsToUpdate, handler: handler, onFinishLocal: {[weak self] in
                    
                    if remote {
                        let statusUpdate = ListItemStatusUpdate(src: status1, dst: status)
                        self?.remoteProvider.updateStatus(listItem, statusUpdate: statusUpdate) {remoteResult in
                            if let remoteUpdateResult = remoteResult.successResult {
                                DBProviders.listItemProvider.storeRemoteListItemSwitchResult(statusUpdate, result: remoteUpdateResult) {success in
                                    if !success {
                                        QL4("Couldn't store remote switch result in database: \(remoteResult) item: \(listItem)")
                                    }
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
                })
            } else {
                QL4("Stored list items returned nil")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    // IMPORTANT: Assumes that the passed list items are ALL the existing list items in src status. If this is not the case, the remaining items/sections in src status will likely be left with a wrong order.
    func switchAllToStatus(listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        
        switchStatusInsertInDst(listItems, list: list, status1: status1, status: status, remote: remote) {switchResult in
            
            if let (switchedItems, _) = switchResult { // here switchedItems is a 1 element array, containing the switched listItem
                
                // all the list items in src status are gone - set src order to 0, just for consistency
                switchedItems.forEach({listItem -> Void in
                    listItem.updateOrderMutable(ListItemStatusOrder(status1, order: 0))
                    listItem.section.updateOrderMutable(ListItemStatusOrder(status1, order: 0)) // this may update sections multiple times but it doesn't matter
                })
                
                // Persist changes. If mem cached is enabled this calls handler directly after mem cache is updated and does db update in the background.
                self.updateLocal(switchedItems, handler: handler, onFinishLocal: {[weak self] in
                    
                    if remote {
                        let statusUpdate = ListItemStatusUpdate(src: status1, dst: status)
                        self?.remoteProvider.updateAllStatus(list.uuid, statusUpdate: statusUpdate) {remoteResult in
                            if let remoteUpdateResult = remoteResult.successResult {
                                DBProviders.listItemProvider.storeRemoteAllListItemSwitchResult(statusUpdate, result: remoteUpdateResult) {success in
                                    if !success {
                                        QL4("Couldn't store remote all switch result in database: \(remoteResult) items: \(listItems)")
                                    }
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
                QL4("Stored list items returned nil")
                handler(ProviderResult(status: .Unknown))
            }
        }
        
    }

    // Helper for common code of status switch update, order update and full update - the only difference of these method is the remote call, switch and order use optimised services.
    // The local call is in all cases a full update.
    // The local call could principially also be optimised but don't see it's worth it, probably the performance is not very different than updating the whole object.
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
    
    func updateListItemsOrder(listItems: [ListItem], status: ListItemStatus, remote: Bool = true, _ handler: ProviderResult<Any> -> Void) {
        
        self.updateLocal(listItems, handler: handler, onFinishLocal: {[weak self] in
            if remote {
                self?.remoteProvider.updateListItemsOrder(listItems, status: status) {remoteResult in
                    if remoteResult.success {
                        // TODO see note in RemoteListItemProvider.updateListItemsTodoOrder
//                        self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
//                        }
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
    
    // TODO!!!! for all status
    func updateListItemsTodoOrderRemote(orderUpdates: [RemoteListItemReorder], sections: [Section], _ handler: ProviderResult<Any> -> Void) {
        DBProviders.listItemProvider.updateListItemsTodoOrderRemote(orderUpdates, sections: sections) {success in
            if success {
                handler(ProviderResult(status: .Success))
            } else {
                QL4("Couldn't store remote list items order update")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    // TODO!!!! remote? why did this service not have remote before, forgot or we don't need it there?
    func increment(listItem: ListItem, status: ListItemStatus, delta: Int, remote: Bool, _ handler: ProviderResult<ListItem> -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.increment(listItem, quantity: ListItemStatusQuantity(status: status, quantity: delta))
        if let memIncremented = memIncremented {
            
            dispatch_async(dispatch_get_main_queue(), { // since the transaction is executed in the background we have to return to main thread here
                handler(ProviderResult(status: .Success, sucessResult: memIncremented))
            })
        }
        dbProvider.incrementListItem(listItem, delta: delta, status: status) {[weak self] listItemMaybe in
            
            if memIncremented == nil { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if let listItem = listItemMaybe {
                    handler(ProviderResult(status: .Success, sucessResult: listItem))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
            
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
                    DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<ListItem>) in
                        QL4("Remote call no success: \(remoteResult) item: \(listItem)")
                        self?.memProvider.invalidate()
                        handler(result)
                    })
                }
            }
        }
    }
    
    // only db no memory cache or remote, this is currently used only by websocket update (when receive websocket increment, fetch inventory item in order to increment it locally)
    private func findListItem(uuid: String, _ handler: ProviderResult<ListItem> -> ()) {
        DBProviders.listItemProvider.findListItem(uuid) {listItemMaybe in
            if let listItem = listItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: listItem))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    // TODO this can be optimised, such that we don't have to prefetch the item but increment directly at least in memory
    func increment(increment: ItemIncrement, status: ListItemStatus, remote: Bool, _ handler: ProviderResult<ListItem> -> Void) {
        findListItem(increment.itemUuid) {[weak self] result in
            if let listItem = result.sucessResult {
                
                self?.increment(listItem, status: status, delta: increment.delta, remote: remote) {result in

                    if let statusQuantity = result.sucessResult {
                        handler(ProviderResult(status: .Success, sucessResult: statusQuantity))
                    } else {
                        handler(ProviderResult(status: .DatabaseSavingError))
                    }
                }
                
            } else {
                print("InventoryItemsProviderImpl.incrementInventoryItem: Didn't find inventory item to increment, for: \(increment)")
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    
    func invalidateMemCache() {
        memProvider.invalidate()
    }
    
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