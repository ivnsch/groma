//
//  CDListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

class CDListItemProvider: CDProvider {

    func save() -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        var error:NSError?
        let success = appDelegate.managedObjectContext!.save(&error)
        if !success {
            println(error?.userInfo)
        }
        return success
    }
    
    
    func loadProducts() -> [CDProduct] {        
        let fetchRequest = NSFetchRequest()
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let entity = NSEntityDescription.entityForName("CDProduct", inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.entity = entity
        
        var error:NSError?
        let products = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as [CDProduct]
        
        return products
    }
    
    func loadListItems() -> [CDListItem] {
        let fetchRequest = NSFetchRequest()
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let entity = NSEntityDescription.entityForName("CDListItem", inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.entity = entity
        
        var error:NSError?
        let listItems = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as [CDListItem]
        
        return listItems
    }
    
    func loadSections() -> [CDSection] {
        let fetchRequest = NSFetchRequest()
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let entity = NSEntityDescription.entityForName("CDSection", inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.entity = entity
        
        var error:NSError?
        let sections = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as [CDSection]
        
        return sections
    }

//    func saveProduct(productName:String) -> CDProduct {
//        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
//        
//        var product = NSEntityDescription.insertNewObjectForEntityForName("CDProduct", inManagedObjectContext: appDelegate.managedObjectContext!) as CDProduct
//        product.name = productName
//        
//        self.save()
//        
//        return product;
//    }
//    
    
    func saveProduct(product:Product) -> CDProduct {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let cdProduct = NSEntityDescription.insertNewObjectForEntityForName("CDProduct", inManagedObjectContext: appDelegate.managedObjectContext!) as CDProduct
        cdProduct.name = product.name
        cdProduct.price = product.price
        cdProduct.quantity = product.quantity
        
        self.save()
        
        return cdProduct
    }
    
    func loadSection(name:String?) -> CDSection? {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("CDSection", inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.predicate = NSPredicate(format: "name=%@", name!)
        
        var error:NSError?
        let sections = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as [CDSection]
        
        return sections.first
    }
    
    func saveSection(section:Section) -> CDSection {
        
        return loadSection(section.name) ?? { // unique - save only if there's no section with this name already
            
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            
            let cdSection = NSEntityDescription.insertNewObjectForEntityForName("CDSection", inManagedObjectContext: appDelegate.managedObjectContext!) as CDSection
            cdSection.name = section.name
            
            self.save()
            
            return cdSection
        }()
    }
    
//    func saveListItem(itemName:String) -> CDListItem {
//        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
//        
//        let product:CDProduct = self.saveProduct(itemName)
//        var listItem = NSEntityDescription.insertNewObjectForEntityForName("ListItem", inManagedObjectContext: appDelegate.managedObjectContext!) as CDListItem
//        listItem.product = product
//        listItem.done = false
//        
//        return listItem;
//    }
    
    
    func saveListItem(listItem:ListItem) -> CDListItem? {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let cdProduct = self.saveProduct(listItem.product)
        let cdSection = self.saveSection(listItem.section)

        let cdListItem = NSEntityDescription.insertNewObjectForEntityForName("CDListItem", inManagedObjectContext: appDelegate.managedObjectContext!) as CDListItem
        cdListItem.product = cdProduct
        cdListItem.done = listItem.done
        cdListItem.section = cdSection
        
        self.save()
        
        return cdListItem
    }
    
    func loadListItem(id:String) -> CDListItem {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let objectId:NSManagedObjectID? = appDelegate.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(NSURL(string: id)!)
        
        let cdListItem = appDelegate.managedObjectContext!.objectWithID(objectId!) as CDListItem
        
        return cdListItem
    }
    
    func updateListItem(listItem:ListItem) -> CDListItem? {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let cdListItem = self.loadListItem(listItem.id)
        
        cdListItem.done = listItem.done
        cdListItem.product.name = listItem.product.name
        cdListItem.product.quantity = listItem.product.quantity
        cdListItem.product.price = listItem.product.price
        
        let saved = self.save()
        
        println("updated list item: \(listItem.product.name), success: \(saved), done: \(cdListItem.done)")
        
        
        return cdListItem
    }
}
