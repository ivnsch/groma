//
//  RemoteIncrementResult.swift
//  shoppin
//
//  Created by ischuetz on 15/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

struct RemoteListItemIncrementResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let uuid: String
    let delta: Int
    let status: ListItemStatus
    let updatedQuantity: Int
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let delta = representation.value(forKeyPath: "delta") as? Int,
            let statusInt = representation.value(forKeyPath: "status") as? Int,
            let status = ListItemStatus(rawValue: statusInt),
            let updatedQuantity = representation.value(forKeyPath: "updatedQuantity") as? Int,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                print("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.delta = delta
        self.status = status
        self.updatedQuantity = updatedQuantity
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), delta: \(delta), status: \(status), updatedQuantity: \(updatedQuantity), lastUpdate: \(lastUpdate)}"
    }
}
