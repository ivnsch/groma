//
//  RemoteGroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 11/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

// FIXME quick & dirty implementation - "input" server model classes need new structure, maybe refactor models generally etc. a lot of repetition
// for most classes we could reuse the normal model classes but this for example has nested group which is not in GroupItem
struct RemoteGroupItemInput: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let uuid: String
    let quantity: Int
    let product: Product
    let group: ListItemGroup
    
    init?(representation: AnyObject) {
        guard
            let uuid = representation.valueForKeyPath("uuid") as? String,
            let quantity = representation.valueForKeyPath("quantity") as? Int,
            let productObj = representation.valueForKeyPath("product"),
            let groupObj = representation.valueForKeyPath("group")
            else {
                QL4("Invalid json: \(representation)")
                return nil}

        self.uuid = uuid
        self.quantity = quantity
        let product = ListItemParser.parseProduct(productObj)
        self.product = product
        let group = WSGroupParser.parseGroup(groupObj)
        self.group = group
    }
    
    
    static func collection(representation: AnyObject) -> [RemoteGroupItemInput]? {
        var items = [RemoteGroupItemInput]()
        for obj in representation as! [AnyObject] {
            if let item = RemoteGroupItemInput(representation: obj) {
                items.append(item)
            } else {
                return nil
            }
            
        }
        return items
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) uuid: \(uuid), quantity: \(quantity)}, product: \(product), group: \(group)}"
    }
    
    func toGroupItem() -> GroupItem {
        // TODO review lastUpdate: NSDate(), lastServerUpdate: nil, removed: false - didn't know what to pass here so used defaults
        return GroupItem(uuid: uuid, quantity: quantity, product: product, group: group, lastUpdate: NSDate(), lastServerUpdate: nil, removed: false)
    }
}