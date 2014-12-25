//
//  ListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//


class ListItemProviderImpl:ListItemProvider {

    let cdProvider = CDListItemProvider()

    func products() -> [Product] {
        return self.cdProvider.loadProducts().map {ProductMapper.productWithCD($0)}
    }
    
    func listItems() -> [ListItem] {
        return self.cdProvider.loadListItems().map {
            let product = ProductMapper.productWithCD($0.product)
            let section = SectionMapper.sectionWithCD($0.section)
            return ListItem(done:$0.done, product:product, section:section)
        }
    }
    
    func remove(listItem:ListItem) -> Bool {
        
        //TODO - remove list item by id
        
//        var success = false
//
//        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
//        let entity = NSEntityDescription.entityForName("Product", inManagedObjectContext: appDelegate.managedObjectContext!)
//        let fetch = NSFetchRequest()
//        fetch.entity = entity
//
//        let predicate = NSPredicate(format: "name == %@", item)
//        fetch.predicate = predicate
//
//        var error:NSError?
//        let products = appDelegate.managedObjectContext!.executeFetchRequest(fetch, error: &error) as [Product]
//
//        for product in products {
//            appDelegate.managedObjectContext!.deleteObject(product)
//        }
//
//        if appDelegate.managedObjectContext!.save(&error) {
//            success = true
//        } else {
//            println(error?.userInfo)
//        }
//        
//        return success
        
        return true
    }
    
    func add(listItem:ListItem) -> Bool {
        return self.cdProvider.saveListItem(listItem) != nil
    }
    
    func sections() -> [Section] {
        return self.cdProvider.loadSections().map {
            return Section(name: $0.name)
        }
    }
}