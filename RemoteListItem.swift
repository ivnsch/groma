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
    var done: Bool
    let quantity: Int
    let productUuid: String
    var sectionUuid: String
    var listUuid: String
    var order: Int
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.done = representation.valueForKeyPath("done") as! Bool
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.productUuid = representation.valueForKeyPath("productUuid") as! String
        self.sectionUuid = representation.valueForKeyPath("sectionUuid") as! String
        self.listUuid = representation.valueForKeyPath("listUuid") as! String
        self.order = representation.valueForKeyPath("order") as! Int
    }
    
    @objc static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteListItem] {
        var listItems = [RemoteListItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItem(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(self.uuid), done: \(self.done), quantity: \(self.quantity), order: \(self.order), productUuid: \(self.productUuid), sectionUuid: \(self.sectionUuid), listUuid: \(self.listUuid)}"
    }
}
