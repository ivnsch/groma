//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

public extension Array {
    public func forEach<U>(_ function: (_ element: Element) -> U) {
        for e in self {
            _ = function(e)
        }
    }
    
    public func findFirst(_ function: (_ element: Element) -> Bool) -> Element? {
        for e in self {
            if function(e) {
                return e
            }
        }
        return nil
    }
    
    public func contains(_ function: (_ element: Element) -> Bool) -> Bool {
        return findFirst(function) != nil
    }
    
    // src: http://stackoverflow.com/a/30593673/930450
    public subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
    
    // TODO maybe this is not very useful now that collect was added?
    // Filters a list and maps in the same iteration.
    // Reduce could also be used for this, but this has better performance.
    public func filterMap<T>(_ filterFunc: (Element) -> Bool, mapFunc: (Element) -> T) -> [T] {
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
    public func collect<T>(_ f: (Element) -> T?) -> [T] {
        var arr: [T] = []
        for e in self {
            if let e = f(e) {
                arr.append(e)
            }
        }
        return arr
    }

    public func split(_ belongs: (Element) -> Bool) -> (belongs: [Element], notBelongs: [Element]) {
        var belongsArr: [Element] = []
        var notBelongsArr: [Element] = []
        for element in self {
            if belongs(element) {
                belongsArr.append(element)
            } else {
                notBelongsArr.append(element)
            }
        }
        return (belongsArr, notBelongsArr)
    }
    
    public func splitMap<U>(_ belongs: (Element) -> Bool, mapper: (Element) -> U) -> (belongs: [U], notBelongs: [U]) {
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
    
    
    // More performant variant of array.enumerate().map{index, element}. We call it like this: array.mapEnumerate{index, Element in return Foo}
    public func mapEnumerate<T>(_ f: (Int, Element) -> T) -> [T] {
        var arr: [T] = []
        for i in 0..<self.count {
            arr.append(f(i, self[i]))
        }
        return arr
    }

    public func forEachEnumerate(_ f: (Int, Element) -> Void) {
        for i in 0..<self.count {
            f(i, self[i])
        }
    }
    
    public func toDictionary<K: Hashable, V>(_ mapFunc: (Element) -> (K, V?)) -> [K: V] {
        var dict = [K: V]()
        for e in self {
            let (k, v) = mapFunc(e)
            dict[k] = v
        }
        return dict
    }
    
    public mutating func appendAll(_ array: [Element]) {
        for element in array {
            self.append(element)
        }
    }
    
    // safe "slice"
    public subscript(range: NSRange) -> Array<Element> {
        get {
            guard range.location < count else {return []}
            let end = Swift.min((range.location + range.length), count)
            return Array(self[range.location..<end])
        }
    }

    public func sum(_ f: (Element) -> Float) -> Float {
        return reduce(0) {sum, element in
            sum + f(element)
        }
    }
    
    public func sum(_ f: (Element) -> Int) -> Int {
        return reduce(0) {sum, element in
            sum + f(element)
        }
    }
    
    public func removeAllWithCondition(_ f: (Element) -> Bool) -> Array<Element> {
        var array = Array<Element>()
        for e in self {
            if !f(e) {
               array.append(e)
            }
        }
        return array
    }
    
    public mutating func insertAll(index: Int, arr: [Element]) {
        for (i, e) in arr.enumerated() {
            insert(e, at: index + i)
        }
    }
}

public extension Array where Element: Hashable {

    // src: http://stackoverflow.com/a/27624444/930450 (modified to be an extension)
    public func distinct() -> [Element] {
        var seen: [Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

public extension Array where Element: Identifiable {
    
    /**
    Replaces first element with same identity with element
    */
    public mutating func update(_ element: Element) -> Bool {
        for i in 0..<self.count {
            if self[i].same(element) {
                self[i] = element
                return true
            }
        }
        return false
    }
    
    public func indexOfUsingIdentifiable(_ element: Element) -> Int? {
        for i in 0..<self.count {
            if self[i].same(element) {
                return i
            }
        }
        return nil
    }
    
    public mutating func removeUsingIdentifiable(_ element: Element) -> Int? {
        if let index = self.indexOfUsingIdentifiable(element) {
            self.remove(at: index)
            return index
        }
        return nil
    }
}

public extension Array where Element: Equatable {
    
    // safe element removal, and returns index of removed element optional
    public mutating func remove(_ element: Element) -> Int? {
        if let index = self.index(of: element) {
            self.remove(at: index)
            return index
        }
        return nil
    }
    
    // Less performant than distinct() in Array[Hashable] so wherever possible try to make the elements hashable and use distinct()
    public func distinctUsingEquatable() -> Array<Element> {
        var array = [Element]()
        for element in self {
            if !array.contains(element) {
                array.append(element)
            }
        }
        return array
    }
}
