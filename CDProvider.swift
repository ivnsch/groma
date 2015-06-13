//
//  CDProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import CoreData

class CDProvider: NSObject {
    
    func save(handler: Try<Bool> -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            

            
            dispatch_async(dispatch_get_main_queue(), {
                
                let appDelegate = SharedAppDelegate.getAppDelegate()
                var error:NSError?
                let success = appDelegate.managedObjectContext!.save(&error) // TODO do this in the background, currently crashes if in background http://stackoverflow.com/a/9347736/930450
                if !success {
                    println("Error: CDProvider couldn't save")
                    println(error?.userInfo)
                }
                
                
                
                handler(Try(success))
            })
        })
    }
    
    func removeObject(object: NSManagedObject, handler: Try<Bool> -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
          
            var success = false
            let appDelegate = SharedAppDelegate.getAppDelegate()
            
            appDelegate.managedObjectContext!.deleteObject(object)
            
            var error:NSError?
            if appDelegate.managedObjectContext!.save(&error) {
                success = true
            } else {
                println(error?.userInfo)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(Try(success))
            })
        })
    }
    
    func load<T:AnyObject>(#entityName: String, type: T.Type, predicate predicateMaybe: NSPredicate? = nil, sortDescriptors sortDescriptorsMaybe: [NSSortDescriptor]? = nil, handler: Try<[T]> -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        
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
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(Try(obj))
            })
        })
    }
}
