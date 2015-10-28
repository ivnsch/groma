//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension Array {
    func forEach<U>(function: (element: Element) -> U) {
        for e in self {
            function(element: e)
        }
    }
    
    func findFirst(function: (element: Element) -> Bool) -> Element? {
        for e in self {
            if function(element: e) {
                return e
            }
        }
        return nil
    }
    
    // src: http://stackoverflow.com/a/30593673/930450
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
    
    // Filters a list and maps in the same iteration.
    // Reduce could also be used for this, but this has better performance.
    func filterMap<T>(filterFunc: Element -> Bool, mapFunc: Element -> T) -> [T] {
        var arr: [T] = []
        for e in self {
            if filterFunc(e) {
                arr.append(mapFunc(e))
            }
        }
        return arr
    }

    func toDictionary<K: Hashable, V>(mapFunc: Element -> (K, V)) -> [K: V] {
        var dict = [K: V]()
        for e in self {
            let (k, v) = mapFunc(e)
            dict[k] = v
        }
        return dict
    }
}


extension Array where Element: Identifiable {
    
    /**
    Replaces first element with same identity with element
    */
    mutating func update(element: Element) {
        for i in 0..<self.count {
            if self[i].same(element) {
                self[i] = element
            }
        }
    }
}

extension Array where Element: Equatable {
    
    // safe element removal
    mutating func remove(element: Element) {
        if let index = self.indexOf(element) {
            self.removeAtIndex(index)
        }
    }
}