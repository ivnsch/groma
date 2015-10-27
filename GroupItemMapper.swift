//
//  GroupItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class GroupItemMapper {
    
    class func dbWith(groupItem: GroupItem) -> DBGroupItem {
        let dbListItemGroup = DBGroupItem()
        dbListItemGroup.uuid = groupItem.uuid
        dbListItemGroup.quantity = groupItem.quantity
        dbListItemGroup.product = ProductMapper.dbWithProduct(groupItem.product)
        return dbListItemGroup
    }
    
    class func groupItemWith(dbGroupItem: DBGroupItem) -> GroupItem {
        let product = ProductMapper.productWithDB(dbGroupItem.product)
        return GroupItem(uuid: dbGroupItem.uuid, quantity: dbGroupItem.quantity, product: product)
    }
}
