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
    let lastUpdate: Date
    
    init?(representation: AnyObject) {
        guard
            let switchedItemObj = representation.value(forKeyPath: "item"),
            let switchedItem = RemoteSwitchListItemItemResult(representation: switchedItemObj as AnyObject),
            let itemOrderUpdatesObj = representation.value(forKeyPath: "orderItems") as? [AnyObject],
            let itemOrderUpdates = RemoteSwitchListItemOrderUpdateResult.collection(itemOrderUpdatesObj),
            let sectionOrderUpdatesObj = representation.value(forKeyPath: "orderSections") as? [AnyObject],
            let sectionOrderUpdates = RemoteSwitchListItemSectionOrderUpdateResult.collection(sectionOrderUpdatesObj),
            let lastUpdate = ((representation.value(forKeyPath: "timestamp") as? Double).map{d in Date(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.switchedItem = switchedItem
        self.itemOrderUpdates = itemOrderUpdates
        self.sectionOrderUpdates = sectionOrderUpdates
        self.lastUpdate = lastUpdate
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) switchedItem: \(switchedItem), itemOrderUpdates: \(itemOrderUpdates), sectionOrderUpdates: \(sectionOrderUpdates), lastUpdate: \(lastUpdate)}"
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
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let todoQuantity = representation.value(forKeyPath: "todoQuantity") as? Int,
            let doneQuantity = representation.value(forKeyPath: "doneQuantity") as? Int,
            let stashQuantity = representation.value(forKeyPath: "stashQuantity") as? Int,
            let todoOrder = representation.value(forKeyPath: "todoOrder") as? Int,
            let doneOrder = representation.value(forKeyPath: "doneOrder") as? Int,
            let stashOrder = representation.value(forKeyPath: "stashOrder") as? Int
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
        return "{\(type(of: self)) uuid: \(uuid), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
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
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let status = representation.value(forKeyPath: "status") as? Int,
            let order = representation.value(forKeyPath: "order") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.status = status
        self.order = order
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteSwitchListItemOrderUpdateResult]? {
        var items = [RemoteSwitchListItemOrderUpdateResult]()
        for obj in representation {
            if let item = RemoteSwitchListItemOrderUpdateResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), status: \(status), order: \(order)}"
    }
}


struct RemoteSwitchListItemSectionOrderUpdateResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let todoOrder: Int
    let doneOrder: Int
    let stashOrder: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let todoOrder = representation.value(forKeyPath: "todoOrder") as? Int,
            let doneOrder = representation.value(forKeyPath: "doneOrder") as? Int,
            let stashOrder = representation.value(forKeyPath: "stashOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.todoOrder = todoOrder
        self.doneOrder = doneOrder
        self.stashOrder = stashOrder
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteSwitchListItemSectionOrderUpdateResult]? {
        var items = [RemoteSwitchListItemSectionOrderUpdateResult]()
        for obj in representation {
            if let item = RemoteSwitchListItemSectionOrderUpdateResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
    }
    
}
