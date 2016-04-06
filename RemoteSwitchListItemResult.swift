//
//  RemoteSwitchListItemResult.swift
//  shoppin
//
//  Created by ischuetz on 05/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

struct RemoteSwitchListItemResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let switchedItem: RemoteSwitchListItemItemResult
    let itemOrderUpdates: [RemoteSwitchListItemOrderUpdateResult]
    let sectionOrderUpdates: [RemoteSwitchListItemSectionOrderUpdateResult]
    let lastUpdate: NSDate
    
    init?(representation: AnyObject) {
        guard
            let switchedItemObj = representation.valueForKeyPath("item"),
            let switchedItem = RemoteSwitchListItemItemResult(representation: switchedItemObj),
            let itemOrderUpdatesObj = representation.valueForKeyPath("orderItems") as? [AnyObject],
            let itemOrderUpdates = RemoteSwitchListItemOrderUpdateResult.collection(itemOrderUpdatesObj),
            let sectionOrderUpdatesObj = representation.valueForKeyPath("orderSections") as? [AnyObject],
            let sectionOrderUpdates = RemoteSwitchListItemSectionOrderUpdateResult.collection(sectionOrderUpdatesObj),
            let lastUpdate = ((representation.valueForKeyPath("timestamp") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.switchedItem = switchedItem
        self.itemOrderUpdates = itemOrderUpdates
        self.sectionOrderUpdates = sectionOrderUpdates
        self.lastUpdate = lastUpdate
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) switchedItem: \(switchedItem), itemOrderUpdates: \(itemOrderUpdates), sectionOrderUpdates: \(sectionOrderUpdates), lastUpdate: \(lastUpdate)}"
    }
}

struct RemoteSwitchListItemItemResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let uuid: String
    let todoQuantity: Int
    let doneQuantity: Int
    let stashQuantity: Int
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let todoQuantity = representation.valueForKeyPath("todoQuantity") as? Int,
            let doneQuantity = representation.valueForKeyPath("doneQuantity") as? Int,
            let stashQuantity = representation.valueForKeyPath("stashQuantity") as? Int,
            let todoOrder = representation.valueForKeyPath("todoOrder") as? Int,
            let doneOrder = representation.valueForKeyPath("doneOrder") as? Int,
            let stashOrder = representation.valueForKeyPath("stashOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.todoQuantity = todoQuantity
        self.doneQuantity = doneQuantity
        self.stashQuantity = stashQuantity
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
    }
}
//extension RemoteSwitchListItemItemResult {
//    var updateDict: [String: AnyObject] {
//        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
//    }
//}

struct RemoteSwitchListItemOrderUpdateResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let status: Int
    let order: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let status = representation.valueForKeyPath("status") as? Int,
            let order = representation.valueForKeyPath("order") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.status = status
        self.order = order
    }
    
    static func collection(representation: AnyObject) -> [RemoteSwitchListItemOrderUpdateResult]? {
        var items = [RemoteSwitchListItemOrderUpdateResult]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteSwitchListItemOrderUpdateResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), status: \(status), order: \(order)}"
    }
}


struct RemoteSwitchListItemSectionOrderUpdateResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let todoOrder = representation.valueForKeyPath("todoOrder") as? Int,
            let doneOrder = representation.valueForKeyPath("doneOrder") as? Int,
            let stashOrder = representation.valueForKeyPath("stashOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
    }
    
    static func collection(representation: AnyObject) -> [RemoteSwitchListItemSectionOrderUpdateResult]? {
        var items = [RemoteSwitchListItemSectionOrderUpdateResult]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteSwitchListItemSectionOrderUpdateResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
    }
    
}
