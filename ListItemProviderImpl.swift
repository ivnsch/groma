//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemProviderImpl: ListItemProvider {

    let dbProvider = RealmProvider()
    let remoteProvider = RemoteListItemProvider()
    
    func products(handler: Try<[Product]> -> ()) {
        self.dbProvider.loadProducts {dbProducts in
            handler(Try(dbProducts.map{ProductMapper.productWithDB($0)}))
        }
    }
    
    func listItems(list: List, handler: Try<[ListItem]> -> ()) {
        self.dbProvider.loadListItems(list, handler: {dbListItems in

            let mappedDBlistItems = dbListItems.map{ListItemMapper.listItemWithDB($0)}
            handler(Try(mappedDBlistItems))
            
            self.remoteProvider.listItems(list: list) {remoteResult in
                
                if let remoteListItems = remoteResult.successResult {
                    let listItemsWithRelations: ListItemsWithRelations = ListItemMapper.listItemsWithRemote(remoteListItems)
                    
                    // if there's no cached list or there's a difference, overwrite the cached list
                    if (mappedDBlistItems != listItemsWithRelations.listItems) {
                        self.dbProvider.saveListItems(listItemsWithRelations) {saved in
                            handler(Try(listItemsWithRelations.listItems))
                        }
                    }
                }
            }
        })
    }
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {
        self.dbProvider.remove(listItem, handler: {removed in
            handler(Try(removed))
        })
    }
    
    func remove(section: Section, handler: Try<Bool> -> ()) {
        self.dbProvider.remove(section) {removed in
            handler(Try(removed))
        }
    }
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        self.dbProvider.remove(list) {removed in
            handler(Try(removed))
        }
    }
    
    func add(listItem: ListItem, handler: Try<Bool> -> ()) {

        // return the saved object, to get object with generated id
        
        // for now do remote first. Imagine we do coredata first, user adds the list and then a lot of items to it and server fails. The list with all items will be lost in next sync.
        // we can do special handling though, like show an error message when server fails and remove the list which was just added, and/or retry server. Or use a flag "synched = false" which tells us that these items should not be removed on sync, similar to items which were added offline. Etc.
        self.remoteProvider.add(listItem, handler: {remoteResult in
            
            if let remoteListItem = remoteResult.successResult {
                self.dbProvider.saveListItem(listItem) {saved in // currently the item returned by server is identically to the one we sent, so we just save our local item
                    if saved {
                        handler(Try(saved))
                    }
                }
            }
        })
    }
    
    func add(listItemInput: ListItemInput, list: List, order orderMaybe: Int? = nil, handler: Try<ListItem> -> ()) {

        self.listItems(list, handler: {try in // TODO fetch items only when order not passed, because they are used only to get order
            
            if let listItems = try.success {
                
                let order = orderMaybe ?? listItems.count
                
                // get product and section uui if they're already in the local db (remember that we assign uuid in the client so this logic has to be in the client)
                self.loadProduct(listItemInput.name, list: list) {productTry in
                    
                    // load product and update or create one
                    // if we find a product with the name we update it - this is for the case the user changes the price for an existing product while adding an item
                    let productUuid: String = {
                        if let existingProduct = productTry.success {
                            return existingProduct.uuid
                        } else {
                            return NSUUID().UUIDString
                        }
                    }()
                    let product = Product(uuid: productUuid, name: listItemInput.name, price: listItemInput.price)

                    // load section or create one (there's no more section data in the input besides of the name, so there's nothing to update).
                    // There is no name update since here we have only name so either the name is in db or it's not, if it's not insert a new section
                    self.loadSection(listItemInput.section, list: list) {sectionTry in
                        
                        let section: Section = {
                            if let existingSection = sectionTry.success {
                                return existingSection
                            } else {
                                return Section(uuid: NSUUID().UUIDString, name: listItemInput.section)
                            }
                        }()
                        
                        // WARN / TODO: we didn't do any local db udpates! currently this is done after we receive the response off addItem of the server, with the server object
                        // in order to support offline use this has to be changed either
                        // 1. do the update before calling the service. If service returns an error then remove?
                        // 2. do the update before calling the service, and add flag not synched (etc)
                        // 3. more ideas?
                        let listItem = ListItem(uuid: NSUUID().UUIDString, done: false, quantity: listItemInput.quantity, product: product, section: section, list: list, order: order)
                        self.add(listItem, handler: {saved in
                            handler(Try(listItem))
                        })
                    }
                }
            }
        })
    }
    
    private func loadSection(name: String, list: List, handler: Try<Section> -> ()) {
        self.dbProvider.loadSectionWithName(name) {dbSectionMaybe in
            if let dbSection = dbSectionMaybe {
                let section = SectionMapper.sectionWithDB(dbSection)
                handler(Try(section))
                
            } else {
                self.remoteProvider.section(name, list: list) {remoteResult in
                    
                    if let remoteSection = remoteResult.successResult {
                        let section = SectionMapper.SectionWithRemote(remoteSection)
                        handler(Try(section))
                    } else {
                        println("Error getting remote product, status: \(remoteResult.status)")
                        handler(Try(NSError()))
                    }
                }
            }
        }
    }
    
    private func loadProduct(name: String, list: List, handler: Try<Product> -> ()) {
        self.dbProvider.loadProductWithName(name) {dbProductMaybe in
            if let dbProduct = dbProductMaybe {
                let product = ProductMapper.productWithDB(dbProduct)
                handler(Try(product))
                
            } else {
                self.remoteProvider.product(name, list: list) {remoteResult in
                    
                    if let remoteProduct = remoteResult.successResult {
                        let product = ProductMapper.ProductWithRemote(remoteProduct)
                        handler(Try(product))
                    } else {
                        println("Error getting remote product, status: \(remoteResult.status)")
                        handler(Try(NSError()))
                    }
                }
            }
        }
    }
 
    func updateDone(listItems: [ListItem], handler: Try<Bool> -> ()) {
        self.update(listItems, handler: handler)
    }
    
    func update(listItems: [ListItem], handler: Try<Bool> -> ()) {
        return self.dbProvider.updateListItems(listItems, handler: {dbListItemsMaybe in
            handler(Try(dbListItemsMaybe != nil))
        })
    }
    
    func update(listItem: ListItem, handler: Try<Bool> -> ()) {
        
        self.dbProvider.saveListItem(listItem) {dbListItem in
            handler(Try(true))
        }
        
//        self.dbProvider.saveSection(listItem.section, handler: {dbSectionMaybe in
//            self.dbProvider.updateListItem(listItem, handler: {try in
//                handler(Try(try.success != nil))
//            })
//
//        }) // creates a new section if there isn't one already
    }
    
    func sections(handler: Try<[Section]> -> ()) {
        self.dbProvider.loadSections {dbSections in
            handler(Try(dbSections.map{SectionMapper.sectionWithDB($0)}))
        }
    }
    
    func measure(title: String, block: (() -> ()) -> ()) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        block {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            println("\(title):: Time: \(timeElapsed)")
        }
    }
    
    func lists(handler: Try<[List]> -> ()) {
        self.dbProvider.loadLists{dbLists in
            
            handler(Try(dbLists))
            
            self.remoteProvider.lists {remoteResult in
                if remoteResult.success {
                    if let remoteLists = remoteResult.successResult {
                        let lists: [List] = remoteLists.map{ListMapper.ListWithRemote($0)}
                        
                        // if there's no cached list or there's a difference, overwrite the cached list
                        if dbLists != lists {
                            
                            self.dbProvider.saveLists(lists, update: true) {saved in
                                if saved {
                                    handler(Try(lists))
                                    
                                } else {
                                    println("Error updating lists - dbListsMaybe is nil")
                                }
                            }
                        }
                        
                    } else {
                        println("Error: invalid state: success response but remote lists is nil")
                        // TODO return error to client
                    }
                    
                } else {
                    println("get remote lists no success, status: \(remoteResult.status)")
                }
            }
        }
    }
    
    // TODO is this used? Also what id, is it uuid?
    func list(listId: String, handler: Try<List> -> ()) {
        // return the saved object, to get object with generated id
        self.dbProvider.loadList(listId) {dbListMaybe in
            if let dbList = dbListMaybe {
                let list = ListMapper.listWithDB(dbList)
                handler(Try(list))
                
            } else {
                println("Error: couldn't loadList: \(listId)")
                handler(Try(NSError()))
            }

        }
    }
    
    func add(list: ListWithSharedUsersInput, handler: Try<List> -> ()) {

        // TODO ensure that in add list case the list is persisted / is never deleted
        // it can be that the user adds it, and we add listitem to tableview immediately to make it responsive
        // but then the background service call fails so nothing is added in the server or db and the user adds 100 items to the list and restarts the app and everything is lost!
        self.remoteProvider.add(list, handler: {remoteResult in
     
            if let remoteList = remoteResult.successResult {
                
                let list = ListMapper.ListWithRemote(remoteList)
                
                self.dbProvider.saveList(list, handler: {saved in
                    handler(Try(list))
                })
                
            } else {
                println("error adding the remote list: \(remoteResult)")
            }
        })
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