//
//  OrderedDictionary.swift
//  FlickrSearch
//
//  Created by Main Account on 9/14/14.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

struct OrderedDictionary<KeyType: Hashable, ValueType> {
    
    typealias ArrayType = [KeyType]
    typealias DictionaryType = [KeyType: ValueType]
    
    var array = ArrayType()
    var dictionary = DictionaryType()
    
    var count: Int {
        return self.array.count
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
}