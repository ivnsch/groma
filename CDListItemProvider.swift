//
//  CDListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

class CDListItemProvider: CDProvider {
    
    func loadProducts(handler: (Try<[CDProduct]>) -> ()) {
        self.load(entityName: "CDProduct", type: CDProduct.self, handler: handler)
    }
    
    func loadListItems(listId: String, handler: Try<[CDListItem]> -> ()) {
    
        self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "list.uuid=%@", listId),
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)],
            handler: {try in
                if let cdListItems = try.success {
                    handler(Try(cdListItems))
                }
            }
        )
    }
    
    func loadSections(handler: (Try<[CDSection]>) -> ()) {
        self.load(entityName: "CDSection", type: CDSection.self, handler: {try in
            if let cdSections = try.success {
                handler(Try(cdSections))
            }
        })
    }
    
    func loadProduct(id: String, handler: (Try<CDProduct>) -> ()) {
        self.load(entityName: "CDProduct", type: CDProduct.self, predicate: NSPredicate(format: "uuid=%@", id), handler: {try in
            
            if let cdProducts = try.success {
                if let first = cdProducts.first {
                    handler(Try(first))
                }
            }
        })
    }
    
    func saveProduct(product: Product, handler: Try<CDProduct> -> ()) {
        let cdProduct = self.saveProductInt(product, save: true)
        
        handler(Try(cdProduct))
    }
    
    func loadSection(name: String?, handler: Try<CDSection> -> ()) {
        self.load(entityName: "CDSection", type: CDSection.self, predicate: NSPredicate(format: "name=%@", name!), handler: {try in
            
            if let sections = try.success {
                if let section = sections.first {
                    handler(Try(section))
                    
                } else {
                    handler(Try(NSError()))
                }
            }
        })
    }
    
    func saveSection(section: Section, handler: Try<CDSection> -> ()) {
        
        loadSection(section.name, handler: {try in
            
            if let cdSection = try.success { // unique - save only if there's no section with this name already
                handler(Try(cdSection))
            
            } else {
                
                let cdSection = NSEntityDescription.insertNewObjectForEntityForName("CDSection", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDSection
                cdSection.uuid = section.uuid
                cdSection.name = section.name
                
                self.save{try in
                }
                
                handler(Try(cdSection))
            }
            
        })
    }
    
    func saveListsOverwrite(lists: [List], handler: Try<Bool> -> ()) {
        
        self.removeAll("CDList", save: false, handler: {[weak self] removeListsTry in
            
            if removeListsTry.success ?? false == true {
                self!.saveListsInt(lists, save: true)
                handler(Try(true)) // TODO error handling?
            }
        })
    }
    
    ///////////////////////////////////////////////
    // TODO refactor
    
    private func saveProductsInt(products: [Product], save: Bool) -> (arr: [CDProduct], idDict: [String: CDProduct]) {
        var arr: [CDProduct] = []
        var idDict: [String: CDProduct] = [:]
        for product in products {
            let cdProduct = self.saveProductInt(product, save: save)
            arr.append(cdProduct)
            idDict[product.uuid] = cdProduct
        }
        
        return (
            arr: arr,
            idDict: idDict
        )
    }
    
    private func saveSectionsInt(sections: [Section], save: Bool) -> (arr: [CDSection], idDict: [String: CDSection]) {
        var arr: [CDSection] = []
        var idDict: [String: CDSection] = [:]
        for section in sections {
            let cdSection = self.saveSectionInt(section, save: save)
            arr.append(cdSection)
            idDict[section.uuid] = cdSection
        }
        
        return (
            arr: arr,
            idDict: idDict
        )
    }
    
    // TODO async, also in other methods, check that save can be done in bg (crash in other place)
    private func saveListsInt(lists: [List], save: Bool) -> (arr: [CDList], idDict: [String: CDList]) {
        var arr: [CDList] = []
        var idDict: [String: CDList] = [:]
        for list in lists {
            let cdList = self.saveListInt(list, save: false)
            arr.append(cdList)
            idDict[list.uuid] = cdList
        }
        
        if save {
            self.save{try in
            }
        }
        
        return (
            arr: arr,
            idDict: idDict
        )
    }
    
    private func saveProductInt(product: Product, save: Bool) -> CDProduct {
        
        let cdProduct = NSEntityDescription.insertNewObjectForEntityForName("CDProduct", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDProduct
        
        cdProduct.uuid = product.uuid
        cdProduct.name = product.name
        cdProduct.price = product.price
        
        if save {
            self.save{try in
            }
        }
        
        return cdProduct
    }
    
    private func saveListInt(list: List, save: Bool) -> CDList {
        
        let cdList = NSEntityDescription.insertNewObjectForEntityForName("CDList", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDList
        
        cdList.uuid = list.uuid
        cdList.name = list.name

        if save {
            self.save{try in
            }
        }
        
        return cdList
    }
    
    private func saveSectionInt(section: Section, save: Bool) -> CDSection {
        
        let cdSection = NSEntityDescription.insertNewObjectForEntityForName("CDSection", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDSection
        
        cdSection.uuid = section.uuid
        cdSection.name = section.name
        
        if save {
            self.save{try in
            }
        }

        return cdSection
    }
    
    
    
    private func upsertProductsInt(models: [Product], save: Bool, handler: Try<(arr: [CDProduct], idDict: [String: CDProduct])> -> ()) {
        self.load(entityName: "CDProduct", type: CDProduct.self, predicate: NSPredicate(format: "uuid IN %@", models.map{$0.uuid}), handler: {try in
            
            if let cdObjs = try.success { // TODO check that when there are no saved products we also join this block

                var existingCDObjsIdsDict: [String: CDProduct] = [:] // quick lookup
                for cdObj in cdObjs {
                    existingCDObjsIdsDict[cdObj.uuid] = cdObj
                }
                
                var idDict: [String: CDProduct] = [:]
                var cdObjs: [CDProduct] = []
                
                for model in models {
                    
                    let cdObj: CDProduct = {
                        if let existing = existingCDObjsIdsDict[model.uuid] { // object is in the db - update
                            existing.name = model.name
                            existing.price = model.price
                            return existing
                            
                        } else { // insert
                            return self.saveProductInt(model, save: false) // we save at the end
                        }
                    }()

                    idDict[model.uuid] = cdObj
                    cdObjs.append(cdObj)
                }
                
                let result: (arr: [CDProduct], idDict: [String: CDProduct]) = (cdObjs, idDict)
                
                if save {
                    self.save{try in
                        handler(Try(result))
                    }
                } else {
                    handler(Try(result))
                }

            }
        })
    }

    private func upsertSectionsInt(models: [Section], save: Bool, handler: Try<(arr: [CDSection], idDict: [String: CDSection])> -> ()) {
        self.load(entityName: "CDSection", type: CDSection.self, predicate: NSPredicate(format: "uuid IN %@", models.map{$0.uuid}), handler: {try in
            
            if let cdObjs = try.success { // TODO check that when there are no saved products we also join this block
                
                var existingCDObjsIdsDict: [String: CDSection] = [:] // quick lookup
                for cdObj in cdObjs {
                    existingCDObjsIdsDict[cdObj.uuid] = cdObj
                }
                
                var idDict: [String: CDSection] = [:]
                var cdObjs: [CDSection] = []
                
                for model in models {
                    
                    let cdObj: CDSection = {
                        if let existing = existingCDObjsIdsDict[model.uuid] { // object is in the db - update
                            existing.name = model.name
                            return existing
                            
                        } else { // insert
                            return self.saveSectionInt(model, save: false) // we save at the end
                        }
                    }()
                    
                    idDict[model.uuid] = cdObj
                    cdObjs.append(cdObj)
                }
                
                let result: (arr: [CDSection], idDict: [String: CDSection]) = (cdObjs, idDict)
                
                if save {
                    self.save{try in
                        handler(Try(result))
                    }
                } else {
                    handler(Try(result))
                }
            }
        })
    }
    
    private func upsertListsInt(models: [List], save: Bool, handler: Try<(arr: [CDList], idDict: [String: CDList])> -> ()) {
        self.load(entityName: "CDList", type: CDList.self, predicate: NSPredicate(format: "uuid IN %@", models.map{$0.uuid}), handler: {try in
            
            if let cdObjs = try.success { // TODO check that when there are no saved products we also join this block
                
                var existingCDObjsIdsDict: [String: CDList] = [:] // quick lookup
                for cdObj in cdObjs {
                    existingCDObjsIdsDict[cdObj.uuid] = cdObj
                }
                
                var idDict: [String: CDList] = [:]
                var cdObjs: [CDList] = []
                
                for model in models {
                    
                    let cdObj: CDList = {
                        if let existing = existingCDObjsIdsDict[model.uuid] { // object is in the db - update
                            existing.name = model.name
                            return existing
                            
                        } else { // insert
                            return self.saveListInt(model, save: false) // we save at the end
                        }
                        }()
                    
                    idDict[model.uuid] = cdObj
                    cdObjs.append(cdObj)
                }
                
                let result: (arr: [CDList], idDict: [String: CDList]) = (cdObjs, idDict)
                
                if save {
                    self.save{try in
                        handler(Try(result))
                    }
                } else {
                    handler(Try(result))
                }
                
            }
        })
    }
    
//    private func saveListItemInt(listItem: ListItem, save: Bool) -> CDListItem {
//        let appDelegate = SharedAppDelegate.getAppDelegate()
//        
//        let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDListItem
//        
//        cdListItem.uuid = listItem.uuid
//        cdListItem.product = cdProductsDict[listItem.uuid]!
//        cdListItem.quantity = listItem.quantity
//        cdListItem.done = listItem.done
//        cdListItem.order = listItem.order
//        cdListItem.section = cdSectionsDict[listItem.uuid]!
//        cdListItem.list = cdListsDict[listItem.uuid]!
//        
//        if save {
//            self.save{try in
//            }
//        }
//        
//        return cdSection
//    }
    
    
    ///////////////////////////////////////////////
    
    func saveListItemsForListUpdate(listItemsWithRelations: ListItemsWithRelations, list: List, handler: Try<Bool> -> ()) {
        self.saveListItemsUpdate(listItemsWithRelations, deleteListItemsPredicate: NSPredicate(format: "list.uuid=%@", list.uuid), handler: handler)
    }
    
    private func saveListItemsUpdate(listItemsWithRelations: ListItemsWithRelations, deleteListItemsPredicate: NSPredicate? = nil, handler: Try<Bool> -> ()) {
    
        let didUpdateEverything: (cdProductsDict: [String: CDProduct], cdSectionsDict: [String: CDSection], cdListsDict: [String: CDList]) -> () = {[weak self] cdProductsDict, cdSectionsDict, cdListsDict in

            // save list items
            for listItem in listItemsWithRelations.listItems {
                let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDListItem
                
                cdListItem.uuid = listItem.uuid
                cdListItem.product = cdProductsDict[listItem.product.uuid]!
                cdListItem.quantity = listItem.quantity
                cdListItem.done = listItem.done
                cdListItem.order = listItem.order
                cdListItem.section = cdSectionsDict[listItem.section.uuid]!
                cdListItem.list = cdListsDict[listItem.list.uuid]!
            }
            
            // now that everything is saved, write to disk
            self!.save(handler)
        }
        
        // delete the all list items for this list
        self.removeAll("CDListItem", predicate: deleteListItemsPredicate, save: false, handler: {removeListItemsTry in
            if removeListItemsTry.success ?? false == true {
                
                // update relations - products, sections, list
                // products, sections and list table contain data from other lists or things so we don't do delete table and insert here
                // TODO these could be executed in paralel, check after port to futures
                self.upsertProductsInt(listItemsWithRelations.products, save: false, handler: {upsertProductsTry in
                    
                    if let (_, cdProductsDict) = upsertProductsTry.success {
                        
                        self.upsertSectionsInt(listItemsWithRelations.sections, save: false, handler: {upsertSectionsTry in
                            
                            if let (_, cdSectionsDict) = upsertSectionsTry.success {
                                
                                self.upsertListsInt(listItemsWithRelations.lists, save: false, handler: {upsertListsTry in
                                    
                                    if let (_, cdListsDict) = upsertListsTry.success {
                                        didUpdateEverything(cdProductsDict: cdProductsDict, cdSectionsDict: cdSectionsDict, cdListsDict: cdListsDict)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })
    }
    
    
    
    // overwrites list items, products, lists, sections
    func saveListItemsOverwrite(listItemsWithRelations: ListItemsWithRelations, handler: Try<Bool> -> ()) {
        
        let didRemoveEverything: () -> () = {[weak self] in

            // save the products, sections, lists
            // TODO error checking this assumes it works
            let (cdProducts, cdProductsDict) = self!.saveProductsInt(listItemsWithRelations.products, save: false)
            let (cdSections, cdSectionsDict) = self!.saveSectionsInt(listItemsWithRelations.sections, save: false)
            let (cdLists, cdListsDict) = self!.saveListsInt(listItemsWithRelations.lists, save: false)

            // save list items
            for listItem in listItemsWithRelations.listItems {
                let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDListItem
                
                cdListItem.uuid = listItem.uuid
                cdListItem.product = cdProductsDict[listItem.product.uuid]!
                cdListItem.quantity = listItem.quantity
                cdListItem.done = listItem.done
                cdListItem.order = listItem.order
                cdListItem.section = cdSectionsDict[listItem.section.uuid]!
                cdListItem.list = cdListsDict[listItem.list.uuid]!
            }
            
            // now that everything is saved, write to disk
            self!.save{try in
                
                if let error = try.error {
                    println("Error saving after saveListItems: \(error)")
                }
            }
        }
        
        // clear everything
        // TODO error handling, maybe after porting to futures
        self.removeAll("CDListItem", save: false, handler: {removeListItemsTry in
            if removeListItemsTry.success ?? false == true {
                
                self.removeAll("CDList", save: false, handler: {removeListsTry in
                    if removeListsTry.success ?? false == true {
                        
                        self.removeAll("CDSection", save: false, handler: {removeSectionsTry in
                            if removeSectionsTry.success ?? false == true {

                                self.removeAll("CDProduct", save: false, handler: {removeProductsTry in
                                    if removeProductsTry.success ?? false == true {
                                        didRemoveEverything()
                                    }
                                })
                            }
                        })
                    }
                })
            }
        })
    }
    
    func saveListItem(listItem: ListItem, handler: Try<CDListItem> -> ()) {

        var cdProductMaybe: CDProduct?
        var cdSectionMaybe: CDSection?
        
        let ifProductAndSectionSaved: () -> () = {
            if let cdProduct = cdProductMaybe, cdSection = cdSectionMaybe {
                
                self.loadList(listItem.list.uuid, handler: {try in
                    
                    if let cdList = try.success {
                        let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDListItem
                        
                        cdListItem.uuid = listItem.uuid
                        cdListItem.product = cdProduct
                        cdListItem.quantity = listItem.quantity
                        cdListItem.done = listItem.done
                        cdListItem.order = listItem.order
                        cdListItem.section = cdSection
                        cdListItem.list = cdList

                        self.save{try in
                        }
                        
                        handler(Try(cdListItem))
                    }
                    
                }) // before list item there must be always a list. Also, if we save each list for each listitem we don't have unique id
            }
        }
        
        
        self.saveProduct(listItem.product, handler: {try in
            cdProductMaybe = try.success
            ifProductAndSectionSaved()
        })
        
        self.saveSection(listItem.section, handler: {try in
            cdSectionMaybe = try.success
            ifProductAndSectionSaved()
        })
    }
    
    func loadListItem(id: String, handler: Try<CDListItem> -> ()) {
        
        self.load(entityName: "CDListItem", type: CDListItem.self, predicate: NSPredicate(format: "uuid=%@", id), handler: {try in
            
            if let cdListItems = try.success {
                if let cdListItem = cdListItems.first {
                    handler(Try(cdListItem))
                }
            }
        })
    }

    // update only done status of listitems, this way avoid loading section, list etc.
    func updateListItemsDone(listItems: [ListItem], handler: Try<Bool> -> ()) {
        
        var count = 0
        
        for listItem in listItems {
            self.loadListItem(listItem.uuid, handler: {try in
                
                if let cdListItem = try.success {
                    cdListItem.done = listItem.done
                }
                
                if ++count == listItems.count {
                    self.save(handler)
                }
            })
        }
    }
  
    // bulk update
    func updateListItems(listItems:[ListItem], handler: Try<[CDListItem]> -> ()) {
        var updatedCDListItems:[CDListItem] = []
        
        for listItem in listItems {
            
            self.updateListItem(listItem, saveContext: false, handler: {try in  // saveContext: false -> we save after bulk update
                if let cdListItem = try.success {
                    updatedCDListItems.append(cdListItem)
                } else {
                    println ("Error: couldn't update list item")
                    handler(Try(NSError()))
                }
            })
        }
        
        self.save {try in
            if let error = try.error {
                println("Warning: could't save after list items bulk update, \(error.description)")
            }
            
            handler(Try(updatedCDListItems))
        }
    }
    
    func updateListItem(listItem: ListItem, saveContext: Bool = true, handler: Try<CDListItem> -> ()) {
        
        self.loadListItem(listItem.uuid, handler: {try in
            
            if let cdListItem = try.success {
                
                self.loadSection(listItem.section.name, handler: {try in
                    
                    if let cdSection = try.success {
                        self.loadList(listItem.list.uuid, handler: {try in
                            
                            if let cdList = try.success {
                                cdListItem.uuid = listItem.uuid
                                cdListItem.done = listItem.done
                                cdListItem.quantity = listItem.quantity
                                cdListItem.product.name = listItem.product.name
                                cdListItem.product.price = listItem.product.price
                                cdListItem.order = listItem.order
                                cdListItem.section = cdSection
                                cdListItem.list = cdList
                                
                                if saveContext {
                                    self.save{try in
                                        if let error = try.error {
                                            println ("Warning: couldn't save context after listitem update, \(error.description)")
                                        }
                                        
                                        handler(Try(cdListItem))
                                    }
                                }
                            }
                        })
                    } else {
                        println("Error: Invalid state: couldn't find section: \(listItem.section.name) for updated item")
                    }
                })
            }
        })
    }
    
    func remove(listItem: ListItem, save: Bool = true, handler: Try<Bool> -> ()) {
        self.loadListItem(listItem.uuid, handler: {try in
            if let cdListItem = try.success {
                self.remove(cdListItem, save: save, handler: handler)
                //        return self.remove(cdListItem, save: save)
            }
        })
    }
    
    private func remove(cdListItem: CDListItem, save: Bool = true, handler: Try<Bool> -> ()) {
        PersistentStoreHelper.sharedInstance.managedObjectContext!.deleteObject(cdListItem)
        
        self.save(handler)
    }
    
    private func loadListItems(section: Section, handler: Try<[CDListItem]> -> ()) {
        self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "section.name=%@", section.name),
            handler: handler)
    }
    
    private func loadListItems(list: List, handler: Try<[CDListItem]> -> ()) {
        
        self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "list.name=%@", list.name),
            handler: handler)
    }
    
    // remove section and all the listitems assigned to it
    func remove(section:Section, handler: Try<Bool> -> ()) {
 
        var listItemsRemoved: Bool = false
        var sectionRemoved: Bool = false
        
        let ifListItemsAndSectionRemoved: () -> () = {
            if listItemsRemoved && sectionRemoved {
                self.save(handler)
            }
        }
        
        // remove listitems
        self.loadListItems(section, handler: {try in
        
            if let sectionCDListItems = try.success {
                var count = 0
                for cdListItem in sectionCDListItems {
                    self.remove(cdListItem, save: false, handler: {try in
                        // TODO handle result
                        
                        if ++count == sectionCDListItems.count {
                            listItemsRemoved = true
                            ifListItemsAndSectionRemoved()
                        }
                        
                    }) // we save after everything is updated
                }
            } else {
                println("Error: no result for load list items, callback will never be executed")
            }
        })
        

        // remove section
        self.loadSection(section.name, handler: {try in
           
            if let cdSection = try.success {
                
                self.removeObject(cdSection, handler: {try in
                    sectionRemoved = true
                    ifListItemsAndSectionRemoved()
                })
            } else {
                println("Error: Illegal state - couldn't find section for listitem to be removed, callback will never be executed")
            }
        })
    }
   
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        
        var listItemsRemoved: Bool = false
        var listRemoved: Bool = false
        
        let ifListItemsAndListRemoved: () -> () = {
            if listItemsRemoved && listRemoved { // TODO check possible race condition here
                handler(Try(true)) // TODO better handling, if e.g. try with cdListItems or remove list is not success this will never be executed
            }
        }
        
        // remove listitems
        self.loadListItems(list, handler: {try in
            
            if let cdListItems = try.success {
                var count = 0
                for cdListItem in cdListItems {
                    self.remove(cdListItem, save: false, handler: {try in
                        if ++count == cdListItems.count {
                            listItemsRemoved = true
                        }
                    }) // we save after everything is updated
                }
            }
        })
        
        
        // remove list
        self.loadList(list.uuid, handler: {try in
            
            if let cdList = try.success {
                self.removeObject(cdList, handler: {try in
                
                    self.save{try in
                        
                        listRemoved = try.success ?? false
                        if !listRemoved {
                            println("Error: list couldn't be removed in core data")
                        }
                        ifListItemsAndListRemoved()
                    }
                })

            }
        })
    }
    
    func loadLists(handler: Try<[CDList]> -> ()) {
        self.load(entityName: "CDList", type: CDList.self, handler: handler)
    } 
    
    func loadList(id: String, handler: Try<CDList> -> ()) {
        self.load(entityName: "CDList", type: CDList.self, predicate: NSPredicate(format: "uuid=%@", id), handler: {try in
            if let cdLists = try.success {
                if let cdList = cdLists.first {
                    handler(Try(cdList))
                }
            }
        })
    }
    
    func saveList(list: List, handler: Try<CDList> -> ()) {
        
        let cdList = NSEntityDescription.insertNewObjectForEntityForName("CDList", inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!) as! CDList
        cdList.name = list.name
        cdList.uuid = NSUUID().UUIDString
        
        self.save{try in
            handler(Try(cdList))
        }
    }
}
