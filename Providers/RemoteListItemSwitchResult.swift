//
//  RemoteListItemSwitchResult.swift
//  shoppin
//
//  Created by ischuetz on 21/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteSwitchListItemFullResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let switchResult: RemoteSwitchListItemResult
    public let srcStatus: ListItemStatus
    public let dstStatus: ListItemStatus
    public let switchedQuantity: Float
    
    public init?(representation: AnyObject) {
        guard
            let switchResultObj = representation.value(forKeyPath: "result"),
            let switchResult = RemoteSwitchListItemResult(representation: switchResultObj as AnyObject),
            let srcStatusInt = representation.value(forKeyPath: "srcStatus") as? Int,
            let srcStatus = ListItemStatus(rawValue: srcStatusInt),
            let dstStatusInt = representation.value(forKeyPath: "dstStatus") as? Int,
            let dstStatus = ListItemStatus(rawValue: dstStatusInt),
            let switchedQuantity = representation.value(forKeyPath: "switchedQuantity") as? Float
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.switchResult = switchResult
        self.srcStatus = srcStatus
        self.dstStatus = dstStatus
        self.switchedQuantity = switchedQuantity
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) switchResult: \(switchResult), srcStatus: \(srcStatus), dstStatus: \(dstStatus), switchedQuantity: \(switchedQuantity)}"
    }
}

