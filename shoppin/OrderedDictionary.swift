//
//  OrderedDictionary.swift
//  FlickrSearch
//
//  Created by Main Account on 9/14/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//
//  modified, added several methods
//

struct OrderedDictionary<KeyType: Hashable, ValueType>: SequenceType {
    
    typealias ArrayType = [KeyType]
    typealias DictionaryType = [KeyType: ValueType]
    
    var array = ArrayType()
    var dictionary = DictionaryType()
    
    var count: Int {
        return self.array.count
    }
    
    var values: [ValueType] {
        var arr: [ValueType] = []
        for (_, v) in self {
            arr.append(v)
        }
        return arr
    }
    
    mutating func insert(value: ValueType, forKey key: KeyType, atIndex index: Int) -> ValueType? {
        var adjustedIndex = index
        
        let existingValue = self.dictionary[key]
        if existingValue != nil {
            
            let existingIndex = self.array.indexOf(key)!
            
            if existingIndex < index {
                adjustedIndex--
            }
            self.array.removeAtIndex(existingIndex)
        }
        
        self.array.insert(key, atIndex:adjustedIndex)
        self.dictionary[key] = value
        
        return existingValue
    }

    mutating func removeIfExists(key: KeyType) -> (KeyType, ValueType)? {
        if let index = array.indexOf(key) {
            return removeAtIndex(index)
        } else {
            return nil
        }
    }
    
    mutating func removeAtIndex(index: Int) -> (KeyType, ValueType) {
        precondition(index < self.array.count, "Index out-of-bounds")
        
        let key = self.array.removeAtIndex(index)
        let value = self.dictionary.removeValueForKey(key)!
        return (key, value)
    }
    
    subscript(key: KeyType) -> ValueType? {
        get {
            return self.dictionary[key]
        }
        set {
            if let _ = self.array.indexOf(key) {
//            if let index = find(self.array, key) {
            } else {
                self.array.append(key)
            }
            
            self.dictionary[key] = newValue
        }
    }
    
    subscript(index: Int) -> (KeyType, ValueType) {
        get {
            precondition(index < self.array.count,
                "Index out-of-bounds")
            
            let key = self.array[index]
            let value = self.dictionary[key]!
            return (key, value)
        }
    }
    
    func map<T>(f: ((KeyType, ValueType)) -> T) -> [T] {
        var arr: [T] = []
        for i in 0..<self.count {
            arr.append(f(self[i]))
        }
        return arr
    }

    func mapValues<T>(f: ValueType -> T) -> [T] {
        var arr: [T] = []
        for (_, v) in self {
            arr.append(f(v))
        }
        return arr
    }
    
    func mapDictionary<T>(f: ((KeyType, ValueType)) -> ((KeyType, T))) -> OrderedDictionary<KeyType, T> {
        var dict: OrderedDictionary<KeyType, T> = OrderedDictionary<KeyType, T>()
        for i in 0..<self.count {
            let mapped = f(self[i])
            dict[mapped.0] = mapped.1
        }
        return dict
    }

    func generate() -> AnyGenerator<(KeyType, ValueType)> {
        var nextIndex = 0
        return anyGenerator {
            if (nextIndex < 0) {
                return nil
            }
            if nextIndex < self.array.count {
                let key = self.array[nextIndex++]
                return (key, self.dictionary[key]!)
            } else {
                return nil
            }
        }
    }
    
    subscript(range: NSRange) -> OrderedDictionary<KeyType, ValueType> {
        get {
            guard range.location < count else {return OrderedDictionary<KeyType, ValueType>()}
            
            let end = min((range.location + range.length), count)
            
            var dict = OrderedDictionary<KeyType, ValueType>()
            for i in range.location..<end {
                let keyVal = self[i]
                dict[keyVal.0] = keyVal.1
            }
            
            return dict
        }
    }
}