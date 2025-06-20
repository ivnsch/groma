//
//  RemoteListItemIncrement.swift
//  shoppin
//
//  Created by ischuetz on 22/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteListItemIncrement: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let status: ListItemStatus
    public let delta: Float
    public let updatedQuantity: Float
    public let lastUpdate: Int64
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let statusInt = representation.value(forKeyPath: "status") as? Int,
            let status = ListItemStatus(rawValue: statusInt),
            let delta = representation.value(forKeyPath: "delta") as? Float,
            let updatedQuantity = representation.value(forKeyPath: "updatedQuantity") as? Float,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.status = status
        self.delta = delta
        self.updatedQuantity = updatedQuantity
        self.lastUpdate = Int64(lastUpdate)
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), status: \(status), delta: \(delta), updatedQuantity: \(updatedQuantity), lastUpdate: \(lastUpdate)}"
    }
}
