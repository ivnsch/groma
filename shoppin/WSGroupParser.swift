//
//  WSGroupParser.swift
//  shoppin
//
//  Created by ischuetz on 09/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct WSGroupParser {
    
    static func parseGroup(json: AnyObject) -> ListItemGroup {
        let remoteGroup = RemoteGroup(representation: json)!
        return ListItemGroupMapper.listItemGroupWithRemote(remoteGroup)
    }
    
    static func parseGroupItem(json: AnyObject) -> GroupItemWithGroup {
        let uuid = json.valueForKeyPath("uuid") as! String
        let quantity = json.valueForKeyPath("quantity") as! Int
        
        let productObj = json.valueForKeyPath("product")!
        let product = ListItemParser.parseProduct(productObj)
        
        let groupObj = json.valueForKeyPath("group")!
        let group = parseGroup(groupObj)
        
        return GroupItemWithGroup(groupItem: GroupItem(uuid: uuid, quantity: quantity, product: product, group: group), group: group)
    }
}
