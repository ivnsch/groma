//
//  CDListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import CoreData

class CDListItemProvider: CDProvider {
    
    func loadProducts(handler: (Try<[CDProduct]>) -> ()) {
        self.load(entityName: "CDProduct", type: CDProduct.self, handler: handler)
    }
    
    func loadListItems(listId: String, handler: Try<[CDListItem]> -> ()) {
    
        self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "list.id=%@", listId),
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
        self.load(entityName: "CDProduct", type: CDProduct.self, predicate: NSPredicate(format: "id=%@", id), handler: {try in
            
            if let cdProducts = try.success {
                if let first = cdProducts.first {
                    handler(Try(first))
                }
            }
        })
    }
    
    func saveProduct(product: Product, handler: Try<CDProduct> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdProduct = NSEntityDescription.insertNewObjectForEntityForName("CDProduct", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDProduct
        
        cdProduct.id = product.id
        cdProduct.name = product.name
        cdProduct.price = product.price
        
        self.save{try in
        }
        
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
                let appDelegate = SharedAppDelegate.getAppDelegate()
                
                let cdSection = NSEntityDescription.insertNewObjectForEntityForName("CDSection", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDSection
                cdSection.name = section.name
                
                self.save{try in
                }
                
                handler(Try(cdSection))
            }
            
        })
    }
    
    func saveListItem(listItem: ListItem, handler: Try<CDListItem> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()

        var cdProductMaybe: CDProduct?
        var cdSectionMaybe: CDSection?
        
        let ifProductAndSectionSaved: () -> () = {
            if let cdProduct = cdProductMaybe, cdSection = cdSectionMaybe {
                
                self.loadList(listItem.list.id, handler: {try in
                    
                    if let cdList = try.success {
                        let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDListItem
                        
                        cdListItem.id = listItem.id
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
        
        self.load(entityName: "CDListItem", type: CDListItem.self, predicate: NSPredicate(format: "id=%@", id), handler: {try in
            
            if let cdListItems = try.success {
                if let cdListItem = cdListItems.first {
                    handler(Try(cdListItem))
                }
            }
        })
    }

    // update only done status of listitems, this way avoid loading section, list etc.
    func updateListItemsDone(listItems: [ListItem], handler: Try<Bool> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        var count = 0
        
        for listItem in listItems {
            self.loadListItem(listItem.id, handler: {try in
                
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
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        self.loadListItem(listItem.id, handler: {try in
            
            if let cdListItem = try.success {
                
                self.loadSection(listItem.section.name, handler: {try in
                    
                    if let cdSection = try.success {
                        self.loadList(listItem.list.id, handler: {try in
                            
                            if let cdList = try.success {
                                cdListItem.id = listItem.id
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
        self.loadListItem(listItem.id, handler: {try in
            if let cdListItem = try.success {
                self.remove(cdListItem, save: save, handler: handler)
                //        return self.remove(cdListItem, save: save)
            }
        })
    }
    
    private func remove(cdListItem: CDListItem, save: Bool = true, handler: Try<Bool> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        appDelegate.managedObjectContext!.deleteObject(cdListItem)
        
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
        let appDelegate = SharedAppDelegate.getAppDelegate()
 
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
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
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
        self.loadList(list.id, handler: {try in
            
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
        self.load(entityName: "CDList", type: CDList.self, predicate: NSPredicate(format: "id=%@", id), handler: {try in
            if let cdLists = try.success {
                if let cdList = cdLists.first {
                    handler(Try(cdList))
                }
            }
        })
    }
    
    func saveList(list: List, handler: Try<CDList> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdList = NSEntityDescription.insertNewObjectForEntityForName("CDList", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDList
        cdList.name = list.name
        cdList.id = NSUUID().UUIDString
        
        self.save{try in
            handler(Try(cdList))
        }
    }
}
