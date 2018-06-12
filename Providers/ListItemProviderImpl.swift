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
    let memProvider = MemListItemProvider(enabled: false)

    // MARK: - Get
    
    func listItems(_ list: List, sortOrderByStatus: ListItemStatus, fetchMode: ProviderFetchModus = .both, _ handler: @escaping (ProviderResult<Results<ListItem>>) -> Void) {

        let memListItemsMaybe = memProvider.listItems(list)
        // mem provider temporarily disabled - IMPORTANT uncomment this for it to work properly
//        if let memListItems = memListItemsMaybe {
//            // Sorting is for the case the list items order was updated (either with reorder or switch status) it's a bit easier right now to put the sorting here TODO resort when storing in mem cache
//            let memSortedListItems = memListItems.sortedByOrder(sortOrderByStatus)
//            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: memSortedListItems))
//            if fetchMode == .memOnly || fetchMode == .first {
//                return
//            }
//        }

        dbProvider.loadListItems(list, status: sortOrderByStatus, handler: {listItems in
            
            // we assume the database result is always == mem result, so if returned from mem already no need to return from db
            // TODO there's no need to load the items from db before doing the remote call (confirm this), since we assume memory == database it would be enough to compare 
            // the server result with memory. Load from db only when there's no memory cache.
            if !memListItemsMaybe.isSet {
                if let listItems = listItems {
                    handler(ProviderResult(status: .success, sucessResult: listItems))
                } else {
                    logger.e("Couldn't load groups")
                    handler(ProviderResult(status: .unknown))
                }
            }
            
//            _ = self?.memProvider.overwrite(listItems) mem provider temporarily disabled - IMPORTANT uncomment this for it to work properly
            
            // Disabled while impl. realm sync
//            self?.remoteProvider.listItems(list: list) {[weak self] remoteResult in
//                
//                if let remoteListItems = remoteResult.successResult {
//                    let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems, sortOrderByStatus: sortOrderByStatus)
//                    
//                    if (sotedListItems != listItemsWithRelations.listItems) { // note: listItemsWithRelations.listItems is already sorted by order
//                        self?.dbProvider.overwrite(listItemsWithRelations.listItems, listUuid: list.uuid, clearTombstones: true) {saved in
//                            
//                            handler(ProviderResult(status: ProviderStatusCode.success, sucessResult: listItemsWithRelations.listItems))
//                            _ = self?.memProvider.overwrite(listItemsWithRelations.listItems)
//                        }
//                    }
//                    
//                } else {
//                    DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
//                }
//            }
        })
    }
    
    // This is currently used only to retrieve possible product's list item on receiving a websocket notification with a product update
    func listItem(_ product: Product, list: List, _ handler: @escaping (ProviderResult<ListItem?>) -> ()) {
        DBProv.listItemProvider.listItem(list, product: product) {listItemMaybe in
            if let listItem = listItemMaybe {
                handler(ProviderResult(status: .success, sucessResult: listItem))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }
    
    func listItems(_ uuids: [String], _ handler: @escaping (ProviderResult<[ListItem]>) -> ()) {
        DBProv.listItemProvider.loadListItems(uuids) {items in
            if let items = items {
                handler(ProviderResult(status: .success, sucessResult: items.toArray()))
            } else {
                logger.e("Couldn't load items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func listItems<T>(list: List, ingredient: Ingredient, mapper: @escaping (Results<ListItem>) -> T, _ handler: @escaping (ProviderResult<T>) -> Void) {
        DBProv.listItemProvider.listItems(list: list, ingredient: ingredient, mapper: mapper) {items in
            if let items = items {
                handler(ProviderResult(status: .success, sucessResult: items))
            } else {
                logger.e("Couldn't load items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // MARK: -
    
    func remove(_ listItem: ListItem, remote: Bool, token: RealmToken?, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        removeListItem(listItem.uuid, listUuid: listItem.list.uuid, remote: remote, token: token, handler)
    }

    func removeListItem(_ listItemUuid: String, listUuid: String, remote: Bool, token: RealmToken?, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        
        let memUpdated = memProvider.removeListItem(listUuid, uuid: listItemUuid)
        if memUpdated {
            handler(ProviderResult(status: ProviderStatusCode.success))
        }
        
        // remote -> markForSync: if we want to call remote it means we want to mark item for sync.
        dbProvider.remove(listItemUuid, listUuid: listUuid, markForSync: remote, token: token, handler: {[weak self] removed in
            if removed {
                if !memUpdated {
                    handler(ProviderResult(status: .success))
                }
            } else {
                handler(ProviderResult(status: .databaseUnknown))
                self?.memProvider.invalidate()
            }
            
            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteProvider.removeListItem(listItemUuid) {result in
//                    if result.success {
//                        self?.dbProvider.clearListItemTombstone(listItemUuid) {removeTombstoneSuccess in
//                            if !removeTombstoneSuccess {
//                                logger.e("Couldn't delete tombstone for: \(listItemUuid)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(result, handler: handler)
//                    }
//                }
//            }
        })
    }
    
    func remove(_ list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        remove(list.uuid, remote: remote, handler)
    }
    
    func remove(_ listUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        memProvider.invalidate()
        DBProv.listProvider.remove(listUuid, markForSync: true) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.success : ProviderStatusCode.databaseUnknown))
            
            // Disabled while impl. realm sync
//            if remote {
//                if removed {
//                    self?.remoteProvider.remove(listUuid) {remoteResult in
//                        if remoteResult.success {
//                            DBProv.listProvider.clearListTombstone(listUuid) {removeTombstoneSuccess in
//                                if !removeTombstoneSuccess {
//                                    logger.e("Couldn't delete tombstone for list: \(listUuid)")
//                                }
//                            }
//                        } else {
//                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[Any]>) in
//                                logger.e(remoteResult)
//                            })
//                        }
//                    }
//                }
//            }
        }
    }
    
    func add(_ groupItems: [GroupItem], status: ListItemStatus, list: List, _ handler: @escaping (ProviderResult<[ListItem]>) -> ()) {
        let listItemPrototypes: [ListItemPrototype] = groupItems.map{
            let storeProductInput = StoreProductInput(price: 0, refPrice: nil, refQuantity: nil, baseQuantity: $0.product.baseQuantity, secondBaseQuantity: $0.product.secondBaseQuantity, unit: $0.product.unit.name)
            return ListItemPrototype(product: $0.product, quantity: $0.quantity, targetSectionName: $0.product.product.item.category.name, targetSectionColor: $0.product.product.item.category.color, storeProductInput: storeProductInput)
        }
        self.add(listItemPrototypes, status: status, list: list, token: nil, handler)
    }
    
    func addGroupItems(_ group: ProductGroup, status: ListItemStatus, list: List, _ handler: @escaping (ProviderResult<[ListItem]>) -> ()) {
        Prov.listItemGroupsProvider.groupItems(group, sortBy: .alphabetic, fetchMode: .memOnly) {[weak self] result in
            if let groupItems = result.sucessResult {
                if groupItems.isEmpty {
                    handler(ProviderResult(status: .isEmpty))
                } else {
                    self?.add(groupItems.toArray(), status: status, list: list, handler)
                }
                
            } else {
                print("Error: ListItemProviderImpl.addGroupItems: Can't get group items for group: \(group)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // TODO these services now are only for the websockets - and websocket call is commented. We just added status parameter to all the add-calls, do we need it here also? Do we have to change sth in the backend? In any case these services probably need to be rewritten now, these services where implemented at the very beginning for sth different and "reused" for websockets. For example it may be that we don't need the increment functionality for websockets.
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func add(_ listItems: [ListItem], remote: Bool = true, _ handler: @escaping (ProviderResult<[ListItem]>) -> ()) {

        let addedListItemsMaybe = memProvider.addListItems(listItems)
        if let addedListItems = addedListItemsMaybe {
            handler(ProviderResult(status: .success, sucessResult: addedListItems))
        }
        
        // TODO review carefully what happens if adding fails after memory cache is updated
        dbProvider.addOrIncrementListItems(listItems) {[weak self] savedListItemsMaybe in // currently the item returned by server is identically to the one we sent, so we just save our local item
            if let savedListItems = savedListItemsMaybe {
                if !addedListItemsMaybe.isSet { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                    handler(ProviderResult(status: .success, sucessResult: savedListItems))
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
                handler(ProviderResult(status: .databaseUnknown))
            }

        }
    }
    
    func add(_ listItem: ListItem, remote: Bool = true, _ handler: @escaping (ProviderResult<ListItem>) -> ()) {
        add([listItem]) {result in
            if let listItems = result.sucessResult {
                if let listItem = listItems.first {
                    handler(ProviderResult(status: .success, sucessResult: listItem))
                    
                } else {
                    print("Error: add listitem returned success result but it's an empty array. ListItem: \(listItem)")
                    handler(ProviderResult(status: .unknown))
                }
                
            } else {
                print("Error: add listitem didn't succeed, listItem: \(listItem), result: \(result)")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // Note: status assumed to be .Todo as we can add list item input only to .Todo
    func add(_ listItemInput: ListItemInput, status: ListItemStatus, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: ListItemStatusOrder?, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        add([listItemInput], status: status, list: list, possibleNewSectionOrder: possibleNewSectionOrder, token: token) {result in
            if let listItems = result.sucessResult {
                
                if let first =  listItems.first {
                    handler(ProviderResult(status: .success, sucessResult: first))
                    
                } else {
                    logger.e("Didn't return list item: \(result)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
                
            } else {
                logger.e("Error adding list item: \(result)")
                handler(ProviderResult(status: .databaseUnknown))
            }
            
        }
    }
    
    
    func add(_ listItemInputs: [ListItemInput], status: ListItemStatus, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: ListItemStatusOrder?, token: RealmToken?, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void) {

        // TODO async? - toListItemProtoypes is executed in the main thread. Note that there could be problems with realm's thread handling
        DBProv.listItemProvider.toListItemProtoypes(inputs: listItemInputs, status: status, list: list).onOk {listItemPrototypes in
            self.add(listItemPrototypes, status: status, list: list, token: token, handler)
            
        }.onErr { error in
            logger.e("Error adding list item inputs: \(error)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }

    
    // Updates list item
    // We load product and section from db identified by uniques and update and link to them, instead of updating directly the product and section of the item
    // The reason for this, is that if we udpate a part of the unique say the product's brand, we have to look if a product with the new unique exist and link to that one - otherwise we may end with 2 products (or sections) with the same semantic unique (but different uuids) and this is invalid, among others it causes an error in the server. 
    // NOTE: for now assumes that the store is not updated (the app doesn't allow to edit the store of a list item). This means that we don't look if a store product with the name-brand-store exists and link to that one if it does like we do with product or category. We just update the current store product. TODO review this
    func update(_ listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, _ remote: Bool, realmData: RealmData?, _ handler: @escaping (ProviderResult<(listItem: ListItem, replaced: Bool)>) -> Void) {
        
        // Remove a possible already existing item with same unique (name+brand) in the same list. Exclude editing item - since this is not being executed in a transaction with the upsert of the item, we should not remove it.
        DBProv.listItemProvider.deletePossibleListItemWithUnique(listItemInput.name, productBrand: listItemInput.brand, notUuid: updatingListItem.uuid, list: list) {[weak self] foundAndDeletedListItem in
        
            self?.sectionAndProductForAddUpdate(listItemInput, list: list, possibleNewSectionOrder: nil, realmData: realmData) {[weak self] result in
                
                if let (section, product) = result.sucessResult {

//                    , baseQuantity: listItemInput.storeProductInput.baseQuantity, unit: listItemInput.storeProductInput.unit
                    let storeProduct = StoreProduct(
                        uuid: updatingListItem.product.uuid,
                        refPrice: listItemInput.storeProductInput.refPrice,
                        refQuantity: listItemInput.storeProductInput.refQuantity,
                        store: updatingListItem.list.store ?? "",
                        product: product
                    ) // possible store product update
                    
                    let listItem = ListItem(
                        uuid: updatingListItem.uuid,
                        product: storeProduct,
                        section: section,
                        list: list,
                        note: listItemInput.note,
                        statusOrder: ListItemStatusOrder(status: status, order: updatingListItem.order(status)),
                        statusQuantity: ListItemStatusQuantity(status: status, quantity: listItemInput.quantity)
                    )

                    if foundAndDeletedListItem {
                        // if deleted a list item, invalidate memory cache such that it's updated next request with correct items
                        self?.invalidateMemCache()
                    }
                    
                    self?.update([listItem], remote: remote) {result in
                        if result.success {
                            handler(ProviderResult(status: .success, sucessResult: (listItem: listItem, replaced: foundAndDeletedListItem)))
                        } else {
                            logger.e("Error updating list item: \(result)")
                            handler(ProviderResult(status: result.status))
                        }
                    }
                } else {
                    logger.e("Error fetching section and/or product: \(result.status)")
                    handler(ProviderResult(status: .databaseUnknown))
                }
            }
        }
    }
    
    // Retrieves section and product identified by semantic unique, if they don't exist creates new ones
    fileprivate func sectionAndProductForAddUpdate(_ listItemInput: ListItemInput, list: List, possibleNewSectionOrder: ListItemStatusOrder?, realmData: RealmData?, _ handler: @escaping (ProviderResult<(Section, QuantifiableProduct)>) -> Void) {
        Prov.sectionProvider.mergeOrCreateSection(listItemInput.section, sectionColor: listItemInput.sectionColor, status: .todo, possibleNewOrder: possibleNewSectionOrder, list: list) {result in
            
            if let section = result.sucessResult {
                
                // updateCategory: false: we don't touch product's category from list items - our inputs affect only the section. We use them though to create a category in the case a category with the section's name doesn't exists already. A product needs a category and it's logical to simply default this to the section if it doesn't exist, instead of making user enter a second input for the category. From user's perspective, most times category = section.
                //Prov.productProvider.mergeOrCreateProduct(listItemInput.name, productPrice: listItemInput.price, category: listItemInput.section, categoryColor: listItemInput.sectionColor, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand, store: listItemInput.store, updateCategory: false)
                let prototype = ProductPrototype(name: listItemInput.name, category: listItemInput.section, categoryColor: listItemInput.sectionColor, brand: listItemInput.brand, baseQuantity: listItemInput.storeProductInput.baseQuantity, secondBaseQuantity: listItemInput.storeProductInput.secondBaseQuantity, unit: listItemInput.storeProductInput.unit, edible: listItemInput.edible)
                Prov.productProvider.mergeOrCreateProduct(prototype: prototype, updateCategory: false, updateItem: false, realmData: realmData) {(result: ProviderResult<(QuantifiableProduct, Bool)>) in
                    if let product = result.sucessResult {
                        handler(ProviderResult(status: .success, sucessResult: (section, product.0)))
                        
                    } else {
                        logger.e("Error fetching product: \(result.status)")
                        handler(ProviderResult(status: .databaseUnknown))
                    }
                }
            } else {
                logger.e("Error fetching section: \(result.status)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    

    // Adds list item with todo status
    func addListItem(_ product: QuantifiableProduct, status: ListItemStatus, sectionName: String, sectionColor: UIColor, quantity: Float, list: List, note: String? = nil, order orderMaybe: Int? = nil, storeProductInput: StoreProductInput?, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        let listItemPrototype = ListItemPrototype(product: product, quantity: quantity, targetSectionName: sectionName, targetSectionColor: sectionColor, storeProductInput: storeProductInput)
        self.add(listItemPrototype, status: status, list: list, token: token, handler)
    }
    
    fileprivate func addSync(_ prototype: ListItemPrototype) {
    
    }
    
    func add(_ prototype: ListItemPrototype, status: ListItemStatus, list: List, note: String? = nil, order orderMaybe: Int? = nil, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        
        add([prototype], status: status, list: list, note: note, order: orderMaybe, token: token) {result in
            if let addedListItems = result.sucessResult {
                
//                // TODO review this do we have to return added item or not
//                let c = ProductCategory(uuid: "123", name: "", color: "")
//                let p = Product(uuid: "123", name: "", category: c)
//                let sp = StoreProduct(uuid: "123", price: 1, baseQuantity: 1, unit: .none, product: p)
//                let section = Section(uuid: "123", name: "", color: UIColor.black, list: list.copy(), order: ListItemStatusOrder(status: .todo, order: 1))
//                handler(ProviderResult(status: .success, sucessResult: ListItem(uuid: "", product: sp, section: section, list: list.copy(), note: nil, statusOrder: ListItemStatusOrder(status: .todo, order: 1), statusQuantity: ListItemStatusQuantity(status: .todo, quantity: 1))))
                
                if let addedListItem = addedListItems.first {
                    handler(ProviderResult(status: .success, sucessResult: addedListItem))
                } else {
                    logger.e("Error: ListItemProviderImpl.add:prototype: Invalid state: add returned success result but it's empty. Status (should be success): \(result.status)")
                    handler(ProviderResult(status: .unknown))
                }

            } else {
                logger.e("Error: ListItemProviderImpl.add:prototype: Add didn't return success result, status: \(result.status)")
                handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
            }
        }
    }
    
    // Adds list items to .Todo
    // TODO!!!! review parameters note and order, we are passing a list of prototypes so this doesn't make sense?   
    func add(_ prototypes: [ListItemPrototype], status: ListItemStatus, list: List, note: String? = nil, order orderMaybe: Int? = nil, token: RealmToken?, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void) {
        
        fatalError("Outdated") // Unit refactoring
        
//        // Fixes Realm acces in incorrect thread exceptions
//        let prototypes = prototypes.map{$0.copy()}
//        let list = list.copy()
//        
//        func getOrderForNewSection(_ existingListItems: Results<ListItem>) -> Int {
//            let sectionsOfItemsWithStatus: [Section] = existingListItems.collect({
//                if $0.hasStatus(status) {
//                    return $0.section
//                } else {
//                    return nil
//                }
//            })
//            return sectionsOfItemsWithStatus.distinctUsingEquatable().count
//        }
//        
//        func getItemCountInSection(listItems: Results<ListItem>, section: Section, status: ListItemStatus) -> Int {
//            var count = 0
//            for listItem in listItems {
//                if listItem.section.uuid == section.uuid && listItem.hasStatus(status) {
//                    count += 1
//                }
//            }
//            return count
//        }
//        
//        typealias BGResult = (success: Bool, listItemUuids: [String]) // helper to differentiate between nil result (db error) and nil listitem (the item was already returned from memory - don't return anything). Returns uuids instead of list items because of Realm thread access limitations
//        
//        dbProvider.withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
//            
//            return syncedRet(weakSelf) {
//        
//                guard let existingStoreProducts: Results<StoreProduct> = DBProv.storeProductProvider.storeProductsSync(prototypes.map{$0.product}, store: list.store ?? "") else {
//                    logger.e("Couldn't load store products")
//                    return (success: false, listItemUuids: [])
//                }
//                
//                let storePrototypes: [StoreListItemPrototype] = {
//                    let existingStoreProductsDict = existingStoreProducts.toDictionary{($0.product.uuid, $0)}
//                    return prototypes.map {prototype in
//                        let storeProduct = existingStoreProductsDict[prototype.product.uuid] ?? {
//                            let storeProduct = StoreProduct(uuid: NSUUID().uuidString, price: prototype.storeProductInput?.price ?? 0, store: list.store ?? "", product: prototype.product)
//                            logger.v("Store product doesn't exist, created: \(storeProduct)")
//                            return storeProduct
//                        }()
//                        
//                        // Set possible passed store product properties in the store product we will save. These are passed only when we create list items, using the form
//                        // We don't update e.g. quantifiable properties (unit, base quantity) because we assume in this method that we have up to date quantity product. On one side we can be here with quick-add - then there can't be changes, or with the form, in which case we fetch/create first the quantifiable product for the entered unique. And we just fetched/created the store product using the uuid of quantifiable product with said unique.
//                        let updatedStoreProduct = prototype.storeProductInput.map{
//                            if $0.price == -1 {
//                                return storeProduct // don't update store product (the only attribute that can currently be updated is price)
//                            } else {
//                                return storeProduct.copy(price: $0.price) // update store product with price
//                            }
//                        } ?? storeProduct
//                        return StoreListItemPrototype(product: updatedStoreProduct, quantity: prototype.quantity, targetSectionName: prototype.targetSectionName, targetSectionColor: prototype.targetSectionColor)
//                    }
//                }()
//                
//                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                // TODO interaction with mem provider is a bit finicky and messy here, if performance is ok and everything works correctly maybe we should do all the logic here and pass only the final list item to the mem provider. The initial idea I think was to put the logic to "upsert" listitem/section in mem provider in order to call handler with the result as soon as possible. This may have had another reasons besides only performance. Review this.
//                
//                // Fetch the section or create a new one if it doesn't exist. Note that this could be/was previously done in the memory provider, which helps a bit with performance as we don't have to read from the database. But we can have sections that are not referenced by any list item (in all status), so they are not in mem provider which has only list items. When sections are left empty after deleting list items or moving items to other sections, we don't delete the sections. So we now retrieve/create section here and pass it to mem provider together with the prototype.
//                var prototypesWithSections: [(StoreListItemPrototype, Section)] = []
//                for prototype in storePrototypes {
//
//                    // Use possible equal section from previous items - this is needed because otherwise if we pass e.g. 3 different fruits and there's no fruits section in the database yet, we would create 3 new fruits sections. Also for performance. Note that later we fetch the section again doing the db transaction, so the error of having 3x the same section would be only in memory, i.e. visible the first time we load the controller and fixed after. TODO Simplify this? Do we really need to determine the section here and again in db transaction. This weird functionality may be a leftover of when we used only the memory cache in this part (see previous comment of why this was changed).
//                    let previousItemSectionMaybeWithSameName: (Section)? = (prototypesWithSections.findFirst{$0.1.name == prototype.targetSectionName})?.1
//                    
//                    let section = previousItemSectionMaybeWithSameName ?? {
//                    
//                        let existingSectionMaybe = realm.objects(Section.self).filter(Section.createFilter(prototype.targetSectionName, listUuid: list.uuid)).first
//                        return existingSectionMaybe ?? {
//                            
//                            let newSection: Section = Section(uuid: NSUUID().uuidString, name: prototype.targetSectionName, color: prototype.targetSectionColor, list: list, order: ListItemStatusOrder(status: status, order: 0)) // NOTE: order for new section is overwritten in mem provider!
//                            logger.v("Section for prototype: \(prototype) didn't exist, created a new one: \(newSection)")
//                            return newSection
//                        }()
//                        
//                    }()
//                    prototypesWithSections.append((prototype, section))
//                }
//                
//                let memAddedListItemsMaybe = weakSelf.memProvider.addOrUpdateListItems(prototypesWithSections, status: status, list: list, note: note)
//                if let addedListItems = memAddedListItemsMaybe {
//                    DispatchQueue.main.async {
//                        // return in advance so our client is quick - the database update continues in the background
//                        handler(ProviderResult(status: .success, sucessResult: addedListItems))
//                    }
//                }
//                ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                
//                
//                let tokens = token.map{[$0.token]} ?? []
//                
//                return weakSelf.dbProvider.doInWriteTransactionSync(withoutNotifying: tokens, realm: token?.realm, {realm in
//                    
//                    // even if we have the possibly updated item from mem cache, do always a fetch to db and use this item - to guarantee max. consistency.s
//                    // theoretically the state in mem should match the state in db so this fetch should not be necessary, but for now let's be secure.
//                    
//                    // see if there's already a listitem for this product in the list - if yes only increment it
//                    
//                    let existingListItems = realm.objects(ListItem.self).filter(ListItem.createFilterList(list.uuid))
//                    let existingListItemsDict: [String: ListItem] = existingListItems.toDictionary{(StoreProduct.uniqueDictKey($0.product.product.product.item.name, brand: $0.product.product.product.brand, store: $0.product.store, unit: $0.product.product.unit, baseQuantity: $0.product.product.baseQuantity), $0)}
//                    
//                    // Quick access for mem cache items - for some things we need to check if list items were added in the mem cache
//                    let memoryCacheItemsDict: [String: ListItem]? = memAddedListItemsMaybe?.toDictionary{(StoreProduct.uniqueDictKey($0.product.product.product.item.name, brand: $0.product.product.product.brand, store: $0.product.store, unit: $0.product.product.unit, baseQuantity: $0.product.product.baseQuantity), $0)}
//                    
//                    // Holds count of new items per section, which is incremented while we loop through prototypes
//                    // we need this to determine the order of the items in the sections - which is the last index in existing items + new items count so far in section
//                    var sectionCountNewItemsDict: [String: Int] = [  :]
//                    
//                    var savedListItems: [ListItem] = []
//
//                    for (prototype, section) in prototypesWithSections {
//                        if var existingListItem = existingListItemsDict[StoreProduct.uniqueDictKey(prototype.product.product.product.item.name, brand: prototype.product.product.product.brand, store: prototype.product.store, unit: prototype.product.product.unit, baseQuantity: prototype.product.product.baseQuantity)] {
//                            
//                            existingListItem = existingListItem.increment(ListItemStatusQuantity(status: status, quantity: prototype.quantity))
//                            
//                            // for some reason it crashes in this line (yes here not when saving) with reason: 'Can't set primary key property 'uuid' to existing value '03F949BB-AE2A-427A-B49B-D53FA290977D'.' (this is the uuid of the list), no idea why, so doing a copy.
//                            //                                    existingListItem.section = section
//                            existingListItem = existingListItem.copy(section: section)
//                            
//                            if let note = note {
//                                existingListItem.note = note
//                            }
//                            
//                            // Item exists, but is not in status - append it to the end of section in status
//                            if !existingListItem.hasStatus(status) {
//                                let existingCountInSection = getItemCountInSection(listItems: existingListItems, section: existingListItem.section, status: status)
//                                existingListItem.updateOrder(ListItemStatusOrder(status: status, order: existingCountInSection))
//                            }
//                            
//                            // let incrementedListItem = existingListItem.copy(quantity: existingListItem.quantity + 1)
//                            realm.add(existingListItem, update: true)
//                            
//                            logger.v("item exists, affter incrementent: \(existingListItem)")
//                            
//                            savedListItems.append(existingListItem)
//                            
//                            
//                        } else { // item doesn't exist
//                            
//                            // see if there's already a section for the new list item in the list, if not create a new one
//                            //                        let listItemsInList = realm.objects(ListItem).filter(ListItem.createFilter(list))
//                            let sectionName = prototype.targetSectionName
//                            let section = existingListItems.findFirst{$0.section.name == sectionName}.map {item in  // it's is a bit more practical to use plain models and map than adding initialisers to db objs
//                                return item.section
//                                } ?? { // section not existent create a new one
//                                    
//                                    let sectionCount = getOrderForNewSection(existingListItems)
//                                    
//                                    // if we already created a new section in the memory cache use that one otherwise create (create case normally only if memcache is disabled)
//                                    return memoryCacheItemsDict?[StoreProduct.uniqueDictKey(prototype.product.product.product.item.name, brand: prototype.product.product.product.brand, store: prototype.product.store, unit: prototype.product.product.unit, baseQuantity: prototype.product.product.baseQuantity)]?.section ?? Section(uuid: NSUUID().uuidString, name: sectionName, color: prototype.targetSectionColor, list: list, order: ListItemStatusOrder(status: status, order: sectionCount))
//                                }()
//                            
//                            // determine list item order and init/update the map with list items count / section as side effect (which is used to determine the order of the next item)
//                            let listItemOrder: Int = {
//                                if let sectionCount = sectionCountNewItemsDict[section.uuid] { // if already initialised (existing items count) increment 1 (for new item we are adding)
//                                    let order = sectionCount + 1
//                                    sectionCountNewItemsDict[section.uuid] = order
//                                    return order
//                                    
//                                } else { // init to existing count
//                                    let existingCountInSection = getItemCountInSection(listItems: existingListItems, section: section, status: status)
//                                    sectionCountNewItemsDict[section.uuid] = existingCountInSection
//                                    return existingCountInSection
//                                }
//                            }()
//                            
//                            let uuid = memoryCacheItemsDict?[StoreProduct.uniqueDictKey(prototype.product.product.product.item.name, brand: prototype.product.product.product.brand, store: prototype.product.store, unit: prototype.product.product.unit, baseQuantity: prototype.product.product.baseQuantity)]?.uuid ?? NSUUID().uuidString
//                            
//                            
//                            // create the list item and save it
//                            // memcache uuid: if we created a new listitem in memcache use this uuid so our data is consistent mem/db
//                            let listItem = ListItem(
//                                uuid: uuid,
//                                product: prototype.product,
//                                section: section,
//                                list: list,
//                                note: note,
//                                statusOrder: ListItemStatusOrder(status: status, order: listItemOrder),
//                                statusQuantity: ListItemStatusQuantity(status: status, quantity: prototype.quantity)
//                            )
//                            
//                            logger.v("item doesn't exist, created: \(listItem)")
//                            
//                            realm.add(listItem, update: true) // this should be update false, but update true is a little more "safer" (e.g uuid clash?), TODO review, maybe false better performance
//                            
//                            savedListItems.append(listItem)
//                        }
//                    }
//                    
//                    return (success: true, listItemUuids: savedListItems.map{$0.uuid}) // map to uuid fixes Realm acces in incorrect thread exceptions
//                })
//            }
//            
//        }) {[weak self] (bgResultMaybe: BGResult?) -> Void in
//                
//            if let bgResult = bgResultMaybe { // bg ran successfully
//                
//                if self?.memProvider.valid ?? false {
//                    // bgResult & mem valid -> do nothing: added item was returned to handler already (after add to mem provider), no need to return it again
//                    
//                } else {
//                    // mem provider is not enabled - controller is waiting for result - return it
//                    do {
//                        let realm = try Realm()
//                        realm.refresh() // for the data we just wrote in background thread to become available
//
//                        let filter: String = ListItem.createFilterForUuids(bgResult.listItemUuids)
//                        let listItems: [ListItem] = realm.objects(ListItem.self).filter(filter).toArray()
//
//                        handler(ProviderResult(status: .success, sucessResult: listItems))
//
//                    } catch let e {
//                        logger.e("Error retrieving saved list items with uuids: \(bgResultMaybe?.listItemUuids), error: \(e)")
//                        handler(ProviderResult(status: .databaseUnknown))
//                    }
//                }
//                
//                //                        if let addedListItem = bgResult.listItem { // bg returned a list item
//                //                            handler(ProviderResult(status: .Success, sucessResult: bgResult.addedListItem))
//                //
//                //
//                //                        } else {
//                //                            // bg was successful but didn't return a list item, this happens when the item was returned from the memory cache
//                //                            // in this case we do nothing - the client already has the added object
//                //                        }
//                
//                
//                // add to server
//                // Disabled while impl. realm sync
////                self?.remoteProvider.add(bgResult.listItems) {remoteResult in
////                    if let remoteListItems = remoteResult.successResult {
////                        self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
////                        }
////                    } else {
////                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[ListItem]>) in
////                            logger.e("Remote call no success: \(remoteResult)")
////                            self?.memProvider.invalidate()
////                            handler(result)
////                        })
////                    }
////                }
//                
//            } else { // there was a database error
//                handler(ProviderResult(status: .databaseUnknown))
//            }
//        }
    }

    func addListItem(_ product: QuantifiableProduct, status: ListItemStatus, section: Section, quantity: Float, list: List, note: String? = nil, order orderMaybe: Int? = nil, storeProductInput: StoreProductInput?, token: RealmToken?, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        // for now call the other func, which will fetch the section again... review if this is bad for performance otherwise let like this
        addListItem(product, status: status, sectionName: section.name, sectionColor: section.color, quantity: quantity, list: list, note: note, order: orderMaybe, storeProductInput: storeProductInput, token: token, handler)
    }
    
    // Common code for update single and batch list items switch status (in case of single listItems contains only 1 element)
    // Switches in memory status of listItems to target status, also updates order & quantity for which it loads list items from database
    // param: orderInDstStatus: To override default dst order with a manual order. This is used for undo cell, where we want to the item to be inserted back at the original position.
    fileprivate func switchStatusInsertInDst(_ listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, orderInDstStatus: Int? = nil, remote: Bool, _ handler: @escaping ((switchedItems: [ListItem], storedItems: [ListItem])?) -> Void) {

        // Outdated implementation
//        self.listItems(list, sortOrderByStatus: status, fetchMode: .memOnly) {result in // TODO review .First suitable here
//
//            if let storedListItems = result.sucessResult {
//
//                // Update quantity and order field - by changing quantity we are moving list items from one status to another
//                // we append the items at the end of the dst section (order == section.count)
//                var dstSectionsDict = storedListItems.sectionCountDict(status)
//                for listItem in listItems {
//
//                    let listItemOrderInDstStatus: Int? = orderInDstStatus ?? (listItem.hasStatus(status) ? listItem.order(status) : nil) // catch this before switching quantity
//
//                    listItem.switchStatusQuantityMutable(status1, targetStatus: status)
//                    if let sectionCount = dstSectionsDict[listItem.section.uuid] { // TODO rename this sounds like count of sections but it's count of list item in sections
//
//                        // If there's already a list item in the target status don't update order. If there's not, set order to last item in section
//                        let listItemOrder: Int = listItemOrderInDstStatus ?? sectionCount
//
//                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: listItemOrder))
//                        dstSectionsDict[listItem.section.uuid]! += 1 // we are adding an item to section - increment count for possible next item
//
//                    } else { // item's section is not in target status - set order 0 (first item in section) and add section to the dictionary
//                        listItem.updateOrderMutable(ListItemStatusOrder(status: status, order: 0))
//                        // update order such that section is appended at the end
//                        listItem.section.updateOrderMutable(ListItemStatusOrder(status: status, order: dstSectionsDict.count))
//                        dstSectionsDict[listItem.section.uuid] = 1 // we are adding an item to section - items count is 1
//                    }
//                    // this is not really necessary, but for consistency - reset order to 0 in the src status.
//                    listItem.updateOrderMutable(ListItemStatusOrder(status: status1, order: 0))
//
////                    logger.d("List item after status update: \(listItem.quantityDebugDescription)")
//                }
//
//                handler((switchedItems: listItems, storedItems: storedListItems.toArray()))
//
//            } else {
//                logger.e("Didn't get listItems: \(result.status), can't switch")
//                handler(nil)
//            }
//        }
    }

    // Websocket list item switch
    func switchStatusLocal(_ listItemUuid: String, status1: ListItemStatus, status: ListItemStatus, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        findListItem(listItemUuid) {[weak self] result in
            if let listItem = result.sucessResult {
                self?.switchStatus(listItem, list: listItem.list, status1: status1, status: status, remote: false, handler)
            } else {
                logger.d("Didn't find list item to be switched, uuid: \(listItemUuid), status1: \(status1), status: \(status)")
            }
        }
    }
    
    // param: orderInDstStatus: To override default dst order with a manual order. This is used for undo cell, where we want to the item to be inserted back at the original position.    
    func switchStatus(_ listItem: ListItem, list: List, status1: ListItemStatus, status: ListItemStatus, orderInDstStatus: Int? = nil, remote: Bool, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        
//        logger.d("Switching status from \(listItem.product.product.name) from status \(status1) to \(status)")
        
        switchStatusInsertInDst([listItem], list: list, status1: status1, status: status, orderInDstStatus: orderInDstStatus, remote: remote) {switchResult in
            
            if let (switchedItems, storedListItems) = switchResult { // here switchedItems is a 1 element array, containing the switched listItem
                
                // Update src items order. We have to shift the followers in the same section or, if the section is empty after we switch item the order of the follower sections - for simplicity we just update the order field of all src list items and sections.
                let allItemsToUpdate: [ListItem] = {
                    if let switchedItem = switchedItems.first {
                        var items = storedListItems
                        _ = items.update(switchedItem) // Update switched item in this array such that it's count in src is 0 and reorder works correctly
                        items.sortAndUpdateOrderFieldsMutating(status1) // This filters and sorts by src status, iterates through them setting order to index.
                        return switchedItems + items // Add again the switched list item to the array (it's lost when we filter by src status)
                    } else {
                        logger.e("Invalid state: there should be a switched list item")
                        return switchedItems
                    }
                }()
                
//                logger.d("After switching: \(listItem.product.product.name), writing updated items to db: \(allItemsToUpdate)")
                
                // Persist changes. If mem cached is enabled this calls handler directly after mem cache is updated and does db update in the background.
                self.updateLocal(allItemsToUpdate, handler: {result in
                    
                    if result.success {
                        if let listItem = switchedItems.first {
                            handler(ProviderResult(status: .success, sucessResult: listItem))
                        } else {
                            logger.e("Invalid statue: No list item. We should have the switched list item here.")
                            handler(ProviderResult(status: .unknown))
                        }
                        
                    } else {
                        handler(ProviderResult(status: result.status))
                    }
                    
                    }, onFinishLocal: {[weak self] in
                    
                    if remote {
                        let statusUpdate = ListItemStatusUpdate(src: status1, dst: status)
                        self?.remoteProvider.updateStatus(listItem, statusUpdate: statusUpdate) {remoteResult in
                            if let remoteUpdateResult = remoteResult.successResult {
                                DBProv.listItemProvider.storeRemoteListItemSwitchResult(statusUpdate, result: remoteUpdateResult) {success in
                                    if !success {
                                        logger.e("Couldn't store remote switch result in database: \(remoteResult) item: \(listItem)")
                                    }
                                }
                                
                            } else {
                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                                    logger.e("Remote call no success: \(remoteResult) item: \(listItem)")
                                    self?.memProvider.invalidate()
                                    handler(ProviderResult<ListItem>(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                                })
                            }
                        }
                    }
                })
            } else {
                logger.e("Stored list items returned nil")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // Switches status of passed items in memory and returns them. For this we loads the currrent list items either from memory or database if mem cache not available.
    fileprivate func getSwitchedItemsForSwitchAll(_ listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void) {
        
        switchStatusInsertInDst(listItems, list: list, status1: status1, status: status, remote: remote) {switchResult in
            
            if let (switchedItems, _) = switchResult {
                
                // all the list items in src status are gone - set src order to 0, just for consistency
                switchedItems.forEach({listItem -> Void in
                    listItem.updateOrderMutable(ListItemStatusOrder(status1, order: 0))
                    listItem.section.updateOrderMutable(ListItemStatusOrder(status1, order: 0)) // this may update sections multiple times but it doesn't matter
                })
                
                handler(ProviderResult(status: .success, sucessResult: switchedItems))

            } else {
                logger.e("Stored list items returned nil")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // Websockets: stores inventory and history items corresponding to buy result and moves item to stash
    // For now not in a transaction, not very critical as this is only a matching operation and if the user reloads the list the data will be consistent again. Of course, before reloading the list the behaviour looks wrong to the user and using the list in this state leads to more weirdness. TODO! do this also in a transaction.
    func storeBuyCartResult(_ switchedResult: RemoteBuyCartResult, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        
        let listItemUuids = switchedResult.switchedItems.map{$0.uuid}
        Prov.listItemsProvider.listItems(listItemUuids) {listItemsResult in
            
            if let listItems = listItemsResult.sucessResult {
                
                // Note: assumes all the items belong to the same list
                if let list = listItems.first?.list {
                    
                    let (inventoryItems, historyItems) = InventoryItemMapper.itemsWithRemote(switchedResult.inventoryAndHistoryItems)
                    Prov.inventoryItemsProvider.addToInventoryLocal(inventoryItems, historyItems: historyItems, dirty: false) {saveInventoryAndHistoryItemsResult in
                        
                        if saveInventoryAndHistoryItemsResult.success {
                            Prov.listItemsProvider.switchAllToStatus(listItems, list: list, status1: .done, status: .stash, remote: false) {switchListItemsResult in
                                if switchListItemsResult.success {
                                    handler(ProviderResult(status: .success))
                                } else {
                                    logger.e("Error switching list items: \(switchListItemsResult)")
                                    handler(ProviderResult(status: .unknown))
                                }
                            }
                            
                        } else {
                            logger.e("Error saving inventory and history items: \(saveInventoryAndHistoryItemsResult)")
                            handler(ProviderResult(status: .unknown))
                        }
                    }
                    
                } else {
                    logger.e("None of the items to be switched is in the list") // this is not entirely impossible but extremely unlikely
                    handler(ProviderResult(status: .success)) // For now just error log, maybe later we should return error status also
                }
            } else {
                logger.e("Error retrieving list items: \(listItemsResult)")
                handler(ProviderResult(status: listItemsResult.status, sucessResult: nil, error: listItemsResult.error, errorObj: listItemsResult.errorObj))
            }
        }
    }
    
    func buyCart(_ listItems: [ListItem], list: List, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        
        // Generate inventory/history items first because list items may change
        let inventoryAndHistoryItemsInput = listItems.map{ProductWithQuantityInput(product: $0.product, quantity: $0.doneQuantity)}

        // If the todo list is empty, move items immediately to todo, otherwise to stash
        listItemCount(.todo, list: list, fetchMode: .memOnly) {[weak self] result in
            if let todoItemsCount = result.sucessResult {
                
                let todoISEmpty: Bool = todoItemsCount == 0
                
                let targetStatus: ListItemStatus = todoISEmpty ? .todo : .stash
            
                self?.listItems(list, sortOrderByStatus: .stash, fetchMode: .memOnly) {stashListItems in
                    
                    self?.getSwitchedItemsForSwitchAll(listItems, list: list, status1: .done, status: targetStatus, remote: remote) {result in
                        
                        if let switchedItems = result.sucessResult {
                            
                            DBProv.listItemProvider.buyCart(list.uuid, switchedItems: switchedItems, inventory: list.inventory, itemInputs: inventoryAndHistoryItemsInput, remote: remote, {[weak self] dbBuyResult -> Void in
                                if let inventoryWithHistoryItems = dbBuyResult.sucessResult {
                                    
                                    // Called after we reset stash items, in case when todo list is left empty or immediately in case where the todo list is left non empty
                                    func afterMaybeResetStash(_ resettedStashItems: [ListItem]? = nil) {
                                
                                        handler(ProviderResult(status: .success))
                                        
                                        self?.remoteProvider.buyCart(list.uuid, inventoryItems: inventoryWithHistoryItems) {remoteResult in
                                            
                                            if let timestamp = remoteResult.successResult {
                                                
                                                DBProv.listItemProvider.storeBuyCartResult(listItems, inventoryWithHistoryItems: inventoryWithHistoryItems, lastUpdate: timestamp) {success in
                                                    if !success {
                                                        logger.e("Couldn't store remote all switch result in database: \(remoteResult) items: \(listItems)")
                                                    }
                                                }
                                                
                                                if let resettedStashItems = resettedStashItems {
                                                    // Now that remote buyCart transaction finished, switch the stash also in remote.
                                                    // TODO!!! -- this should be in the same transaction from buyCart (in client and server) so this additional call is not necessary. Also ensure consistency with the client and server switch.
                                                    Prov.listItemsProvider.switchAllToStatus(resettedStashItems, list: list, status1: .stash, status: .todo, remote: true) {result in
                                                        if !result.success {
                                                            logger.e("Error switching stash items (remote) after buyCart: \(result)")
                                                        }
                                                    }
                                                }

                                                
                                            } else {
                                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                                                    logger.e("Remote call no success: \(remoteResult) items: \(listItems)")
                                                    self?.memProvider.invalidate()
                                                    handler(result)
                                                })
                                            }
                                        }
                                    }
                                    
                                    
                                    if todoISEmpty {
                                        // Do the possible stash emptying separately (not in the same transaction as switching items and inventory, history - reason is that switching items loads stored items from db, since we don't store the items until buyCart we can't use this method again to save the possible stash-to-todo switch. So for now we do this after the buy transaction, if it fails it's not critical if the stash items keep in the stash.
                                        self?.listItems(list, sortOrderByStatus: .stash, fetchMode: .memOnly) {listItemsAfterSwitchResult in
                                            if let listItemsAfterSwitch = listItemsAfterSwitchResult.sucessResult {
                                                let stashItems = listItemsAfterSwitch.filter{$0.hasStatus(.stash)}
            
                                                // We don't send it to remote because don't have called buyCart yet, that should come first (stash items should be appended after the cart items, like in client). The reason we don't have called buyCart is that we want to first to all client side operations in order to return to controller as soon as possible.
                                                Prov.listItemsProvider.switchAllToStatus(Array(stashItems), list: list, status1: .stash, status: .todo, remote: false) {result in
                                                    if result.success {
                                                        afterMaybeResetStash(Array(stashItems))
                                                    } else {
                                                        logger.e("Couldn't reset stash list items")
                                                        handler(ProviderResult(status: .databaseUnknown))
                                                    }
                                                }
                                            }
                                        }
                                        
                                    } else {
                                        afterMaybeResetStash()
                                    }
                                    
                                } else {
                                    logger.e("db buy cart didn't return items") // this should not happen as we should not call this method with an empty cart, and if there are cart items there must be inventory/history items.
                                    handler(ProviderResult(status: .unknown))
                                }
                            })
                            
                        } else {
                            logger.e("No switched items")
                            handler(ProviderResult(status: .unknown))
                        }
                    }
                }

            } else {
                logger.e("Couldn't get items count")
                handler(ProviderResult(status: .databaseUnknown))
            }
            
        }
    }
    
    // IMPORTANT: Assumes that the passed list items are ALL the existing list items in src status. If this is not the case, the remaining items/sections in src status will likely be left with a wrong order.
    // Passes to handler the switched list items (state as stored in local db - no remote things like lastUpdate timestamp)
    func switchAllToStatus(_ listItems: [ListItem], list: List, status1: ListItemStatus, status: ListItemStatus, remote: Bool, _ handler: @escaping (ProviderResult<[ListItem]>) -> Void) {
        
        getSwitchedItemsForSwitchAll(listItems, list: list, status1: status1, status: status, remote: remote) {result in
            
            if let switchedItems = result.sucessResult {
                
                // Persist changes. If mem cached is enabled this calls handler directly after mem cache is updated and does db update in the background.
                self.updateLocal(switchedItems, handler: {result in
                    if result.success {
                        handler(ProviderResult(status: .success, sucessResult: switchedItems))
                    } else {
                        handler(ProviderResult(status: result.status, sucessResult: nil, error: result.error, errorObj: result.errorObj))
                    }
                    
                }, onFinishLocal: {[weak self] in
                    
                    if remote {
                        let statusUpdate = ListItemStatusUpdate(src: status1, dst: status)
                        self?.remoteProvider.updateAllStatus(list.uuid, statusUpdate: statusUpdate) {remoteResult in
                            if let remoteUpdateResult = remoteResult.successResult {
                                DBProv.listItemProvider.storeRemoteAllListItemSwitchResult(statusUpdate, result: remoteUpdateResult) {success in
                                    if !success {
                                        logger.e("Couldn't store remote all switch result in database: \(remoteResult) items: \(listItems)")
                                    }
                                }
                                
                            } else {
                                DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<[ListItem]>) in
                                    logger.e("Remote call no success: \(remoteResult) items: \(listItems)")
                                    self?.memProvider.invalidate()
                                    handler(result)
                                })
                            }
                        }
                    }
                })
                
            } else {
                logger.e("No switched items")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func switchAllStatusLocal(_ result: RemoteSwitchAllListItemsLightResult, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listProvider.loadList(result.update.listUuid) {listMaybe in
            if let list = listMaybe {
                DBProv.listItemProvider.loadListItems(list.uuid) {(listItems: Results<ListItem>?) in
                    
                    guard let listItems = listItems else {logger.e("No items"); handler(ProviderResult(status: .unknown)); return}
                    
                    Prov.listItemsProvider.switchAllToStatus(listItems.toArray(), list: list, status1: result.update.srcStatus, status: result.update.dstStatus, remote: false) {switchResult in
                        if let switchedListItems = switchResult.sucessResult {
                            handler(ProviderResult(status: .success))
                            
                            DBProv.listItemProvider.storeWebsocketAllListItemSwitchResult(switchedListItems, lastUpdate: result.lastUpdate) {success in
                                if success {
                                    logger.v("Updated timestamps")
                                } else {
                                    logger.e("Counldn't update timestamps")
                                }
                            }
                        } else {
                            logger.e("No switched list items, can't store timestamps")
                            handler(ProviderResult(status: switchResult.status, sucessResult: nil, error: switchResult.error, errorObj: switchResult.errorObj))
                        }
                    }
                }
            } else {
                logger.d("List to switch items not found: \(result.update.listUuid)")
                handler(ProviderResult(status: .success)) // list can be removed shortly before we get the message so this is not an error
            }
        }
    }


    // Helper for common code of status switch update, order update and full update - the only difference of these method is the remote call, switch and order use optimised services.
    // The local call is in all cases a full update.
    // The local call could principially also be optimised but don't see it's worth it, probably the performance is not very different than updating the whole object.
    fileprivate func updateLocal(_ listItems: [ListItem], remote: Bool = true, handler: @escaping (ProviderResult<Any>) -> Void, onFinishLocal: @escaping VoidFunction) {
        let memUpdated = memProvider.updateListItems(listItems)
        if memUpdated {
            handler(ProviderResult(status: .success))
        }
        
        self.dbProvider.updateListItems(listItems, handler: {[weak self] saved in
            if saved {
                if !memUpdated {
                    handler(ProviderResult(status: .success))
                }
            } else {
                handler(ProviderResult(status: .databaseUnknown))
                self?.memProvider.invalidate()
            }
          
            onFinishLocal()
        })
    }
    
    func update(_ listItems: [ListItem], remote: Bool = true, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        
        self.updateLocal(listItems, handler: handler, onFinishLocal: {
//            if remote {
//                self?.remoteProvider.update(listItems) {remoteResult in
//                    if let remoteListItems = remoteResult.successResult {
//                        self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            logger.e("Remote call no success: \(remoteResult) items: \(listItems)")
//                            self?.memProvider.invalidate()
//                            handler(result)
//                        })
//                    }
//                }
//            }
        })
    }
    
    func update(_ listItem: ListItem, remote: Bool = true, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        update([listItem], remote: remote, handler)
    }
    
    func updateListItemsOrder(_ listItems: [ListItem], status: ListItemStatus, remote: Bool = true, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        
        self.updateLocal(listItems, handler: handler, onFinishLocal: {[weak self] in
            if remote {
                self?.remoteProvider.updateListItemsOrder(listItems, status: status) {remoteResult in
                    if remoteResult.success {
                        // TODO see note in RemoteListItemProvider.updateListItemsTodoOrder
//                        self?.dbProvider.updateLastSyncTimeStamp(remoteListItems) {success in
//                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            logger.e("Remote call no success: \(remoteResult) items: \(listItems)")
                            self?.memProvider.invalidate()
                            handler(result)
                        })
                    }
                }
            }
        })
    }
    
    func updateListItemsOrderLocal(_ orderUpdates: [RemoteListItemReorder], sections: [Section], status: ListItemStatus, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.listItemProvider.updateListItemsOrderLocal(orderUpdates, sections: sections, status: status) {success in
            if success {
                Prov.listItemsProvider.invalidateMemCache()
                handler(ProviderResult(status: .success))
            } else {
                logger.e("Couldn't store remote list items order update")
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    // TODO!!!! remote? why did this service not have remote before, forgot or we don't need it there?
    func increment(_ listItem: ListItem, status: ListItemStatus, delta: Float, remote: Bool, tokens: [NotificationToken], _ handler: @escaping (ProviderResult<ListItem>) -> ()) {
        
        // Get item from database with updated quantityDelta
        // The reason we do this instead of using the item parameter, is that later doesn't always have valid quantityDelta
        // -> When item is incremented we set back quantityDelta after the server's response, this is NOT communicated to the item in the view controller (so on next increment, the passed quantityDelta is invalid)
        // Which is ok. because the UI must not have logic related with background server update
        // Cleaner would be to create a lightweight InventoryItem version for the UI - without quantityDelta, etc. But this adds extra complexity
        
        let memIncremented = memProvider.increment(listItem, quantity: ListItemStatusQuantity(status: status, quantity: delta))
        if let memIncremented = memIncremented {
            
            DispatchQueue.main.async(execute: { // since the transaction is executed in the background we have to return to main thread here
                handler(ProviderResult(status: .success, sucessResult: memIncremented))
            })
        }
        dbProvider.incrementListItem(listItem, delta: delta, status: status, tokens: tokens) {listItemMaybe in
            
            if memIncremented == nil { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                if let listItem = listItemMaybe {
                    handler(ProviderResult(status: .success, sucessResult: listItem))
                } else {
                    handler(ProviderResult(status: .databaseSavingError))
                }
            }
            
//            if remote {
//                self?.remoteProvider.incrementListItem(listItem, delta: delta, status: status) {remoteResult in
//                    if let incrementResult = remoteResult.successResult {
//                        self?.dbProvider.updateListItemWithIncrementResult(incrementResult) {success in
//                            if !success {
//                                logger.e("Couldn't save increment result for item: \(listItem), remoteResult: \(remoteResult)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<ListItem>) in
//                            logger.e("Remote call no success: \(remoteResult) item: \(listItem)")
//                            self?.memProvider.invalidate()
//                            handler(result)
//                        })
//                    }
//                }
//            }
        }
    }
    
    // only db no memory cache or remote, this is currently used only by websocket update (when receive websocket increment, fetch inventory item in order to increment it locally)
    fileprivate func findListItem(_ uuid: String, _ handler: @escaping (ProviderResult<ListItem>) -> ()) {
        DBProv.listItemProvider.findListItem(uuid) {listItemMaybe in
            if let listItem = listItemMaybe {
                handler(ProviderResult(status: .success, sucessResult: listItem))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    // TODO this can be optimised, such that we don't have to prefetch the item but increment directly at least in memory
    func increment(_ increment: RemoteListItemIncrement, remote: Bool, _ handler: @escaping (ProviderResult<ListItem>) -> Void) {
        findListItem(increment.uuid) {[weak self] result in
            if let listItem = result.sucessResult {
                
                self?.increment(listItem, status: increment.status, delta: increment.delta, remote: remote, tokens: []) {result in

                    if let statusQuantity = result.sucessResult {
                        handler(ProviderResult(status: .success, sucessResult: statusQuantity))
                    } else {
                        handler(ProviderResult(status: .databaseSavingError))
                    }
                }
                
            } else {
                logger.d("Didn't find inventory item to increment, for: \(increment)")
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    func listItemCount(_ status: ListItemStatus, list: List, fetchMode: ProviderFetchModus = .first, _ handler: @escaping (ProviderResult<Int>) -> Void) {
        let countMaybe = memProvider.listItemCount(status, list: list)
        if let count = countMaybe {
            handler(ProviderResult(status: .success, sucessResult: count))
            if fetchMode == .memOnly {
                return
            }
        }
        
        dbProvider.listItemCount(status, list: list) {dbCountMaybe in
            if let dbCount = dbCountMaybe {
                // if for some reason the count in db is different than in memory return it again so the interface can update
                // (only used for fetchmode .Both)
                if (countMaybe.map{$0 != dbCount} ?? true) {
                    handler(ProviderResult(status: .success, sucessResult: dbCount))
                }
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // MARK: - Memory cache
    
    func invalidateMemCache() {
        memProvider.invalidate()
    }
    
    func removeSectionFromListItemsMemCacheIfExistent(_ sectionUuid: String, listUuid: String?, handler: @escaping (ProviderResult<Any>) -> Void) {
        if memProvider.enabled {
            let success = memProvider.removeSection(sectionUuid, listUuid: listUuid)
            if !success {
                logger.e("Mem cache section removal returned false: sectionUuid: \(sectionUuid), listUuid: \(String(describing: listUuid))")
            }
            handler(ProviderResult(status: .success))
        } else {
            handler(ProviderResult(status: .success))
        }
    }
    
    
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // New
    
    func addNew(listItemInput: ListItemInput, list: List, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<AddListItemResult>) -> Void) {
        if let tuple = DBProv.listItemProvider.addSync(listItemInput: listItemInput, list: list, status: status, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: tuple))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }

    // TODO rename
    func addNewStoreProduct(listItemInput: ListItemInput, list: List, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<(StoreProduct, Bool)>) -> Void) {
        if let storeProduct = DBProv.listItemProvider.addStoreProductSync(listItemInput: listItemInput, list: list, status: status, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: storeProduct))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func addNew(listItemInputs: [ListItemInput], list: List, status: ListItemStatus, realmData: RealmData?, _ handler: @escaping (ProviderResult<[(listItem: ListItem, isNew: Bool)]>) -> Void) {
        if let tuples = DBProv.listItemProvider.addSync(listItemInputs: listItemInputs, list: list, status: status, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: tuples))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func addNew(listItem: ListItem, section: Section, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        fatalError("does this need to be in provider (probably only in realm provider) if no remove")
        //DBProv.listItemProvider.addSync(listItem: listItem, section: section, notificationToken: notificationToken) {success in
        //    handler(ProviderResult(status: success ? .success : .databaseUnknown))
        //}
    }
    
    // Quick add
    // TODO rename add or increment
    // TODO maybe remove references to section, list of list items so we don't have to pass them here
    func addNew(quantifiableProduct: QuantifiableProduct, store: String, list: List, quantity: Float, note: String?, status: ListItemStatus, realmData: RealmData, _ handler: @escaping (ProviderResult<AddListItemResult>) -> Void) {
       
        if let tuple = DBProv.listItemProvider.addSync(quantifiableProduct: quantifiableProduct, store: store, refPrice: nil, refQuantity: nil, list: list, quantity: quantity, note: note, status: status, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: tuple))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }

    func updateNew(_ listItemInput: ListItemInput, updatingListItem: ListItem, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<(UpdateListItemResult)>) -> Void) {
        
        switch DBProv.listItemProvider.update(listItemInput, updatingListItem: updatingListItem, status: status, list: list, realmData: realmData) {
        case .ok(let updateResult): handler(ProviderResult(status: .success, sucessResult: updateResult))
        case .err(let e):
            logger.e("Error in update list items: \(e)")
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    /////////////////////////////////////////////////////////////
    // Cart
    
    
    func addToCart(quantifiableProduct: QuantifiableProduct, store: String, list: List, quantity: Float, realmData: RealmData, _ handler: @escaping (ProviderResult<AddCartListItemResult>) -> Void) {
        
        if let tuple = DBProv.listItemProvider.addToCartSync(quantifiableProduct: quantifiableProduct, store: store, list: list, quantity: quantity, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: tuple))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    
    func deleteNew(indexPath: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<DeleteListItemResult>) -> Void) {
        if let result = DBProv.listItemProvider.deleteSync(indexPath: indexPath, status: status, list: list, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: result))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func move(from: IndexPath, to: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<MoveListItemResult>) -> Void) {
        if let result = DBProv.listItemProvider.move(from: from, to: to, status: status, list: list, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: result))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func moveCartOrStash(from: IndexPath, to: IndexPath, status: ListItemStatus, list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        if let _ = DBProv.listItemProvider.moveCartOrStash(from: from, to: to, status: status, list: list, realmData: realmData) {
            handler(ProviderResult(status: .success))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
        
    func calculateCartStashAggregate(list: List, _ handler: @escaping (ProviderResult<ListItemsCartStashAggregate>) -> Void) {
        let listUuid = list.uuid // We retrieve list in background, to not get Realm thread exception
        background({
            return DBProv.listItemProvider.calculateCartStashAggregate(listUuid: listUuid)
        }) {aggregateMaybe in
            if let aggregate = aggregateMaybe {
                handler(ProviderResult(status: .success, sucessResult: aggregate))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // MARK: - Buy
    
    func buyCart(list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.listItemProvider.buyCart(list: list, realmData: realmData)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }
    
    // MARK: - Switch
        
    func switchTodoToCartSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<SwitchListItemResult>) -> Void) {
        if let result = DBProv.listItemProvider.switchTodoToCartSync(listItem: listItem, from: from, realmData: realmData) {
            handler(ProviderResult(status: .success, sucessResult: result))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func switchCartToStashSync(listItems: [ListItem], list: List, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.listItemProvider.switchCartToStashSync(listItems: listItems, list: list, realmData: realmData)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }
    
    func switchStashToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.listItemProvider.switchStashToTodoSync(listItem: listItem, from: from, realmData: realmData)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }
    
    func switchCartToTodoSync(listItem: ListItem, from: IndexPath, realmData: RealmData, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.listItemProvider.switchCartToTodoSync(listItem: listItem, from: from, realmData: realmData)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }

    func removePossibleSectionDuplicates(list: List, status: ListItemStatus, _ handler: @escaping (ProviderResult<Bool>) -> Void) {
        let dbResult = DBProv.listItemProvider.removePossibleSectionDuplicates(list: list, status: status)
        let providerResult: ProviderResult<Bool> = {
            switch dbResult.status {
            case .success: return ProviderResult(status: .success, sucessResult: false)
            case .removedADuplicate: return ProviderResult(status: .success, sucessResult: true)
            default: return ProviderResult(status: .databaseUnknown)
            }
        } ()
        handler(providerResult)
    }
}
