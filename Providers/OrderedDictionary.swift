//
//  OrderedDictionary.swift
//  FlickrSearch
//
//  Created by Main Account on 9/14/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//
//  modified, added several methods
//

public struct OrderedDictionary<KeyType: Hashable, ValueType>: Sequence {
    
    public typealias ArrayType = [KeyType]
    public typealias DictionaryType = [KeyType: ValueType]
    
    public var array = ArrayType()
    public var dictionary = DictionaryType()
    
    public init() {}
    
    public var count: Int {
        return self.array.count
    }

    public var keys: [KeyType] {
        var arr: [KeyType] = []
        for (k, _) in self {
            arr.append(k)
        }
        return arr
    }
    
    public var values: [ValueType] {
        var arr: [ValueType] = []
        for (_, v) in self {
            arr.append(v)
        }
        return arr
    }
    
    public mutating func insert(_ value: ValueType, forKey key: KeyType, atIndex index: Int) -> ValueType? {
        var adjustedIndex = index
        
        let existingValue = self.dictionary[key]
        if existingValue != nil {
            
            let existingIndex = self.array.index(of: key)!
            
            if existingIndex < index {
                adjustedIndex -= 1
            }
            self.array.remove(at: existingIndex)
        }
        
        self.array.insert(key, at:adjustedIndex)
        self.dictionary[key] = value
        
        return existingValue
    }

    public mutating func removeIfExists(_ key: KeyType) -> (KeyType, ValueType)? {
        if let index = array.index(of: key) {
            return removeAtIndex(index)
        } else {
            return nil
        }
    }
    
    public mutating func removeAtIndex(_ index: Int) -> (KeyType, ValueType) {
        precondition(index < self.array.count, "Index out-of-bounds")
        
        let key = self.array.remove(at: index)
        let value = self.dictionary.removeValue(forKey: key)!
        return (key, value)
    }
    
    public subscript(key: KeyType) -> ValueType? {
        get {
            return self.dictionary[key]
        }
        set {
            if let _ = self.array.index(of: key) {
//            if let index = find(self.array, key) {
            } else {
                self.array.append(key)
            }
            
            self.dictionary[key] = newValue
        }
    }
    
    public subscript(index: Int) -> (KeyType, ValueType) {
        get {
            precondition(index < self.array.count,
                "Index out-of-bounds")
            
            let key = self.array[index]
            let value = self.dictionary[key]!
            return (key, value)
        }
    }

    // Returns tuple with optional value
    // TODO maybe make this the default and remove unsafe get (with force unwrap). Subsequently also rename mapOpt in map and remove the other one. Needs changes in a few places of the app.
    public subscript(safe index: Int) -> (KeyType, ValueType?) {
        get {
            precondition(index < self.array.count,
                "Index out-of-bounds")
            
            let key = self.array[index]
            let value = self.dictionary[key]
            return (key, value)
        }
    }

    public func mapOpt<T>(_ f: ((KeyType, ValueType?)) -> T) -> [T] {
        var arr: [T] = []
        for i in 0..<self.count {
            arr.append(f(self[safe: i]))
        }
        return arr
    }
    
    public func map<T>(_ f: ((KeyType, ValueType)) -> T) -> [T] {
        var arr: [T] = []
        for i in 0..<self.count {
            arr.append(f(self[i]))
        }
        return arr
    }

    public func mapValues<T>(_ f: (ValueType) -> T) -> [T] {
        var arr: [T] = []
        for (_, v) in self {
            arr.append(f(v))
        }
        return arr
    }
    
    public func mapDictionary<T>(_ f: ((KeyType, ValueType)) -> ((KeyType, T))) -> OrderedDictionary<KeyType, T> {
        var dict: OrderedDictionary<KeyType, T> = OrderedDictionary<KeyType, T>()
        for i in 0..<self.count {
            let mapped = f(self[i])
            dict[mapped.0] = mapped.1
        }
        return dict
    }

    public func makeIterator() -> AnyIterator<(KeyType, ValueType)> {
        var nextIndex = 0
        return AnyIterator {
            if (nextIndex < 0) {
                return nil
            }
            if nextIndex < self.array.count {
                let key = self.array[nextIndex]
                nextIndex += 1
                return (key, self.dictionary[key]!)
            } else {
                return nil
            }
        }
    }
    
    public subscript(range: NSRange) -> OrderedDictionary<KeyType, ValueType> {
        get {
            guard range.location < count else {return OrderedDictionary<KeyType, ValueType>()}
            
            let end = Swift.min((range.location + range.length), count)
            
            var dict = OrderedDictionary<KeyType, ValueType>()
            for i in range.location..<end {
                let keyVal = self[i]
                dict[keyVal.0] = keyVal.1
            }
            
            return dict
        }
    }
    
    public func toDictionary() -> Dictionary<KeyType, ValueType> {
        var dict = [KeyType: ValueType]()
        for entry in self {
            dict[entry.0] = entry.1
        }
        return dict
    }
}
