//
//  RemoteSwitchListItemResult.swift
//  shoppin
//
//  Created by ischuetz on 05/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

public struct RemoteSwitchListItemResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    public let switchedItem: RemoteSwitchListItemItemResult
    public let itemOrderUpdates: [RemoteSwitchListItemOrderUpdateResult]
    public let sectionOrderUpdates: [RemoteSwitchListItemSectionOrderUpdateResult]
    public let lastUpdate: Date
    
    public init?(representation: AnyObject) {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) switchedItem: \(switchedItem), itemOrderUpdates: \(itemOrderUpdates), sectionOrderUpdates: \(sectionOrderUpdates), lastUpdate: \(lastUpdate)}"
    }
}

public struct RemoteSwitchListItemItemResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let todoQuantity: Int
    public let doneQuantity: Int
    public let stashQuantity: Int
    public let todoOrder: Int
    public let doneOrder: Int
    public let stashOrder: Int
    
    public init?(representation: AnyObject) {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), todoQuantity: \(todoQuantity), doneQuantity: \(doneQuantity), stashQuantity: \(stashQuantity), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
    }
}
//extension RemoteSwitchListItemItemResult {
//    var updateDict: [String: AnyObject] {
//        return ["uuid": uuid, "lastupdate": lastUpdate, "dirty": false]
//    }
//}

public struct RemoteSwitchListItemOrderUpdateResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let status: Int
    public let order: Int
    
    public init?(representation: AnyObject) {
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
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSwitchListItemOrderUpdateResult]? {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), status: \(status), order: \(order)}"
    }
}


public struct RemoteSwitchListItemSectionOrderUpdateResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let todoOrder: Int
    public let doneOrder: Int
    public let stashOrder: Int
    
    public init?(representation: AnyObject) {
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
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSwitchListItemSectionOrderUpdateResult]? {
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
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), todoOrder: \(todoOrder), doneOrder: \(doneOrder), stashOrder: \(stashOrder)}"
    }
    
}
