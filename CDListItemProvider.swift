//
//  CDListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import CoreData

class CDListItemProvider: CDProvider {
    
    func loadProducts() -> [CDProduct] {
        return self.load(entityName: "CDProduct", type: CDProduct.self)
    }
    
    func loadListItems(listId:String) -> [CDListItem] {
        return self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "list.id=%@", listId),
            sortDescriptors: [NSSortDescriptor(key: "order", ascending: true)])
    }
    
    func loadSections() -> [CDSection] {
        return self.load(entityName: "CDSection", type: CDSection.self)
    }
    
    func loadProduct(id:String) -> CDProduct {
        return self.loadManagedObject(id)
    }
    
    func saveProduct(product:Product) -> CDProduct {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdProduct = NSEntityDescription.insertNewObjectForEntityForName("CDProduct", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDProduct
        
        cdProduct.name = product.name
        cdProduct.price = product.price
        
        self.save()
        
        return cdProduct
    }
    
    func loadSection(name:String?) -> CDSection? {
        let sections = self.load(entityName: "CDSection", type: CDSection.self, predicate: NSPredicate(format: "name=%@", name!))
        return sections.first
    }
    
    func saveSection(section:Section) -> CDSection {
        
        return loadSection(section.name) ?? { // unique - save only if there's no section with this name already
            
            let appDelegate = SharedAppDelegate.getAppDelegate()
            
            let cdSection = NSEntityDescription.insertNewObjectForEntityForName("CDSection", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDSection
            cdSection.name = section.name
            
            self.save()
            
            return cdSection
        }()
    }
    
    func saveListItem(listItem:ListItem) -> CDListItem {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdProduct = self.saveProduct(listItem.product)
        let cdSection = self.saveSection(listItem.section)
//        let cdList = self.saveList(listItem.list)
        let cdList = self.loadList(listItem.list.id) // before list item there must be always a list. Also, if we save each list for each listitem we don't have unique id
        
        let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDListItem

        cdListItem.product = cdProduct
        cdListItem.quantity = listItem.quantity
        cdListItem.done = listItem.done
        cdListItem.order = listItem.order
        cdListItem.section = cdSection
        cdListItem.list = cdList
        
        self.save()
        
        return cdListItem
    }
    
    func loadListItem(id:String) -> CDListItem {
        return self.loadManagedObject(id)
    }

    // update only done status of listitems, this way avoid loading section, list etc.
    func updateListItemsDone(listItems:[ListItem]) -> Bool {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        for listItem in listItems {
            let cdListItem = self.loadListItem(listItem.id)
            cdListItem.done = listItem.done
        }
        return self.save()
    }
  
    // bulk update
    func updateListItems(listItems:[ListItem]) -> [CDListItem]? {
        var updatedCDListItems:[CDListItem] = []
        
        for listItem in listItems {
            if let cdListItem = self.updateListItem(listItem, saveContext: false) { // we save after of bulk update
                updatedCDListItems.append(cdListItem)
                
            } else {
                println ("Error: couldn't update list item")
                return nil
            }
        }
        
        if !self.save() {
            println("Warning: could't save after list items bulk update")
        }
        
        return updatedCDListItems
    }
    
    func updateListItem(listItem:ListItem, saveContext:Bool = true) -> CDListItem? {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdListItem = self.loadListItem(listItem.id)
        let cdSection = self.loadSection(listItem.section.name)! // since we are updating an item, we assume section exists
        let cdList = self.loadList(listItem.list.id)
        
        cdListItem.done = listItem.done
        cdListItem.quantity = listItem.quantity
        cdListItem.product.name = listItem.product.name
        cdListItem.product.price = listItem.product.price
        cdListItem.order = listItem.order
        cdListItem.section = cdSection
        cdListItem.list = cdList
        
        if saveContext {
            if !self.save() {
                println ("Warning: couldn't save context after listitem update")
            }
        }
        
        return cdListItem
    }
    
    func remove(listItem: ListItem, save: Bool = true) -> Bool {
        let cdListItem = self.loadListItem(listItem.id)
        return self.remove(cdListItem, save: save)
    }
    
    private func remove(cdListItem: CDListItem, save: Bool = true) -> Bool {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        appDelegate.managedObjectContext!.deleteObject(cdListItem)
        
        if save {
            return self.save()
        } else {
            return true
        }
    }
    
    private func loadListItems(section: Section) -> [CDListItem] {
        return self.load(
            entityName: "CDListItem",
            type: CDListItem.self,
            predicate: NSPredicate(format: "section.name=%@", section.name))
    }
    
    // remove section and all the listitems assigned to it
    func remove(section:Section) -> Bool {
        let appDelegate = SharedAppDelegate.getAppDelegate()
 
        // remove listitems
        let sectionCDListItems = self.loadListItems(section)
        for cdListItem in sectionCDListItems {
            self.remove(cdListItem, save: false) // we save after everything is updated
        }
       
        // remove section
        if let cdSection = self.loadSection(section.name) {
            self.removeObject(cdSection)
            
        } else {
            println("Error: Illegal state - trying to remove a section that is not stored")
        }
        
        return self.save()
    }
    
    func loadLists() -> [CDList] {
        return self.load(entityName: "CDList", type: CDList.self)
    } 
    
    func loadList(id:String) -> CDList {
        return self.loadManagedObject(id)
    }
    
    func saveList(list:List) -> CDList {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let cdList = NSEntityDescription.insertNewObjectForEntityForName("CDList", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDList
        cdList.name = list.name
        self.save() //save before we store the id because it changes on save, and for consistency we want to store the final one
        
        cdList.id = cdList.objectID.URIRepresentation().absoluteString! // store the core data id as an extra field "id" - to be able to make fetch request using id predicate (we want to fetch list items by list id)
        
        self.save() //now that we stored the id, save again...
        
        return cdList
    }
}
