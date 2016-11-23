//
//  RemoteSwitchAllListItemsLightResult.swift
//  shoppin
//
//  Created by ischuetz on 23/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSwitchAllListItemsLightResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let update: RemoteSwitchAllListItemsLightUpdate
    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let updateObj = representation.value(forKeyPath: "update"),
            let update = RemoteSwitchAllListItemsLightUpdate(representation: updateObj as AnyObject),
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.update = update
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) update: \(update), lastUpdate: \(lastUpdate)}"
    }
}



struct RemoteSwitchAllListItemsLightUpdate: ResponseObjectSerializable, CustomDebugStringConvertible {
    let srcStatus: ListItemStatus
    let dstStatus: ListItemStatus
    let listUuid: String
    
    init?(representation: AnyObject) {
        guard
            let srcStatusInt = representation.value(forKeyPath: "srcStatus") as? Int,
            let srcStatus = ListItemStatus(rawValue: srcStatusInt),
            let dstStatusInt = representation.value(forKeyPath: "dstStatus") as? Int,
            let dstStatus = ListItemStatus(rawValue: dstStatusInt),
            let listUuid = representation.value(forKeyPath: "listUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.srcStatus = srcStatus
        self.dstStatus = dstStatus
        self.listUuid = listUuid
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) srcStatus: \(srcStatus), dstStatus: \(dstStatus), listUuid: \(listUuid)}"
    }
}

