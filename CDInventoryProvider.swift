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
    
    
    func loadInventory(handler: Try<[CDInventoryItem]> -> ()) {
        self.load(entityName: "CDInventoryItem", type: CDInventoryItem.self, handler: handler)
    }
    
    func addToInventory(items: [InventoryItem], handler: Try<Bool> -> ()) {
        for item in items {
            self.addToInventory(item, save: false, handler: {try in
            }) // don't save after each item, we save after all
        }
        self.save(handler)
    }
    
    private func loadInventoryItem(product: Product, handler: Try<CDInventoryItem> -> ()) {
        // for now use the product name instead of id, because we create a new product each time and don't do unique name check... name in inventory at least should be unique
        // the problem is basically that we allow the user to add multiple listitems with the same name and this creates new product each time so we can have multiple products with the same name. This is kind of wrong because there should be globally only 1 product with a name (unless we create a unique with product name+market/section or similar)
        // in any case, in the inventory product name must be unique (or show to the user all attributes which make the item unique e.g. bread(bakery)-2x, bread(toy)-3x etc. (in this case bakery/toy is a section)
        // TODO later after introducing market product & co review uniqueness and relationship product-inventory item
        self.load(entityName: "CDInventoryItem", type: CDInventoryItem.self, predicate: NSPredicate(format: "product.name=%@", product.name), handler: {try in
            if let items = try.success {
                if let first = items.first {
                    handler(Try(first))
                }
            }
        })
    }
    
    func addToInventory(item: InventoryItem, save: Bool = true, handler: Try<CDInventoryItem> -> ()) {
        
        self.loadInventoryItem(item.product, handler: {[weak self] try in
            
            if let existingItem = try.success {
                existingItem.quantity = existingItem.quantity.integerValue + item.quantity
                handler(Try(existingItem))
                
            } else {
                let appDelegate = SharedAppDelegate.getAppDelegate()
                let cdInventoryItem = NSEntityDescription.insertNewObjectForEntityForName("CDInventoryItem", inManagedObjectContext: appDelegate.managedObjectContext!) as! CDInventoryItem
                
                self?.cdListItemProvider.loadProduct(item.product.uuid, handler: {try in
                    
                    if let cdProduct = try.success {
                        
                        cdInventoryItem.product = cdProduct
                        cdInventoryItem.quantity = item.quantity
                        
                        if save {
                            self?.save{try in
                                handler(Try(cdInventoryItem))
                            }
                        } else {  // TODO check in other methods that receive save parameter that we also call the handler wenn save is false
                            handler(Try(cdInventoryItem))
                        }
                    }

                })
            }
        })
    }
    
    func updateInventoryItem(item: InventoryItem, handler: Try<CDInventoryItem> -> ()) {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        self.loadInventoryItem(item.product, handler: {try in
         
            if let cdInventoryItem = try.success {
                
                cdInventoryItem.quantity = item.quantity
                
                self.save {try in
                }
                
                handler(Try(cdInventoryItem))
                
            } else {
                println("ERROR invalid state - inventory item not found")
            }
        })
    }
}