//
//  RealmProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO maybe remove the mapping toArray later if we want to stick with realm, as this can increase performance
// this would mean the provider is more coupled with realm but that's ok in this case

class RealmProvider {

    func saveObj<T: DBSyncable>(obj: T, update: Bool = false, handler: Bool -> ()) {

        let finished: (Bool) -> () = {success in
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            do {
                obj.lastUpdate = NSDate()
                let realm = try Realm()
                realm.write {
                    realm.add(obj, update: update)
                }
            } catch _ { // TODO doesn't compile when writing here (and in the other methods) ErrorType or let error as NSError, why?
                print("Error: creating Realm() in saveObj")
                finished(false)
            }
            
            finished(true)
        })
    }
    
    func saveObjs<T: DBSyncable>(objs: [T], update: Bool = false, onSaved: ((Realm) -> ())? = nil, handler: Bool -> ()) {
        
        let finished: (Bool) -> () = {success in
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

            do {
                let realm = try Realm()
                realm.write {
                    for obj in objs {
                        obj.lastUpdate = NSDate()
                        realm.add(obj, update: update)
                    }
                }
            } catch _ {
                print("Error: creating Realm() in saveObjs")
                finished(false)
            }

            finished(true)
        })
    }
    
    func loadFirst<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, handler: U? -> ()) {
        self.load(mapper, filter: filterMaybe, handler: {results in
            handler(results.first)
        })
    }
    

    
    func load<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, handler: [U] -> ()) {

        let finished: ([U]) -> () = {result in
            dispatch_async(dispatch_get_main_queue(), {
                handler(result)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            do {
                let realm = try Realm()
                
                var results = realm.objects(T)
                if let filter = filterMaybe {
                    results = results.filter(filter)
                }
                
                let objs: [T] = realm.objects(T).toArray() 
                let models = objs.map{mapper($0)}
                
                finished(models)
                
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished([]) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        })
    }
    
    func remove<T: Object>(pred: String, handler: Bool -> (), objType: T.Type) {
        
        let finished: (Bool) -> () = {success in
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                let results: Results<T> = realm.objects(T).filter(pred)
                realm.write {
                    realm.delete(results)
                }

                finished(true)

            } catch _ {
                print("Error: creating Realm() in remove")
                finished(false)
            }
        })
    }
    
    // resetLastUpdateToServer = true should be always used when this method is called for sync
    func overwrite<T: DBSyncable>(newObjects: [T], resetLastUpdateToServer: Bool = true, handler: Bool -> ()) {
        let finished: (Bool) -> () = {success in
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                let results: Results<T> = realm.objects(T)
                realm.write {
                    realm.delete(results)
                    for obj in newObjects {
                        if resetLastUpdateToServer {
                            obj.lastUpdate = obj.lastServerUpdate // for sync - this basically removes "dirty" status of item (item is not dirty when lastUpdate == lastServerUpdate)
                        } else {
                            obj.lastUpdate = NSDate()
                        }
                        
                        realm.add(obj, update: false)
                    }
                }

                finished(true)

            } catch _ {
                print("Error: creating Realm() in remove")
                finished(false)
            }
        })
    }

}
