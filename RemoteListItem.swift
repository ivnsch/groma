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
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let productUuid = representation.valueForKeyPath("storeProductUuid") as? String,
            let sectionUuid = representation.valueForKeyPath("sectionUuid") as? String,
            let listUuid = representation.valueForKeyPath("listUuid") as? String,
            let note = representation.valueForKeyPath("note") as? String?, // TODO is this correct way for optional here?
            let todoQuantity = representation.valueForKeyPath("todoQuantity") as? Int,
            let todoOrder = representation.valueForKeyPath("todoOrder") as? Int,
            let doneQuantity = representation.valueForKeyPath("doneQuantity") as? Int,
            let doneOrder = representation.valueForKeyPath("doneOrder") as? Int,
            let stashQuantity = representation.valueForKeyPath("stashQuantity") as? Int,
            let stashOrder = representation.valueForKeyPath("stashOrder") as? Int,
            let lastUpdate = representation.valueForKeyPath("lastUpdate") as? Double
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
    
    static func collection(representation: AnyObject) -> [RemoteListItem]? {
        var listItems = [RemoteListItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItem(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), note: \(note), todoQuantity: \(todoQuantity), todoOrder: \(todoOrder), doneQuantity: \(doneQuantity), doneOrder: \(doneOrder), stashQuantity: \(stashQuantity), stashOrder: \(stashOrder), productUuid: \(productUuid), sectionUuid: \(sectionUuid), listUuid: \(listUuid), listUpdate: \(lastUpdate)}"
    }
}

extension RemoteListItem {
    var timestampUpdateDict: [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
    
    static func createTimestampUpdateDict(uuid uuid: String, lastUpdate: Int64) -> [String: AnyObject] {
        return DBSyncable.timestampUpdateDict(uuid, lastServerUpdate: lastUpdate)
    }
}
