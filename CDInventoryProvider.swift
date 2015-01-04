//
//  CDInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import CoreData

class CDInventoryProvider: CDProvider {
    
    let cdListItemProvider:CDListItemProvider = CDListItemProvider() // TODO review - is it a good practice to create dependencies between providers like this
    
    
    func loadInventory() -> [CDInventoryItem] {
        return self.load(entityName: "CDInventoryItem", type: CDInventoryItem.self)
    }
    
    func addToInventory(items:[InventoryItem]) -> Bool {
        for item in items {
            self.addToInventory(item, save: false) // don't save after each item, we save after all
        }
        self.save()
        
        return true
    }
    
    private func loadInventoryItem(product:Product) -> CDInventoryItem? {
        // for now use the product name instead of id, because we create a new product each time and don't do unique name check... name in inventory at least should be unique
        // the problem is basically that we allow the user to add multiple listitems with the same name and this creates new product each time so we can have multiple products with the same name. This is kind of wrong because there should be globally only 1 product with a name (unless we create a unique with product name+market/section or similar)
        // in any case, in the inventory product name must be unique (or show to the user all attributes which make the item unique e.g. bread(bakery)-2x, bread(toy)-3x etc. (in this case bakery/toy is a section)
        // TODO later after introducing market product & co review uniqueness and relationship product-inventory item
        return self.load(entityName: "CDInventoryItem", type: CDInventoryItem.self, predicate: NSPredicate(format: "product.name=%@", product.name)).first
    }
    
    func addToInventory(item:InventoryItem, save:Bool = true) -> CDInventoryItem {
        var savedItem:CDInventoryItem
        
        if let existingItem = self.loadInventoryItem(item.product) {
            existingItem.quantity = existingItem.quantity.integerValue + item.quantity
            savedItem = existingItem
            
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let cdInventoryItem = NSEntityDescription.insertNewObjectForEntityForName("CDInventoryItem", inManagedObjectContext: appDelegate.managedObjectContext!) as CDInventoryItem
            
            let cdProduct = cdListItemProvider.loadProduct(item.product.id)
            
            cdInventoryItem.product = cdProduct
            cdInventoryItem.quantity = item.quantity
            savedItem = cdInventoryItem
            
            if save {
                self.save()
            }
        }
        return savedItem
    }
    
    func updateInventoryItem(item:InventoryItem) -> CDInventoryItem {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let cdInventoryItem = self.loadInventoryItem(item.product)
        
        cdInventoryItem!.quantity = item.quantity
        
        let saved = self.save()
        
        return cdInventoryItem!
    }
}