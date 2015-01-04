//
//  CDInventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import CoreData

class CDInventoryProvider: CDProvider {
    
    func loadInventory() -> [CDInventoryItem] {
        
        let fetchRequest = NSFetchRequest()
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let entity = NSEntityDescription.entityForName("CDInventoryItem", inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.entity = entity
        
        var error:NSError?
        let inventory = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as [CDInventoryItem]
        
        return inventory
    }
}