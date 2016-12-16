//
//  ValidatorDictionary.swift
//  Validator
//
//  Created by Deniz Adalar on 04/05/16.
//  Copyright © 2016 jpotts18. All rights reserved.
//

import Foundation

public struct ValidatorDictionary<T> : Sequence {
    public init() {}

    fileprivate var innerDictionary: [ObjectIdentifier: T] = [:];
    
    public subscript(key: ValidatableField?) -> T? {
        get {
            if let key = key {
                return innerDictionary[ObjectIdentifier(key)];
            } else {
                return nil;
            }
        }
        set(newValue) {
            if let key = key {
                innerDictionary[ObjectIdentifier(key)] = newValue;
            }
        }
    }
    
    public mutating func removeAll() {
        innerDictionary.removeAll()        
    }
    
    public mutating func removeValueForKey(_ key: ValidatableField) {
        innerDictionary.removeValue(forKey: ObjectIdentifier(key))
    }
    
    public var isEmpty: Bool {
        return innerDictionary.isEmpty
    }
    
    public func makeIterator() -> DictionaryIterator<ObjectIdentifier ,T> {
        return innerDictionary.makeIterator()
    }

}

public func +<T>(left: ValidatorDictionary<T>, right: ValidatorDictionary<T>) -> ValidatorDictionary<T> {
    var newDict = ValidatorDictionary<T>()
    for (key, value) in left {
        newDict.innerDictionary[key] = value
    }
    for (key, value) in right {
        newDict.innerDictionary[key] = value
    }
    return newDict
}
