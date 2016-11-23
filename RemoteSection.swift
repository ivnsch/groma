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
    let lastUpdate: Int64
    
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    init?(representation: AnyObject) {
        guard
        let uuid = representation.value(forKeyPath: "uuid") as? String,
        let name = representation.value(forKeyPath: "name") as? String,
        let color = ((representation.value(forKeyPath: "color") as? String).map{colorStr in
            UIColor(hexString: colorStr)
        }),
        let listUuid = representation.value(forKeyPath: "listUuid") as? String,
        let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double,
        let todoOrder = representation.value(forKeyPath: "todoOrder") as? Int,
        let doneOrder = representation.value(forKeyPath: "doneOrder") as? Int,
        let stashOrder = representation.value(forKeyPath: "stashOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.name = name
        self.color = color
        
        self.listUuid = listUuid
        self.lastUpdate = Int64(lastUpdate)
        
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteSection]? {
        var sections = [RemoteSection]()
        for obj in representation {
            if let section = RemoteSection(representation: obj) {
                sections.append(section)
            } else {
                return nil
            }
            
        }
        return sections
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), name: \(name), color: \(color), listUuid: \(listUuid), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder), lastUpdate: \(lastUpdate)}"
    }
}

extension RemoteSection {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
