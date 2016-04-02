//
//  RealmProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

// TODO maybe remove the mapping toArray later if we want to stick with realm, as this can increase performance
// this would mean the provider is more coupled with realm but that's ok in this case

// TODO!! currently there's no way for the client to know there was an error in realm - it will return either empty array or nil, being equivalent with "not found"
// do we really want this? or rather return also a status code (at least maybe an "either") so client can show error accordingly? Or maybe it's enough to send error to error tracking?
class RealmProvider {

    func saveObj<T: DBSyncable>(obj: T, update: Bool = false, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            let resultMaybe = self?.saveObjSync(obj, update: update)
            dispatch_async(dispatch_get_main_queue(), {
                if let result = resultMaybe {
                    handler(result)
                } else {
                    QL4("self is nil")
                    handler(false)
                }
            })
        })
    }
    
    func saveObjSync<T: DBSyncable>(obj: T, update: Bool = false) -> Bool {
        do {
            obj.lastUpdate = NSDate()
            let realm = try Realm()
            try realm.write {
                realm.add(obj, update: update)
            }
        } catch let error as NSError {
            QL4("Realm error: \(error)")
            return false
        } catch let error {
            QL4("Realm error: \(error)")
            return false
        }
        return true
    }

    /**
    * Batch save
    */
    func saveObjs<T: Object>(objs: [T], update: Bool = false, onSaved: ((Realm) -> ())? = nil, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            let resultMaybe = self?.saveObjsSync(objs, update: update)
            dispatch_async(dispatch_get_main_queue(), {
                if let result = resultMaybe {
                    handler(result)
                } else {
                    QL4("self is nil")
                    handler(false)
                }
            })
        })
    }
    
    func saveObjsSync<T: Object>(objs: [T], update: Bool = false) -> Bool {
        do {
            let realm = try Realm()
            try realm.write {
                saveObjsSyncInt(realm, objs: objs, update: update)
            }
        } catch let error as NSError {
            QL4("Realm error: \(error)")
            return false
        } catch let error {
            QL4("Realm error: \(error)")
            return false
        }
        return true
    }
    
    // expected to be called in transaction and do catch block
    // Suffix "Int" like "internal" to differentiate from "Sync" that contains also creation of Realm / error handling
    func saveObjsSyncInt<T: Object>(realm: Realm, objs: [T], update: Bool = false) {
        for obj in objs {
            realm.add(obj, update: update)
        }
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
                try realm.write {
                    for obj in objs {
                        obj.lastUpdate = NSDate()
                        realm.add(obj, update: update)
                    }
                }
            } catch let error as NSError {
                QL4("Realm error: \(error)")
                finished(false)
            } catch let error {
                QL4("Realm error: \(error)")
                finished(false)
            }

            finished(true)
        })
    }

    func loadFirst<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, handler: U? -> ()) {
        self.load(mapper, filter: filterMaybe, handler: {results in
            if results.count > 1 {
                QL3("Multiple items found in load first \(filterMaybe)") // usually when we call loadFirst we expect only 1 item to be in the database, so a warning just in case
            }
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
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
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
    
    // WARN: passing nil as pred will remove ALL objects of objType
    // additionalActions: optional actions to be executed after delete in the same transaction
    func remove<T: Object>(pred: String?, handler: Bool -> (), objType: T.Type, additionalActions: (Realm -> Void)? = nil) {
        
        let finished: (Bool) -> () = {success in
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            do {
                let realm = try Realm()
                var results: Results<T> = realm.objects(T)
                if let pred = pred {
                    results = results.filter(pred)
                }
                try realm.write {
                    realm.delete(results)
                    additionalActions?(realm)
                }
                
                finished(true)

            } catch let error {
                QL4("Realm error: \(error)")
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
                try realm.write {
                    obj = f(realm)
                }
                finished(obj)
                
            } catch let error as NSError {
                QL4("Realm error: \(error)")
                finished(nil)
            } catch let error {
                QL4("Realm error: \(error)")
                finished(nil)
            }
        })
    }

    func doInWriteTransactionSync<T>(f: Realm -> T?) -> T? {
        do {
            let realm = try Realm()

            var obj: T?
            try realm.write {
                obj = f(realm)
            }
            return obj
            
        } catch let error as NSError {
            QL4("Realm error: \(error)")
            return nil
        } catch let error {
            QL4("Realm error: \(error)")
            return nil
        }
    }
    
    func withRealm<T>(f: Realm -> T?, resultHandler: T? -> Void) {
        background({
            do {
                let realm = try Realm()
                return f(realm)
                
            } catch let error as NSError {
                QL4("Realm error: \(error)")
                return nil
            } catch let error {
                QL4("Realm error: \(error)")
                return nil
            }
            }) { (result: T?) in
                resultHandler(result)
        }
    }
    
    
    // resetLastUpdateToServer = true should be always used when this method is called for sync. TODO no resetLastUpdateToServer default = true, it's better to pass it explicitly
    // additionalActions: optional additional actions to be executed in the transaction
    func overwrite<T: DBSyncable>(newObjects: [T], deleteFilter deleteFilterMaybe: String? = nil, resetLastUpdateToServer: Bool = true, additionalActions: (Realm -> Void)? = nil, handler: Bool -> ()) {
        
        self.doInWriteTransaction({realm in
            
            var results: Results<T> = realm.objects(T)

            if let filter = deleteFilterMaybe {
                results = results.filter(filter)
            }
            
            realm.delete(results)
            for obj in newObjects {
                if resetLastUpdateToServer {
                    obj.lastUpdate = obj.lastServerUpdate // TODO remove lastUpdate (and rename resetLastUpdateToServer accordingly, maybe resetDirty)? we now have dirty
                    obj.dirty = false
                    
                } else {
                    obj.lastUpdate = NSDate()
                }
                
                realm.add(obj, update: true) // update: true just in case some dependencies have repeated data (e.g. a shared user), if false the second shared user with same unique causes an exception
            }
            
            additionalActions?(realm)
            
            return true
            
        }, finishHandler: {saved in
            handler(saved ?? false)
        })
    }
}
