//
//  ItemIncrement.swift
//  shoppin
//
//  Created by ischuetz on 10/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ItemIncrement: CustomDebugStringConvertible {
    
    let delta: Int
    let itemUuid: String
    
    init(delta: Int, itemUuid: String) {
        self.delta = delta
        self.itemUuid = itemUuid
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) delta: \(delta), itemUuid: \(itemUuid)}"
    }
}