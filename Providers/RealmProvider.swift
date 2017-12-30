//
//  RealmProvider.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

enum DBProviderResult {
    case success
    case nameAlreadyExists
    case unknown

    var isSuccess: Bool {
        return self == .success
    }

    var providerStatus: ProviderStatusCode {
        switch self {
        case .success: return .success
        case .nameAlreadyExists: return .nameAlreadyExists
        case .unknown: return .databaseUnknown
        }
    }
}


// TODO maybe remove the mapping toArray later if we want to stick with realm, as this can increase performance
// this would mean the provider is more coupled with realm but that's ok in this case

// TODO!! currently there's no way for the client to know there was an error in realm - it will return either empty array or nil, being equivalent with "not found"
// do we really want this? or rather return also a status code (at least maybe an "either") so client can show error accordingly? Or maybe it's enough to send error to error tracking?
class RealmProvider {

    func saveObj<T: DBSyncable>(_ obj: T, update: Bool = false, handler: @escaping (Bool) -> ()) {
        DispatchQueue.global(qos: .background).async {[weak self] in
            let resultMaybe = self?.saveObjSync(obj, update: update)
            DispatchQueue.main.async(execute: {
                if let result = resultMaybe {
                    handler(result)
                } else {
                    logger.e("self is nil")
                    handler(false)
                }
            })
        }
    }
    
    func saveObjSync<T: DBSyncable>(_ obj: T, update: Bool = false) -> Bool {
        do {
//            obj.lastUpdate = NSDate()
            let realm = try RealmConfig.realm()
            try realm.write {
                realm.add(obj, update: update)
            }
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return false
        } catch let error {
            logger.e("Realm error: \(error)")
            return false
        }
        return true
    }

    /**
    * Batch save
    */
    func saveObjs<T: Object>(_ objs: [T], update: Bool = false, onSaved: ((Realm) -> ())? = nil, handler: @escaping (Bool) -> ()) {
        DispatchQueue.global(qos: .background).async {[weak self] in
            let resultMaybe = self?.saveObjsSync(objs, update: update)
            DispatchQueue.main.async(execute: {
                if let result = resultMaybe {
                    handler(result)
                } else {
                    logger.e("self is nil")
                    handler(false)
                }
            })
        }
    }
    
    func saveObjsSync<T: Object>(_ objs: [T], update: Bool = false) -> Bool {
        do {
            let realm = try RealmConfig.realm()
            try realm.write {
                saveObjsSyncInt(realm, objs: objs, update: update)
            }
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return false
        } catch let error {
            logger.e("Realm error: \(error)")
            return false
        }
        return true
    }
    
    // expected to be called in transaction and do catch block
    // Suffix "Int" like "internal" to differentiate from "Sync" that contains also creation of Realm / error handling
    func saveObjsSyncInt<T: Object>(_ realm: Realm, objs: [T], update: Bool = false) {
        for obj in objs {
            realm.add(obj, update: update)
        }
    }
    
    /**
    * Batch save, refreshing last update date
    */
    func saveObjs<T: DBSyncable>(_ objs: [T], update: Bool = false, onSaved: ((Realm) -> ())? = nil, handler: @escaping (Bool) -> ()) {
        doInWriteTransaction({realm -> Bool in
            for obj in objs {
                realm.add(obj, update: update)
            }
            return true
            
        }) {successMaybe in
            handler(successMaybe ?? false)
        }
    }

    func loadFirst<T: Object, U>(_ mapper: @escaping (T) -> U, filter filterMaybe: String? = nil, handler: @escaping (U?) -> ()) {
        self.load(mapper, filter: filterMaybe, handler: {results in
            if results.count > 1 {
                logger.d("Multiple items found in load first \(String(describing: filterMaybe))") // sometimes we expect only 1 item to be in the database, log this just in case
            }
            handler(results.first)
        })
    }
    
    //////////////////////

    // TODO range: can't we just subscript result instead of do this programmatically (take a look into https://github.com/realm/realm-cocoa/issues/1904)
    func load<T: Object>(predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, handler: @escaping (Results<T>?) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let result: Results<T>? = self.loadSync(predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe)
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
    }
    
    func load<T: Object>(filter filterMaybe: String? = nil, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, handler: @escaping (Results<T>?) -> Void) {
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        load(predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, handler: handler)
    }
    
    
    func loadSync<T: Object>(predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil) -> Results<T>? {
        do {
            let realm = try RealmConfig.realm()
            let results: Results<T> = self.loadSync(realm, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe)
            return results
            
        } catch let e {
            logger.e("Error: creating Realm, returning empty results, error: \(e)")
            return nil
        }
    }
    
    func loadSync<T: Object>(filter filterMaybe: String?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil) -> Results<T>? {
        return loadSync(filter: filterMaybe, sortDescriptors: sortDescriptorMaybe.flatMap{sc in sc.key.map{[SortDescriptor(keyPath: $0, ascending: sc.ascending)]}} ?? [])
    }
    
    func loadSync<T: Object>(filter filterMaybe: String?, sortDescriptors: [SortDescriptor]) -> Results<T>? {
        do {
            let realm = try RealmConfig.realm()
            return loadSync(realm, filter: filterMaybe, sortDescriptors: sortDescriptors)
            
        } catch let e {
            logger.e("Error: creating Realm, returning empty results, error: \(e)")
            return nil
        }
    }
    
    func loadSync<T: Object>(_ realm: Realm, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil) -> Results<T> {
//        var results = realm.objects(T.self)
//        if let predicate = predicateMaybe {
//            results = results.filter(predicate)
//        }
//        if let sortDescriptor = sortDescriptorMaybe, let key = sortDescriptor.key {
//            results = results.sorted(byProperty: key, ascending: sortDescriptor.ascending)
//        }
//        
//        return results
        
        return loadSync(realm, predicate: predicateMaybe, sortDescriptors: sortDescriptorMaybe.flatMap{sc in sc.key.map{[SortDescriptor(keyPath: $0, ascending: sc.ascending)]}} ?? [])
    }
    
    func loadSync<T: Object>(_ realm: Realm, predicate predicateMaybe: NSPredicate?, sortDescriptors: [SortDescriptor]) -> Results<T> {
        var results = realm.objects(T.self)
        if let predicate = predicateMaybe {
            results = results.filter(predicate)
        }
        results = results.sorted(by: sortDescriptors)
        
        return results
    }

    func loadSync<T: Object>(_ realm: Realm, filter filterMaybe: String?, sortDescriptor sortDescriptorMaybe: SortDescriptor? = nil) -> Results<T> {
        return self.loadSync(realm, filter: filterMaybe, sortDescriptors: sortDescriptorMaybe.map{[$0]} ?? [])
    }
    
    func loadSync<T: Object>(_ realm: Realm, filter filterMaybe: String?, sortDescriptors: [SortDescriptor]) -> Results<T> {
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        return self.loadSync(realm, predicate: predicateMaybe, sortDescriptors: sortDescriptors)
    }
    
    func loadFirstSync<T: Object>(filter filterMaybe: String? = nil) -> T? {
        return loadSync(filter: filterMaybe, sortDescriptor: nil)?.first
    }
    
    //////////////////////
    // Load array without mapper
    // Special methods (with repeated code) for this, since on one side we want to do the conversion to array in the background together with loading the objs (so we can't use the methods that return Results) and on the other it was not possible to adjust the methods that return arrays and use mapper to make mapper optional. There seem to be a problem with the returned type "U" of the objects being the same as "T". TODO try to adjust methods with mapper. Or refactor in some other way.
    
    func load<T: Object>(predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: @escaping ([T]) -> Void) {
        
        let finished: ([T]) -> Void = {result in
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
        
        DispatchQueue.global(qos: .background).async {
            
            do {
                let realm = try RealmConfig.realm()
                let models: [T] = self.loadSync(realm, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
                finished(models)
                
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                finished([]) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
    }
    
    func loadSync<T: Object>(_ realm: Realm, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [T] {
        var results = realm.objects(T.self)
        if let predicate = predicateMaybe {
            results = results.filter(predicate)
        }
        if let sortDescriptor = sortDescriptorMaybe, let key = sortDescriptor.key {
            results = results.sorted(byKeyPath: key, ascending: sortDescriptor.ascending)
        }
        
        return results.toArray(rangeMaybe)
    }
    
    func loadSync<T: Object>(_ realm: Realm, filter filterMaybe: String?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [T] {
        
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        return loadSync(realm, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
    }
    
    func load<T: Object>(filter filterMaybe: String? = nil, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: @escaping ([T]) -> Void) {
        
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        load(predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe, handler: handler)
    }
    
    //////////////////////
    
    // TODO range: can't we just subscript result instead of do this programmatically (take a look into https://github.com/realm/realm-cocoa/issues/1904)
    func load<T: Object, U>(_ mapper: @escaping (T) -> U, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: @escaping ([U]) -> ()) {
        
        let finished: ([U]) -> () = {result in
            DispatchQueue.main.async(execute: {
                handler(result)
            })
        }
        
        DispatchQueue.global(qos: .background).async {
            
            do {
                let realm = try RealmConfig.realm()
                let models = self.loadSync(realm, mapper: mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
                finished(models)
                
            } catch let e {
                logger.e("Error: creating Realm, returning empty results, error: \(e)")
                finished([]) // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
    }
    
    func loadSync<T: Object, U>(_ realm: Realm, mapper: @escaping (T) -> U, predicate predicateMaybe: NSPredicate?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [U] {
        var results = realm.objects(T.self)
        if let predicate = predicateMaybe {
            results = results.filter(predicate)
        }
        if let sortDescriptor = sortDescriptorMaybe, let key = sortDescriptor.key {
            results = results.sorted(byKeyPath: key, ascending: sortDescriptor.ascending)
        }
        
        let objs: [T] = results.toArray(rangeMaybe)
        return objs.map{mapper($0)}
    }

    func loadSync<T: Object, U>(_ realm: Realm, mapper: @escaping (T) -> U, filter filterMaybe: String?, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil) -> [U] {
        
        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        return self.loadSync(realm, mapper: mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe)
    }
    
    func load<T: Object, U>(_ mapper: @escaping (T) -> U, filter filterMaybe: String? = nil, sortDescriptor sortDescriptorMaybe: NSSortDescriptor? = nil, range rangeMaybe: NSRange? = nil, handler: @escaping ([U]) -> ()) {

        let predicateMaybe = filterMaybe.map {
            NSPredicate(format: $0, argumentArray: [])
        }
        
        self.load(mapper, predicate: predicateMaybe, sortDescriptor: sortDescriptorMaybe, range: rangeMaybe, handler: handler)
    }
    
    // WARN: passing nil as pred will remove ALL objects of objType
    // additionalActions: optional actions to be executed after delete in the same transaction
    func remove<T: Object>(_ pred: String?, handler: @escaping (Bool) -> (), objType: T.Type, additionalActions: ((Realm) -> Void)? = nil) {
        
        let finished: (Bool) -> () = {success in
            DispatchQueue.main.async(execute: {
                handler(success)
            })
        }
        
        DispatchQueue.global(qos: .background).async {[weak self] in guard let weakSelf = self else {return}
            finished(weakSelf.removeSync(pred, objType: objType, additionalActions: additionalActions))
        }
    }

    func removeSync<T: Object>(_ pred: String?, objType: T.Type, additionalActions: ((Realm) -> Void)? = nil) -> Bool {
        do {
            let realm = try RealmConfig.realm()
            return removeSync(realm, pred: pred, objType: objType, additionalActions: additionalActions)
        } catch let error {
            logger.e("Realm error: \(error)")
            return false
        }
    }

    func removeSync<T: Object>(_ realm: Realm, pred: String?, objType: T.Type, additionalActions: ((Realm) -> Void)? = nil) -> Bool {
        do {
            var results: Results<T> = realm.objects(T.self)
            if let pred = pred {
                results = results.filter(pred)
            }
            try realm.write {
                realm.delete(results)
                additionalActions?(realm)
            }
            
            return true
            
        } catch let error {
            logger.e("Realm error: \(error)")
            return false
        }
    }

    // WARN: passing nil as pred will remove ALL objects of objType
    // additionalActions: optional actions to be executed after delete in the same transaction
    // Returns count of removed items or nil if there was an error.
    func removeReturnCount<T: Object>(_ pred: String?, handler: @escaping (Int?) -> Void, objType: T.Type, additionalActions: ((Realm) -> Void)? = nil) {
        doInWriteTransaction({[weak self] realm in
            return self?.removeReturnCountSync(realm, pred: pred, objType: objType, additionalActions: additionalActions)
        }, finishHandler: {countMaybe in
            handler(countMaybe)
        })
    }
    
    func removeReturnCountSync<T: Object>(_ pred: String?, objType: T.Type, realmData: RealmData?, doTransaction: Bool = true, additionalActions: ((Realm) -> Void)? = nil) -> Int? {
        
        func transactionContent(realm: Realm) -> Int? {
            return removeReturnCountSync(realm, pred: pred, objType: objType, additionalActions: additionalActions)
        }
        
        if doTransaction {
            return doInWriteTransactionSync(realmData: realmData) {realm in
                return transactionContent(realm: realm)
            }
        } else {
            if let realm = realmData?.realm {
                return transactionContent(realm: realm)
            } else {
                logger.e("Invalid state: when do own transaction == false a realm should be passed")
                return nil
            }
        }
    }
    
    // Expects to be executed in a transaction
    func removeReturnCountSync<T: Object>(_ realm: Realm, pred: String?, objType: T.Type, additionalActions: ((Realm) -> Void)? = nil) -> Int? {
        var results: Results<T> = realm.objects(T.self)
        if let pred = pred {
            results = results.filter(pred)
        }
        
        let count = results.count
        
        realm.delete(results)
        additionalActions?(realm)
        
        return count
    }
    
    func doInWriteTransaction<T>(withoutNotifying: [NotificationToken] = [], realm: Realm? = nil, _ f: @escaping (Realm) -> T?, finishHandler: @escaping (T?) -> Void) {
        
        let finished: (T?) -> Void = {obj in
            DispatchQueue.main.async(execute: {
                finishHandler(obj)
            })
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                let realm = try realm ?? RealmConfig.realm()
                var obj: T?
                try realm.write(withoutNotifying: withoutNotifying) {_ in 
                    obj = f(realm)
                }
                finished(obj)
                
            } catch let error as NSError {
                logger.e("Realm error: \(error)")
                finished(nil)
            } catch let error {
                logger.e("Realm error: \(error)")
                finished(nil)
            }
        }
    }

    func doInWriteTransactionSync<T>(realmData: RealmData?, _ f: (Realm) -> T?) -> T? {
        do {
            let realm = try realmData?.realm ?? RealmConfig.realm()
            return doInWriteTransactionWithRealmSync(withoutNotifying: realmData.map{[$0.token]} ?? [], realm, f: f)
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return nil
        } catch let error {
            logger.e("Realm error: \(error)")
            return nil
        }
    }
    
    // TODO refactor with doInWriteTransactionSync(realmData...)
    func doInWriteTransactionSync<T>(withoutNotifying: [NotificationToken] = [], realm: Realm? = nil, _ f: (Realm) -> T?) -> T? {
        do {
            let realm = try realm ?? RealmConfig.realm()
            return doInWriteTransactionWithRealmSync(withoutNotifying: withoutNotifying, realm, f: f)
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return nil
        } catch let error {
            logger.e("Realm error: \(error)")
            return nil
        }
    }
    
// TODO remove?
//    func commitWrite(object: Object, withoutNotifying: [NotificationToken] = []) -> Bool {
//        do {
//            guard let realm = object.realm else {
//                logger.e("Object has no realm: \(object), isInvalidated: \(object.isInvalidated)")
//                return false
//            }
//            try realm.commitWrite(withoutNotifying: [])
//            return true
//        } catch let error {
//            logger.e("Realm error: \(error)")
//            return false
//        }
//    }
    
    func doInWriteTransactionWithRealmSync<T>(withoutNotifying: [NotificationToken] = [], _ realm: Realm, f: (Realm) -> T?) -> T? {
        do {
            var obj: T?
            try realm.write(withoutNotifying: withoutNotifying) {_ in
                obj = f(realm)
            }
            return obj
            
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return nil
        } catch let error {
            logger.e("Realm error: \(error)")
            return nil
        }
    }
    
    func withRealm<T>(_ f: @escaping (Realm) throws -> T?, resultHandler: @escaping (T?) -> Void) {
        background({[weak self] in
            return self?.withRealmSync(f)
            }) { (result: T?) in
                resultHandler(result)
        }
    }
    
    func withRealmSync<T>(realm: Realm? = nil, _ f: (Realm) throws -> T?) -> T? {
        do {
            return try f(realm ?? RealmConfig.realm())
        } catch let error as NSError {
            logger.e("Realm error: \(error)")
            return nil
        } catch let error {
            logger.e("Realm error: \(error)")
            return nil
        }
    }
    
    // resetLastUpdateToServer = true should be always used when this method is called for sync. TODO no resetLastUpdateToServer default = true, it's better to pass it explicitly
    // additionalActions: optional additional actions to be executed in the transaction
    func overwrite<T: Sequence>(_ newObjects: T, deleteFilter deleteFilterMaybe: String? = nil, resetLastUpdateToServer: Bool = true, idExtractor: @escaping (T.Iterator.Element) -> String, additionalActions: ((Realm) -> Void)? = nil, handler: @escaping (Bool) -> ()) where T.Iterator.Element: DBSyncable {
        
        self.doInWriteTransaction({realm in
            
            var results: Results<T.Iterator.Element> = realm.objects(T.Iterator.Element.self)

            if let filter = deleteFilterMaybe {
                results = results.filter(filter)
            }
            
            // Collect the stored items that are not in the updated items to delete them. Note that we can't just call delete on the results, as even when we write the same items after it in the same transaction the references to the them (from other objects) will be set to nil.
            var toDeleteDict = results.toDictionary{(idExtractor($0), $0)}
            
            for obj in newObjects {
                if resetLastUpdateToServer {
//                    obj.lastUpdate = obj.lastServerUpdate
                    obj.dirty = false
                    
                } else {
//                    obj.lastUpdate = NSDate()
                }
                
                realm.add(obj, update: true) // update: true just in case some dependencies have repeated data (e.g. a shared user), if false the second shared user with same unique causes an exception
                toDeleteDict.removeValue(forKey: idExtractor(obj))
            }
            
            for val in toDeleteDict.values {
                val.deleteWithDependenciesSync(realm, markForSync: !resetLastUpdateToServer)
            }
            
            additionalActions?(realm)
            
            return true
            
        }, finishHandler: {saved in
            handler(saved ?? false)
        })
    }
    
    func refresh() {
        do {
            let realm = try RealmConfig.realm()
            realm.refresh()
        } catch let e {
            logger.e("Couldn't refresh realm, error: \(e)")
        }
    }
}
