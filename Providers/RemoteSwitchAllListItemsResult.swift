//
//  RemoteSwitchAllListItemsResult.swift
//  shoppin
//
//  Created by ischuetz on 06/04/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


public struct RemoteSwitchAllListItemsResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let items: [RemoteSwitchAllListItemResult]
    public let sections: [RemoteSwitchAllSectionResult]
    public let lastUpdate: Int64
    
    public init?(representation: AnyObject) {
        guard
            let itemsObj = representation.value(forKeyPath: "items") as? [AnyObject],
            let items = RemoteSwitchAllListItemResult.collection(itemsObj),
            let sectionsObj = representation.value(forKeyPath: "sections") as? [AnyObject],
            let sections = RemoteSwitchAllSectionResult.collection(sectionsObj),
            let lastUpdate = representation.value(forKeyPath: "timestamp") as? Double
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.items = items
        self.sections = sections
        self.lastUpdate = Int64(lastUpdate)
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSwitchAllListItemsResult]? {
        var items = [RemoteSwitchAllListItemsResult]()
        for obj in representation {
            if let item = RemoteSwitchAllListItemsResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)), items: \(items), sections: \(sections), lastUpdate: \(lastUpdate)}"
    }
}

public struct RemoteSwitchAllListItemResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let dstQuantity: Float
    public let dstOrder: Int
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let dstQuantity = representation.value(forKeyPath: "dstQuantity") as? Float,
            let dstOrder = representation.value(forKeyPath: "dstOrder") as? Int
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.dstQuantity = dstQuantity
        self.dstOrder = dstOrder
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSwitchAllListItemResult]? {
        var items = [RemoteSwitchAllListItemResult]()
        for obj in representation {
            if let item = RemoteSwitchAllListItemResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), dstQuantity: \(dstQuantity), dstOrder: \(dstOrder)}"
    }
}

public struct RemoteSwitchAllSectionResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    public let uuid: String
    public let dstOrder: Int
    
    public init?(representation: AnyObject) {
        guard
            let uuid = representation.value(forKeyPath: "uuid") as? String,
            let dstOrder = representation.value(forKeyPath: "dstOrder") as? Int
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.uuid = uuid
        self.dstOrder = dstOrder
    }
    
    public static func collection(_ representation: [AnyObject]) -> [RemoteSwitchAllSectionResult]? {
        var items = [RemoteSwitchAllSectionResult]()
        for obj in representation {
            if let item = RemoteSwitchAllSectionResult(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
        }
        return items
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) uuid: \(uuid), dstOrder: \(dstOrder)}"
    }
}
