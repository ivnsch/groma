//
//  ListItemGroupMapper.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemGroupMapper {
    
    class func dbWith(listItemGroup: ListItemGroup) -> DBListItemGroup {
        let dbListItemGroup = DBListItemGroup()
        dbListItemGroup.uuid = listItemGroup.uuid
        dbListItemGroup.name = listItemGroup.name
        dbListItemGroup.order = listItemGroup.order
        let dbListItems = listItemGroup.items.map{GroupItemMapper.dbWith($0)}
        for dbObj in dbListItems {
            dbListItemGroup.items.append(dbObj)
        }
        dbListItemGroup.setBgColor(listItemGroup.bgColor)
        return dbListItemGroup
    }
    
    class func listItemGroupWith(dbListItemGroup: DBListItemGroup) -> ListItemGroup {
        return ListItemGroup(
            uuid: dbListItemGroup.uuid,
            name: dbListItemGroup.name,
            items: dbListItemGroup.items.map{GroupItemMapper.groupItemWith($0)},
            bgColor: dbListItemGroup.bgColor(),
            order: dbListItemGroup.order
        )
    }
}