//
//  CDProvider.swift
//  shoppin
//
//  Created by ischuetz on 13.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import CoreData

class CDProvider: NSObject {
    
    func save(handler: Try<Bool> -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            

            
            dispatch_async(dispatch_get_main_queue(), {
                
                var error:NSError?
                let success = PersistentStoreHelper.sharedInstance.managedObjectContext!.save(&error) // TODO do this in the background, currently crashes if in background http://stackoverflow.com/a/9347736/930450
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
            
            PersistentStoreHelper.sharedInstance.managedObjectContext!.deleteObject(object)
            
            var error:NSError?
            if PersistentStoreHelper.sharedInstance.managedObjectContext!.save(&error) {
                success = true
            } else {
                println(error?.userInfo)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(Try(success))
            })
        })
    }
    
    func removeAll(entityName: String, predicate predicateMaybe: NSPredicate? = nil, save: Bool, handler: Try<Bool> -> ()) {
        
        let context = PersistentStoreHelper.sharedInstance.managedObjectContext!
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
        fetchRequest.includesPropertyValues = false
        
        if let predicate = predicateMaybe {
            fetchRequest.predicate = predicate
        }
        
        var error:NSError?
        if let results = context.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject] {
            for result in results {
                context.deleteObject(result)
            }
            
            if save {
                var error:NSError?
                if context.save(&error) {
                    handler(Try(true))
                    
                } else if let error = error {
                    println(error.userInfo)
                    handler(Try(error))
                }
                
            } else {
                handler(Try(true))
            }

        } else if let error = error {
            println(error.userInfo)
            handler(Try(error))
            
        } else {
            println("Error: removeAll - results is nil")
            // TODO is this really an error, if yes handle appropiately otherwise return success
        }
    }
    
    func load<T:AnyObject>(#entityName: String, type: T.Type, predicate predicateMaybe: NSPredicate? = nil, sortDescriptors sortDescriptorsMaybe: [NSSortDescriptor]? = nil, handler: Try<[T]> -> ()) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        
            let fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: PersistentStoreHelper.sharedInstance.managedObjectContext!)
            fetchRequest.entity = entity
            
            if let predicate = predicateMaybe {
                fetchRequest.predicate = predicate
            }
            
            if let sortDescriptors = sortDescriptorsMaybe {
                fetchRequest.sortDescriptors = sortDescriptors
            }
            
            var error:NSError?
            let obj = PersistentStoreHelper.sharedInstance.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error) as! [T]
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(Try(obj))
            })
        })
    }
}
