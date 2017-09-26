//
//  RemoteContainedItemIdentifier.swift
//  shoppin
//
//  Created by ischuetz on 16/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteContainedItemIdentifier: CustomDebugStringConvertible {
    let itemUuid: String
    let containerUuid: String
    
    init?(representation: AnyObject) {
        guard
            let itemUuid = representation.value(forKeyPath: "uuid") as? String,
            let containerUuid = representation.value(forKeyPath: "containerUuid") as? String
            else {
                logger.e("Invalid json: \(representation)")
                return nil}

        self.itemUuid = itemUuid
        self.containerUuid = containerUuid
    }
    
    
    var debugDescription: String {
        return "{\(type(of: self)) itemUuid: \(itemUuid), containerUuid: \(containerUuid)}"
    }
}
