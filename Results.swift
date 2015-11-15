//
//  Results.swift
//  shoppin
//
//  Created by ischuetz on 14/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

extension Results {

    /**
    Load the database result into memory
    - parameter range:optional range to load, if nil everything will be loaded
    If range is not fully contained in results count the returned array is determined by the intersection of range and results count
    If range starts beyond results count an empty array is returned
    */
    func toArray(range: NSRange? = nil) -> [T] {
        
        guard range?.location < count else {
            print("Warning: Requesting out of bounds range of results. Range: \(range), results count: \(count)")
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
    func toDictionary<K: Hashable, V>(mapFunc: T -> (K, V)) -> [K: V] {
        var dict = [K: V]()
        for e in self {
            let (k, v) = mapFunc(e)
            dict[k] = v
        }
        return dict
    }
    
    func findFirst(function: (element: T) -> Bool) -> T? {
        for e in self {
            if function(element: e) {
                return e
            }
        }
        return nil
    }
    
}

extension RealmSwift.List {
    
    func toArray() -> [T] {
        return self.map{$0}
    }
}

