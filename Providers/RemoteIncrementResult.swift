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
    let delta: Float
    let updatedQuantity: Float
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let delta = representation.value(forKeyPath: "delta") as? Float,
            let updatedQuantity = representation.value(forKeyPath: "updatedQuantity") as? Float,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.delta = delta
        self.updatedQuantity = updatedQuantity
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), delta: \(delta), updatedQuantity: \(updatedQuantity), lastUpdate: \(lastUpdate)}"
    }
}
