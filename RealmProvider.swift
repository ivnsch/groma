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
            } catch let error as NSError {
                print("Error: creating Realm() in saveObj: \(error)")
                finished(false)
            } catch _ {
                print("Error: creating Realm() in saveObj (unknown)")
                finished(false)
            }
            
            finished(true)
        })
    }

    /**
    * Batch save
    */
    func saveObjs<T: Object>(objs: [T], update: Bool = false, onSaved: ((Realm) -> ())? = nil, handler: Bool -> ()) {
        
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
                        realm.add(obj, update: update)
                    }
                }
            } catch let error as NSError {
                print("Error: creating Realm() in saveObjs: \(error)")
                finished(false)
            } catch _ {
                print("Error: creating Realm() in saveObjs (unknown)")
                finished(false)
            }
            
            finished(true)
        })
    }
    
    /**
    * Batch save, refreshing last update date
    */
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
            } catch let error as NSError {
                print("Error: creating Realm() in saveObjs: \(error)")
                finished(false)
            } catch _ {
                print("Error: creating Realm() in saveObjs (unknown)")
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
    
    // TODO range: can't we just subscript result instead of do this programmatically (take a look into https://github.com/realm/realm-cocoa/issues/1904)
    func load<T: Object, U>(mapper: T -> U, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: [U] -> ()) {
        
        let finished: ([U]) -> () = {result in
            dispatch_async(dispatch_get_main_queue(), {
                handler(result)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            do {
                let realm = try Realm()
                let models = self.loadSync(realm, mapper: mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
                finished(models)
                
            } catch _ {
                print("Error: creating Realm() in load, returning empty results")
                finished([]) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        })
    }
    
    func loadSync<T: Object, U>(realm: Realm, mapper: T -> U, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [U] {
        var results = realm.objects(T)
        if let predicate = predicateMaybe {
            results = results.filter(predicate)
        }
        if let sortDescriptor = sortDescriptorMaybe, key = sortDescriptor.key {
            results = results.sorted(key, ascending: sortDescriptor.ascending)
        }
        
        let objs: [T] = results.toArray(rangeMaybe)
        return objs.map{mapper($0)}
    }

    func loadSync<T: Object, U>(realm: Realm, mapper: T -> U, filter filterMaybe: String?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [U] {
        
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        return self.loadSync(realm, mapper: mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
    }
    
    func load<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: [U] -> ()) {

        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        self.load(mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe, handler: handler)
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
    
    func doInWriteTransaction<T>(f: Realm -> T?, finishHandler: T? -> Void) {
        
        let finished: T? -> Void = {obj in
            dispatch_async(dispatch_get_main_queue(), {
                finishHandler(obj)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                var obj: T?
                realm.write {
                    obj = f(realm)
                }
                finished(obj)
                
            } catch let error as NSError {
                print("Error: creating Realm() in doInWriteTransaction: \(error)")
                finished(nil)
            } catch _ {
                print("Error: creating Realm() in doInWriteTransaction (unknown)")
                finished(nil)
            }
        })
    }

    func doInWriteTransactionSync<T>(f: Realm -> T?) -> T? {
        do {
            let realm = try Realm()

            var obj: T?
            realm.write {
                obj = f(realm)
            }
            return obj
            
        } catch let error as NSError {
            print("Error: creating Realm() in doInWriteTransaction: \(error)")
            return nil
        } catch _ {
            print("Error: creating Realm() in doInWriteTransaction (unknown)")
            return nil
        }
    }
    
    // resetLastUpdateToServer = true should be always used when this method is called for sync
    func overwrite<T: DBSyncable>(newObjects: [T], resetLastUpdateToServer: Bool = true, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            let results: Results<T> = realm.objects(T)

            realm.delete(results)
            for obj in newObjects {
                if resetLastUpdateToServer {
                    obj.lastUpdate = obj.lastServerUpdate

                } else {
                    obj.lastUpdate = NSDate()
                }
                
                realm.add(obj, update: false)
            }
            return true
            
        }, finishHandler: {saved in
            handler(saved ?? false)
        })
    }
}
