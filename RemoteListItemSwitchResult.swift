//
//  RemoteListItemSwitchResult.swift
//  shoppin
//
//  Created by ischuetz on 21/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSwitchListItemFullResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let switchResult: RemoteSwitchListItemResult
    let srcStatus: ListItemStatus
    let dstStatus: ListItemStatus
    let switchedQuantity: Int
    
    init?(representation: AnyObject) {
        guard
            let switchResultObj = representation.valueForKeyPath("result"),
            let switchResult = RemoteSwitchListItemResult(representation: switchResultObj),
            let srcStatusInt = representation.valueForKeyPath("srcStatus") as? Int,
            let srcStatus = ListItemStatus(rawValue: srcStatusInt),
            let dstStatusInt = representation.valueForKeyPath("dstStatus") as? Int,
            let dstStatus = ListItemStatus(rawValue: dstStatusInt),
            let switchedQuantity = representation.valueForKeyPath("switchedQuantity") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.switchResult = switchResult
        self.srcStatus = srcStatus
        self.dstStatus = dstStatus
        self.switchedQuantity = switchedQuantity
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) switchResult: \(switchResult), srcStatus: \(srcStatus), dstStatus: \(dstStatus), switchedQuantity: \(switchedQuantity)}"
    }
}

