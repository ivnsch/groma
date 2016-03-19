//
//  RemoteOrderUpdate.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteOrderUpdate: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let order: Int
//    let lastUpdate: NSDate // no timestamp here due to server implementation details. So order updates don't have timestamp check on sync, which means they can always be overwrritten. This is not critical as order is not shared, and it doesn't happen that offen that user uses the app in another - unsynchronised - device - and does an order update in one of them which is overwritten. Plus order overwrite is not critical, in the rare case this happens user can reorder the items again.
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let order = representation.valueForKeyPath("order") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.order = order
    }
    
    static func collection(representation: AnyObject) -> [RemoteOrderUpdate]? {
        var sections = [RemoteOrderUpdate]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteOrderUpdate(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), order: \(order)}"
    }
}