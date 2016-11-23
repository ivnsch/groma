//
//  RemoteIncrement.swift
//  shoppin
//
//  Created by ischuetz on 17/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteIncrement: ResponseObjectSerializable, CustomDebugStringConvertible {
    let uuid: String
    let delta: Int
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let delta = representation.value(forKeyPath: "delta") as? Int,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.delta = delta
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), delta: \(delta), lastUpdate: \(lastUpdate)}"
    }
}
