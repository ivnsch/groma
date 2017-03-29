//
//  Results.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

extension Results {

    /**
    Load the database result into memory
    - parameter range:optional range to load, if nil everything will be loaded
    If range is not fully contained in results count the returned array is determined by the intersection of range and results count
    If range starts beyond results count an empty array is returned
    */
    public func toArray(_ range: NSRange? = nil) -> [T] {
        
        guard (range.map{$0.location < count} ?? true) else {
            QL3("Warning: Requesting out of bounds range of results. Range: [\(String(describing: range?.location)), \(String(describing: range?.length))], results count: \(count)")
            return []
        }
        
        let start = range?.location ?? 0
        let end = range.map{r in
            let endNotTrunkated: Int = (r.location + r.length)
            return count < endNotTrunkated ? count : endNotTrunkated // note we can't use min bc Results has a min method and math min doesn't have a namespace
        } ?? count
        
        let arr: [T] = (start..<end).map {
            self[$0]
        }
        
        return arr
    }
    
    // Copied from Array extension - we need this for results also
    // mapFunc: maps element to a tuple key: value
    public func toDictionary<K: Hashable, V>(_ mapFunc: (T) -> (K, V)) -> [K: V] {
        var dict = [K: V]()
        for e in self {
            let (k, v) = mapFunc(e)
            dict[k] = v
        }
        return dict
    }
    
    public func findFirst(_ function: (_ element: T) -> Bool) -> T? {
        for e in self {
            if function(e) {
                return e
            }
        }
        return nil
    }
    
    public func splitMap<U>(_ belongs: (T) -> Bool, mapper: (T) -> U) -> (belongs: [U], notBelongs: [U]) {
        var belongsArr: [U] = []
        var notBelongsArr: [U] = []
        for element in self {
            if belongs(element) {
                belongsArr.append(mapper(element))
            } else {
                notBelongsArr.append(mapper(element))
            }
        }
        return (belongsArr, notBelongsArr)
    }
    
    // Filter + map
    // parameter f, mapping and filtering function if returns nil -> filter out
    public func collect<U>(_ f: (T) -> U?) -> [U] {
        var arr: [U] = []
        for e in self {
            if let e = f(e) {
                arr.append(e)
            }
        }
        return arr
    }
    
//    func distinctSet() -> Set<T> {
//        var set = Set<T>()
//        for element in self {
//            set.insert(element)
//        }
//        return set
//    }
    
    public func distinctArray() -> [T] {
//        var set = Set<T>()
        var array = [T]()
        for element in self {
//            if !set.contains(element) {
            if !array.contains(element) {
//                set.insert(element)
                array.append(element)
            }
        }
        return array
    }
    
    // NOTE: calls count - this may be not good for performance depending on implementation
    public subscript (safe index: Int) -> T? {
        if index < count {
            return self[index]
        } else {
            return nil
        }
    }
}

// doesn't compile... TODO why? use this if it's possible
//extension Results where T: DBSyncable {
//    
//    func dirty(dirty: Bool = true) -> String {
//        return self.filter("dirty == \(dirty)")
//    }
//}
