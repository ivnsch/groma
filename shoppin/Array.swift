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
    
    // TODO maybe this is not very useful now that collect was added?
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

    // Filter + map
    // parameter f, mapping and filtering function if returns nil -> filter out
    func collect<T>(f: Element -> T?) -> [T] {
        var arr: [T] = []
        for e in self {
            if let e = f(e) {
                arr.append(e)
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
    
    mutating func appendAll(array: [Element]) {
        for element in array {
            self.append(element)
        }
    }
    
    // safe "slice"
    subscript(range: NSRange) -> Array<Element> {
        get {
            guard range.location < count else {return []}
            let end = min((range.location + range.length), count)
            return Array(self[range.location..<end])
        }
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