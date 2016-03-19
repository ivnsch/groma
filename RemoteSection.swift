//
//  RemoteSection.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSection: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let name: String
    var color: UIColor
    var listUuid: String
    let lastUpdate: NSDate
    
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    init?(representation: AnyObject) {
        guard
        let uuid = representation.valueForKeyPath("uuid") as? String,
        let name = representation.valueForKeyPath("name") as? String,
        let color = ((representation.valueForKeyPath("color") as? String).map{colorStr in
            UIColor(hexString: colorStr)
        }),
        let listUuid = representation.valueForKeyPath("listUuid") as? String,
        let lastUpdate = ((representation.valueForKeyPath("lastUpdate") as? Double).map{d in NSDate(timeIntervalSince1970: d)}),
        let todoOrder = representation.valueForKeyPath("todoOrder") as? Int,
        let doneOrder = representation.valueForKeyPath("doneOrder") as? Int,
        let stashOrder = representation.valueForKeyPath("stashOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.color = color
        
        self.listUuid = listUuid
        self.lastUpdate = lastUpdate
        
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
    }
    
    static func collection(representation: AnyObject) -> [RemoteSection]? {
        var sections = [RemoteSection]()
        for obj in representation as! [AnyObject] {
            if let section = RemoteSection(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), name: \(name), color: \(color), listUuid: \(listUuid), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastUpdate: \(lastUpdate)}"
    }
}

extension RemoteSection {
    var timestampUpdateDict: [String: AnyObject] {
        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
    }
}