//
//  RemoteGroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 11/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// FIXME quick & dirty implementation - "input" server model classes need new structure, maybe refactor models generally etc. a lot of repetition
// for most classes we could reuse the normal model classes but this for example has nested group which is not in GroupItem
final class RemoteGroupItemInput: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let quantity: Int
    let product: Product
    let group: ListItemGroup
    
    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.uuid = representation.valueForKeyPath("uuid") as! String
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        
        let product: AnyObject = representation.valueForKeyPath("product")!
        self.product = ListItemParser.parseProduct(product)
        
        let group: AnyObject = representation.valueForKeyPath("group")!
        self.group = WSGroupParser.parseGroup(group)
    }
    
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteGroupItemInput] {
        var items = [RemoteGroupItemInput]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroupItemInput(response: response, representation: obj) {
                items.append(item)
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), quantity: \(quantity)}, product: \(product), group: \(group)}"
    }
    
    func toGroupItem() -> GroupItem {
        // TODO review lastUpdate: NSDate(), lastServerUpdate: nil, removed: false - didn't know what to pass here so used defaults
        return GroupItem(uuid: uuid, quantity: quantity, product: product, lastUpdate: NSDate(), lastServerUpdate: nil, removed: false)
    }
}