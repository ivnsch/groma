//
//  RemoteIncrementResult.swift
//  shoppin
//
//  Created by ischuetz on 15/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

struct RemoteIncrementResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let uuid: String
    let delta: Int
    let updatedQuantity: Int
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let delta = representation.valueForKeyPath("delta") as? Int,
            let updatedQuantity = representation.valueForKeyPath("updatedQuantity") as? Int,
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.delta = delta
        self.updatedQuantity = updatedQuantity
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), delta: \(delta), updatedQuantity: \(updatedQuantity), lastUpdate: \(lastUpdate)}"
    }
}