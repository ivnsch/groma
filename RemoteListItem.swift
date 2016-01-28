//
//  RemoteListItem.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteListItem: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
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

    let lastUpdate: NSDate
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.sectionUuid = representation.valueForKeyPath("sectionUuid") as! String
        self.listUuid = representation.valueForKeyPath("listUuid") as! String
        self.note = representation.valueForKeyPath("note") as! String? // TODO is this correct way for optional here?
        
        self.todoQuantity = representation.valueForKeyPath("todoQuantity") as! Int
        self.todoOrder = representation.valueForKeyPath("todoOrder") as! Int
        self.doneQuantity = representation.valueForKeyPath("doneQuantity") as! Int
        self.doneOrder = representation.valueForKeyPath("doneOrder") as! Int
        self.stashQuantity = representation.valueForKeyPath("stashQuantity") as! Int
        self.stashOrder = representation.valueForKeyPath("stashOrder") as! Int
        
        self.lastUpdate = NSDate(timeIntervalSince1970: representation.valueForKeyPath("lastUpdate") as! Double)
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteListItem] {
        var listItems = [RemoteListItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItem(response: response, representation: obj) {
                listItems.append(listItem)
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
        return ["uuid": uuid, "lastupdate": lastUpdate]
    }
}