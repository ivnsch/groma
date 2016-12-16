//
//  OrderedDictionary_Quantities.swift
//  shoppin
//
//  Created by ischuetz on 23/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension OrderedDictionary where ValueType: Addable {
    
    // Note: not thread safe!
    public mutating func addOrIncrementItem(_ key: KeyType, quantity: ValueType) {
        if self[key] != nil {
           self[key] = ValueType.identity
        } else {
            self[key] = self[key]! + quantity
        }
    }
}
