//
//  RemoteSwitchAllListItemsLightResult.swift
//  shoppin
//
//  Created by ischuetz on 23/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

public struct RemoteSwitchAllListItemsLightResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let update: RemoteSwitchAllListItemsLightUpdate
    public let lastUpdate: Int64
    
    public init?(representation: AnyObject) {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) update: \(update), lastUpdate: \(lastUpdate)}"
    }
}



public struct RemoteSwitchAllListItemsLightUpdate: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let srcStatus: ListItemStatus
    public let dstStatus: ListItemStatus
    public let listUuid: String
    
    public init?(representation: AnyObject) {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) srcStatus: \(srcStatus), dstStatus: \(dstStatus), listUuid: \(listUuid)}"
    }
}

