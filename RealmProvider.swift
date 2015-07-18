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

    func saveObj<T: Object>(obj: T, update: Bool = false, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            realm.write {
                realm.add(obj, update: update)
            }
            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }
    
    func saveObjs<T: Object>(objs: [T], update: Bool = false, handler: Bool -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            realm.write {
                for obj in objs {
                    realm.add(obj, update: update)
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }
    
    func load<T: Object, U>(mapper: T -> U, filter filterMaybe: String? = nil, handler: [U] -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            var results = Realm().objects(T)
            if let filter = filterMaybe {
                results = results.filter(filter)
            }
            
            let objs: [T] = Realm().objects(T).toArray()
            let models = objs.map{mapper($0)}
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(models)
            })
        })
    }
    
    func remove<T: Object>(pred: String, handler: Bool -> (), objType: T.Type) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let realm = Realm()
            let results: Results<T> = realm.objects(T).filter(pred)
            realm.write {
                realm.delete(results)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                handler(true)
            })
        })
    }
}
