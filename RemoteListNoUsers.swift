//
//  RemoteListNoUsers.swift
//  shoppin
//
//  Created by ischuetz on 24/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListNoUsers: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    let order: Int
    var color: UIColor
    let lastUpdate: NSDate
    let inventoryUuid: String
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let name = representation.valueForKeyPath("name") as? String,
            let order = representation.valueForKeyPath("order") as? Int,
            let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)}),
            let inventoryUuid = representation.valueForKeyPath("inventoryUuid") as? String,
            let color = ((representation.valueForKeyPath("color") as? String).map{colorStr in
                UIColor(hexString: colorStr)
            })
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.order = order
        self.lastUpdate = lastUpdate
        self.inventoryUuid = inventoryUuid
        self.color = color
    }
    
    static func collection(representation: AnyObject) -> [RemoteListNoUsers]? {
        var lists = [RemoteListNoUsers]()
        for obj in representation as! [AnyObject] {
            if let list = RemoteListNoUsers(representation: obj) {
                lists.append(list)
            } else {
                return nil
            }
            
        }
        return lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), order: \(order), inventoryUuid: \(inventoryUuid), lastUpdate: \(lastUpdate), color: \(color)}"
    }
}
