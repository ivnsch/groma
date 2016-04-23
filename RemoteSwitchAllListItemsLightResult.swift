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
            let updateObj = representation.valueForKeyPath("update"),
            let update = RemoteSwitchAllListItemsLightUpdate(representation: updateObj),
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.update = update
        self.lastUpdate = Int64(lastUpdate)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) update: \(update), lastUpdate: \(lastUpdate)}"
    }
}



struct RemoteSwitchAllListItemsLightUpdate: ResponseObjectSerializable, CustomDebugStringConvertible {
    let srcStatus: ListItemStatus
    let dstStatus: ListItemStatus
    let listUuid: String
    
    init?(representation: AnyObject) {
        guard
            let srcStatusInt = representation.valueForKeyPath("srcStatus") as? Int,
            let srcStatus = ListItemStatus(rawValue: srcStatusInt),
            let dstStatusInt = representation.valueForKeyPath("dstStatus") as? Int,
            let dstStatus = ListItemStatus(rawValue: dstStatusInt),
            let listUuid = representation.valueForKeyPath("listUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.srcStatus = srcStatus
        self.dstStatus = dstStatus
        self.listUuid = listUuid
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) srcStatus: \(srcStatus), dstStatus: \(dstStatus), listUuid: \(listUuid)}"
    }
}

