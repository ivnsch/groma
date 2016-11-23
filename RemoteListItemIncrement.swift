//
//  RemoteListItemIncrement.swift
//  shoppin
//
//  Created by ischuetz on 22/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItemIncrement: ResponseObjectSerializable, CustomDebugStringConvertible {
    let uuid: String
    let status: ListItemStatus
    let delta: Int
    let updatedQuantity: Int
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let statusInt = representation.value(forKeyPath: "status") as? Int,
            let status = ListItemStatus(rawValue: statusInt),
            let delta = representation.value(forKeyPath: "delta") as? Int,
            let updatedQuantity = representation.value(forKeyPath: "updatedQuantity") as? Int,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.status = status
        self.delta = delta
        self.updatedQuantity = updatedQuantity
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), status: \(status), delta: \(delta), updatedQuantity: \(updatedQuantity), lastUpdate: \(lastUpdate)}"
    }
}
