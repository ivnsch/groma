//
//  RemoteSwitchAllListItemsResult.swift
//  shoppin
//
//  Created by ischuetz on 06/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteSwitchAllListItemsResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let items: [RemoteSwitchAllListItemResult]
    let sections: [RemoteSwitchAllSectionResult]
    let lastUpdate: NSDate
    
    init?(representation: AnyObject) {
        guard
            let itemsObj = representation.valueForKeyPath("items"),
            let items = RemoteSwitchAllListItemResult.collection(itemsObj),
            let sectionsObj = representation.valueForKeyPath("sections"),
            let sections = RemoteSwitchAllSectionResult.collection(sectionsObj),
            let lastUpdate = ((representation.valueForKeyPath("timestamp") as? Double).map{d in NSDate(timeIntervalSince1970: d)})
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.items = items
        self.sections = sections
        self.lastUpdate = lastUpdate
    }
    
    static func collection(representation: AnyObject) -> [RemoteSwitchAllListItemsResult]? {
        var items = [RemoteSwitchAllListItemsResult]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteSwitchAllListItemsResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType), items: \(items), sections: \(sections), lastUpdate: \(lastUpdate)}"
    }
}

struct RemoteSwitchAllListItemResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let dstQuantity: Int
    let dstOrder: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let dstQuantity = representation.valueForKeyPath("dstQuantity") as? Int,
            let dstOrder = representation.valueForKeyPath("dstOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.dstQuantity = dstQuantity
        self.dstOrder = dstOrder
    }
    
    static func collection(representation: AnyObject) -> [RemoteSwitchAllListItemResult]? {
        var items = [RemoteSwitchAllListItemResult]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteSwitchAllListItemResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), dstQuantity: \(dstQuantity), dstOrder: \(dstOrder)}"
    }
}

struct RemoteSwitchAllSectionResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let dstOrder: Int
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let dstOrder = representation.valueForKeyPath("dstOrder") as? Int
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.dstOrder = dstOrder
    }
    
    static func collection(representation: AnyObject) -> [RemoteSwitchAllSectionResult]? {
        var items = [RemoteSwitchAllSectionResult]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteSwitchAllSectionResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), dstOrder: \(dstOrder)}"
    }
}