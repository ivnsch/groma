//
//  Realm.swift
//  shoppin
//
//  Created by ischuetz on 01/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {

    func deleteAll<T: Object>(type: T.Type) {
        delete(objects(T))
    }
    
    func deleteForFilter<T: Object>(type: T.Type, _ filter: String) {
        delete(objects(T).filter(filter))
    }
}
