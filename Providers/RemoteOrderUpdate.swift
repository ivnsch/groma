//
//  RemoteOrderUpdate.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteOrderUpdate: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let order: Int
//    let lastUpdate: NSDate // no timestamp here due to server implementation details. So order updates don't have timestamp check on sync, which means they can always be overwrritten. This is not critical as order is not shared, and it doesn't happen that offen that user uses the app in another - unsynchronised - device - and does an order update in one of them which is overwritten. Plus order overwrite is not critical, in the rare case this happens user can reorder the items again.
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let order = representation.value(forKeyPath: "order") as? Int
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.order = order
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteOrderUpdate]? {
        var sections = [RemoteOrderUpdate]()
        for obj in representation {
            if let section = RemoteOrderUpdate(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), order: \(order)}"
    }
}
