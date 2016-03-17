//
//  RemoteContainedItemIdentifier.swift
//  shoppin
//
//  Created by ischuetz on 16/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteContainedItemIdentifier: CustomDebugStringConvertible {
    let itemUuid: String
    let containerUuid: String
    
    init?(representation: AnyObject) {
        guard
            let itemUuid = representation.valueForKeyPath("uuid") as? String,
            let containerUuid = representation.valueForKeyPath("containerUuid") as? String
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.itemUuid = itemUuid
        self.containerUuid = containerUuid
    }
    
    
    var debugDescription: String {
        return "{\(self.dynamicType) itemUuid: \(itemUuid), containerUuid: \(containerUuid)}"
    }
}
