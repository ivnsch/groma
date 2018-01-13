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
    
    func write(withoutNotifying: [NotificationToken] = [], f: (Realm) -> Void) throws {
        beginWrite()
        f(self)
        try commitWrite(withoutNotifying: withoutNotifying)
    }

    // When doing a transaction in a notification block there's a "already in a write transaction" crash, because apparently this block is called before the current transaction finishes.
    // So this does a transaction only if there's no transaction in progress yet.
    // Note that this applies to realms in the same tread, i.e. there can be only one transaction per thread.
    // See https://github.com/realm/realm-cocoa/issues/4511#issuecomment-270962198
    func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }

    func deleteAll<T: Object>(_ type: T.Type) {
        delete(objects(T.self))
    }
    
    func deleteForFilter<T: Object>(_ type: T.Type, _ filter: String) {
        delete(objects(T.self).filter(filter))
    }
}
