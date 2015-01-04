//
//  CDProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData

class CDProvider: NSObject {
    
    func save() -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        var error:NSError?
        let success = appDelegate.managedObjectContext!.save(&error)
        if !success {
            println(error?.userInfo)
        }
        return success
    }
    
    func loadManagedObject<T>(id:String) -> T {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        let objectId:NSManagedObjectID? = appDelegate.persistentStoreCoordinator!.managedObjectIDForURIRepresentation(NSURL(string: id)!)
        
        let obj = appDelegate.managedObjectContext!.objectWithID(objectId!) as T
        
        return obj
    }
    
    func removeObject(object:NSManagedObject) -> Bool {
        var success = false
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        appDelegate.managedObjectContext!.deleteObject(object)
        
        var error:NSError?
        if appDelegate.managedObjectContext!.save(&error) {
            success = true
        } else {
            println(error?.userInfo)
        }
        return success
    }
}
