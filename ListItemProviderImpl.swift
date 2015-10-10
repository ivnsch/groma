//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemProviderImpl: ListItemProvider {

    let dbProvider = RealmListItemProvider()
    let remoteProvider = RemoteListItemProvider()
    let memProvider = MemListItemProvider(enabled: true)
    
    func product(name: String, handler: ProviderResult<Product> -> ()) {
        dbProvider.loadProductWithName(name) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }

    func products(handler: ProviderResult<[Product]> -> ()) {
        self.dbProvider.loadProducts {dbProducts in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbProducts))
        }
    }

    func add(product: Product, handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product]) {saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProvider.loadProductSuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }

    func sectionSuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProvider.loadSectionSuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }
    
    func listItems(list: List, fetchMode: ProviderFetchModus = .Both, _ handler: ProviderResult<[ListItem]> -> ()) {

        let memListItemsMaybe = memProvider.listItems(list)
        if let memListItems = memListItemsMaybe {
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: memListItems))
            if fetchMode == .MemOnly {
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
                    let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems, list: list)
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (dbListItems != listItemsWithRelations.listItems) { // note: listItemsWithRelations.listItems is already sorted by order
                        self?.dbProvider.saveListItems(listItemsWithRelations) {saved in
                            
                            if fetchMode == .Both {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: listItemsWithRelations.listItems))
                            }
                            self?.memProvider.overwrite(listItemsWithRelations.listItems)
                        }
                    }
                    
                } else {
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        })
    }
    
    func remove(listItem: ListItem, _ handler: ProviderResult<Any> -> ()) {
        
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
            
            self?.remoteProvider.remove(listItem) {result in
                if !result.success {
                    print("Error: Removing listItem: \(listItem)")
                }
            }
        })
    }
    
    func remove(section: Section, _ handler: ProviderResult<Any> -> ()) {
        memProvider.invalidate()
        self.dbProvider.remove(section) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func remove(list: List, _ handler: ProviderResult<Any> -> ()) {
        memProvider.invalidate()
        self.dbProvider.remove(list) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func add(listItem: ListItem, _ handler: ProviderResult<Any> -> ()) {

        let memAdded = memProvider.addListItem(listItem)
        if memAdded {
            handler(ProviderResult(status: .Success))
        }
        
        // TODO local database first then server
        // and review carefully what happens if adding fails after memory cache is updated
        
        
        // return the saved object, to get object with generated id
        
        // for now do remote first. Imagine we do coredata first, user adds the list and then a lot of items to it and server fails. The list with all items will be lost in next sync.
        // we can do special handling though, like show an error message when server fails and remove the list which was just added, and/or retry server. Or use a flag "synched = false" which tells us that these items should not be removed on sync, similar to items which were added offline. Etc.
        self.remoteProvider.add(listItem, handler: {[weak self] remoteResult in
            
            if remoteResult.success {
                self?.dbProvider.saveListItem(listItem) {saved in // currently the item returned by server is identically to the one we sent, so we just save our local item
                    let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status) // return status of remote, for now we don't consider save to db critical - TODO review when focusing on offline mode - in this case at least we have to skip the remote call and db operation is critical
                    if !memAdded { // we assume the database result is always == mem result, so if returned from mem already no need to return from db
                        handler(ProviderResult(status: providerStatus))
                    }
                }
                
            } else {
                DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                self?.memProvider.invalidate()
            }
        })
    }
    
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int? = nil, possibleNewSectionOrder: Int, _ handler: ProviderResult<ListItem> -> ()) {

        self.listItems(list, fetchMode: .First) {result in // TODO fetch items only when order not passed, because they are used only to get order
            
            if let listItems = result.sucessResult {
                
                let order = orderMaybe ?? listItems.count
                
                // get product and section uui if they're already in the local db (remember that we assign uuid in the client so this logic has to be in the client)
                self.loadProduct(listItemInput.name, list: list) {productTry in
                    
                    // load product and update or create one
                    // if we find a product with the name we update it - this is for the case the user changes the price for an existing product while adding an item
                    let productUuid: String = {
                        if let existingProduct = productTry.sucessResult {
                            return existingProduct.uuid
                        } else {
                            return NSUUID().UUIDString
                        }
                    }()
                    let product = Product(uuid: productUuid, name: listItemInput.name, price: listItemInput.price)

                    // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
                    // There is no name update since here we have only name so either the name is in db or it's not, if it's not insert a new section
                    self.loadSection(listItemInput.section, list: list) {result in
                        
                        let section: Section = {
                            if let existingSection = result.sucessResult {
                                return existingSection
                            } else {
                                return Section(uuid: NSUUID().UUIDString, name: listItemInput.section, order: possibleNewSectionOrder)
                            }
                        }()
                        
                        // WARN / TODO: we didn't do any local db udpates! currently this is done after we receive the response off addItem of the server, with the server object
                        // in order to support offline use this has to be changed either
                        // 1. do the update before calling the service. If service returns an error then remove?
                        // 2. do the update before calling the service, and add flag not synched (etc)
                        // 3. more ideas?
                        let listItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
                        self.add(listItem, {result in
                            if result.success {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: listItem))
                            } else {
                                handler(ProviderResult(status: result.status))
                            }
                        })
                    }
                }
            }
        }
    }
    
    private func loadSection(name: String, list: List, handler: ProviderResult<Section> -> ()) {
        self.dbProvider.loadSectionWithName(name) {dbSectionMaybe in
            if let dbSection = dbSectionMaybe {
                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSection))
                
            } else {
                self.remoteProvider.section(name, list: list) {remoteResult in
                    
                    if let remoteSection = remoteResult.successResult {
                        let section = SectionMapper.SectionWithRemote(remoteSection)
                        handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: section))
                        
                    } else {
                        print("Error getting remote product, status: \(remoteResult.status)")
                        let providerStatus = DefaultRemoteResultMapper.toProviderStatus(remoteResult.status)
                        handler(ProviderResult(status: providerStatus))
                    }
                }
            }
        }
    }
    
    private func loadProduct(name: String, list: List, handler: ProviderResult<Product> -> ()) {
        self.dbProvider.loadProductWithName(name) {dbProductMaybe in
            if let dbProduct = dbProductMaybe {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
                
            } else {
                self.remoteProvider.product(name, list: list) {remoteResult in
                    
                    if let remoteProduct = remoteResult.successResult {
                        let product = ProductMapper.ProductWithRemote(remoteProduct)
                        handler(ProviderResult(status: .Success, sucessResult: product))
                    } else {
                        print("Error getting remote product, status: \(remoteResult.status)")
                        handler(ProviderResult(status: .DatabaseUnknown))
                    }
                }
            }
        }
    }

    func switchDone(listItems: [ListItem], list: List, done: Bool, _ handler: ProviderResult<Any> -> ()) {
        
        // Helper to count how many list items each section has
        // filtered by "done" in same pass for better performance
        func sectionCountAndFilteredByDoneDict(listItems: [ListItem], done: Bool) -> [Section: Int] {
            var dict = [Section: Int]()
            for listItem in listItems {
                if listItem.done == done {
                    if dict[listItem.section] != nil {
                        dict[listItem.section]!++
                    } else {
                        dict[listItem.section] = 1
                    }
                }
            }
            return dict
        }
        
        self.listItems(list, fetchMode: .MemOnly) {result in // TODO review .First suitable here

            if let storedListItems = result.sucessResult {
            
                // Update done and order field - by changing "done" we are moving list items from one tableview to another
                // we append the items at the end of the section (order == section.count)
                var sectionsDict = sectionCountAndFilteredByDoneDict(storedListItems, done: done)
                for listItem in listItems {
                    listItem.done = done
                    if let sectionCount = sectionsDict[listItem.section] {
                        listItem.order = sectionCount
                        sectionsDict[listItem.section]!++ // we are adding an item to section - increment count for possible next item
                        
                    } else { // item's section is not in target list - set order 0 (first item in section) and add section to the dictionary
                        listItem.order = 0
                        sectionsDict[listItem.section] = 1 // we are adding an item to section - items count is 1
                    }
                }
                
                // persist changes
                self.update(listItems, handler)
                
            } else {
                print("Error: didn't get listItems in updateBatchDone: \(result.status)")
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func update(listItems: [ListItem], _ handler: ProviderResult<Any> -> ()) {
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
            self?.remoteProvider.update(listItems) {result in
                if !result.success {
                    print("Error: Updating listItems: \(listItems), result: \(result)")
                    DefaultRemoteErrorHandler.handle(result.status, handler: handler)
                }
            }
        })
    }
    
    func update(listItem: ListItem, _ handler: ProviderResult<Any> -> ()) {
        update(listItem, handler)
    }
    
    func sections(handler: ProviderResult<[Section]> -> ()) {
        self.dbProvider.loadSections {dbSections in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSections))
        }
    }
    
    func lists(handler: ProviderResult<[List]> -> ()) {
        self.dbProvider.loadLists{dbLists in
            
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbLists))
            
            self.remoteProvider.lists {remoteResult in

                if let remoteLists = remoteResult.successResult {
                    let lists: [List] = remoteLists.map{ListMapper.ListWithRemote($0)}
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if dbLists != lists {
                        
                        self.dbProvider.saveLists(lists, update: true) {saved in
                            if saved {
                                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: lists))
                                
                            } else {
                                print("Error updating lists - dbListsMaybe is nil")
                            }
                        }
                    }
                    
                } else {
                    print("get remote lists no success, status: \(remoteResult.status)")
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
                }
            }
        }
    }
    
    // TODO is this used? Also what id, is it uuid?
    func list(listId: String, _ handler: ProviderResult<List> -> ()) {
        // return the saved object, to get object with generated id
        self.dbProvider.loadList(listId) {dbListMaybe in
            if let dbList = dbListMaybe {
                handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbList))
                
            } else {
                print("Error: couldn't loadList: \(listId)")
                handler(ProviderResult(status: ProviderStatusCode.NotFound))
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
                    
                    self.dbProvider.saveProducts(items.products.map{ProductMapper.ProductWithRemote($0)}) {productSaved in
                        if productSaved {
                            
                            self.dbProvider.saveSections(items.sections.map{SectionMapper.SectionWithRemote($0)}) {sectionsSaved in
                                if sectionsSaved {
                                    
                                    // for now overwrite all. In the future we should do a timestamp check here also for the case that user does an update while the sync service is being called
                                    // since we support background sync, this should not be neglected
                                    
                                    let listItemsWithRelations = ListItemMapper.listItemsWithRemote(items, list: list)
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
                    DefaultRemoteErrorHandler.handle(remoteResult.status, handler: handler)
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
}