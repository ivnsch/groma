//
//  RemoteListItem.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let uuid: String
    let productUuid: String
    var sectionUuid: String
    var listUuid: String
    let note: String?
    
    let todoQuantity: Int
    let todoOrder: Int
    let doneQuantity: Int
    let doneOrder: Int
    let stashQuantity: Int
    let stashOrder: Int

    let lastUpdate: Int64
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let productUuid = representation.value(forKeyPath: "storeProductUuid") as? String,
            let sectionUuid = representation.value(forKeyPath: "sectionUuid") as? String,
            let listUuid = representation.value(forKeyPath: "listUuid") as? String,
            let note = representation.value(forKeyPath: "note") as? String?, // TODO is this correct way for optional here?
            let todoQuantity = representation.value(forKeyPath: "todoQuantity") as? Int,
            let todoOrder = representation.value(forKeyPath: "todoOrder") as? Int,
            let doneQuantity = representation.value(forKeyPath: "doneQuantity") as? Int,
            let doneOrder = representation.value(forKeyPath: "doneOrder") as? Int,
            let stashQuantity = representation.value(forKeyPath: "stashQuantity") as? Int,
            let stashOrder = representation.value(forKeyPath: "stashOrder") as? Int,
            let lastUpdate = representation.value(forKeyPath: "lastUpdate") as? Double
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.productUuid = productUuid
        self.sectionUuid = sectionUuid
        self.listUuid = listUuid
        self.note = note
        
        self.todoQuantity = todoQuantity
        self.todoOrder = todoOrder
        self.doneQuantity = doneQuantity
        self.doneOrder = doneOrder
        self.stashQuantity = stashQuantity
        self.stashOrder = stashOrder
        
        self.lastUpdate = Int64(lastUpdate)
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteListItem]? {
        var listItems = [RemoteListItem]()
        for obj in representation {
            if let listItem = RemoteListItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), note: \(note), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder), productUuid: \(productUuid), sectionUuid: \(sectionUuid), listUuid: \(listUuid), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteListItem {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    static func createTimestampUpdateDict(uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
