//
//  ItemIncrement.swift
//  shoppin
//
//  Created by ischuetz on 10/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class ItemIncrement: CustomDebugStringConvertible {
    
    public let delta: Float
    public let itemUuid: String
    
    public init(delta: Float, itemUuid: String) {
        self.delta = delta
        self.itemUuid = itemUuid
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) delta: \(delta), itemUuid: \(itemUuid)}"
    }
}
