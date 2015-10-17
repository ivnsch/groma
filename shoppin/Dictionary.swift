//
//  Dictionary.swift
//  shoppin
//
//  Created by ischuetz on 10/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func map<T>(f: ((Key, Value)) -> ((Key, T))) -> Dictionary<Key, T> {
        var dict: Dictionary<Key, T> = Dictionary<Key, T>()
        for (k, v) in self {
            let mapped = f(k, v)
            dict[mapped.0] = mapped.1
        }
        return dict
    }
}


// TODO is there a way we can get this extension to work
// the idea is when having a dictionary with arrays as values, be able to either append to existing array for a key or insert a new entry
//extension Dictionary where Value: Array<T> {
//
//    mutating func appendOrInsert(key: Key, value: T) {
//        // TODO more elegant way to write this?
//        if self[key] != nil {
//            self[key]!.append(value)
//        } else {
//            self[key] = []
//        }
//    }
//}