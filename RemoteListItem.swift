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
    var status: Int
    let quantity: Int
    let productUuid: String
    var sectionUuid: String
    var listUuid: String
    var order: Int
    let note: String?
    let lastUpdate: NSDate
    
    init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.status = representation.valueForKeyPath("status") as! Int
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.sectionUuid = representation.valueForKeyPath("sectionUuid") as! String
        self.listUuid = representation.valueForKeyPath("listUuid") as! String
        self.order = representation.valueForKeyPath("order") as! Int
        self.note = representation.valueForKeyPath("note") as! String? // TODO is this correct way for optional here?
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
        return "{\(self.dynamicType) uuid: \(uuid), status: \(status), quantity: \(quantity), order: \(order), note: \(note), productUuid: \(productUuid), sectionUuid: \(sectionUuid), listUuid: \(listUuid), listUpdate: \(lastUpdate)}"
    }
}
