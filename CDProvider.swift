//
//  CDProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import CoreData

class CDProvider: NSObject {
    
    func save() -> Bool {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        var error:NSError?
        let success = appDelegate.managedObjectContext!.save(&error)
        if !success {
            println(error?.userInfo)
        }
        return success
    }
    
    func loadManagedObject<T>(id:String) -> T {
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        let objectId:NSManagedObjectID? = appDelegate.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(NSURL(string: id)!)
        
        let obj = appDelegate.managedObjectContext!.objectWithID(objectId!) as! T
        
        return obj
    }
    
    func removeObject(object:NSManagedObject) -> Bool {
        var success = false
        let appDelegate = SharedAppDelegate.getAppDelegate()
        
        appDelegate.managedObjectContext!.deleteObject(object)
        
        var error:NSError?
        if appDelegate.managedObjectContext!.save(&error) {
            success = true
        } else {
            println(error?.userInfo)
        }
        return success
    }
    
    func load<T:AnyObject>(#entityName:String, type:T.Type, predicate predicateMaybe:NSPredicate? = nil, sortDescriptors sortDescriptorsMaybe:[NSSortDescriptor]? = nil) -> [T] {
        let fetchRequest = NSFetchRequest()
        let appDelegate = SharedAppDelegate.getAppDelegate()
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: appDelegate.managedObjectContext!)
        fetchRequest.entity = entity
        
        if let predicate = predicateMaybe {
            fetchRequest.predicate = predicate
        }
        
        if let sortDescriptors = sortDescriptorsMaybe {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        
        var error:NSError?
        let obj = appDelegate.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as! [T]
        
        return obj
    }
}
