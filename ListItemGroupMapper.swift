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
        dbListItemGroup.setBgColor(listItemGroup.bgColor)
        let dbListItems = listItemGroup.items.map{GroupItemMapper.dbWith($0)}
        for dbObj in dbListItems {
            dbListItemGroup.items.append(dbObj)
        }
        dbListItemGroup.setBgColor(listItemGroup.bgColor)
        dbListItemGroup.fav  = listItemGroup.fav
        return dbListItemGroup
    }
    
    class func listItemGroupWith(dbListItemGroup: DBListItemGroup) -> ListItemGroup {
        return ListItemGroup(
            uuid: dbListItemGroup.uuid,
            name: dbListItemGroup.name,
            items: dbListItemGroup.items.map{GroupItemMapper.groupItemWith($0)},
            bgColor: dbListItemGroup.bgColor(),
            order: dbListItemGroup.order,
            fav: dbListItemGroup.fav
        )
    }
    
    class func listItemGroupWithRemote(remoteGroup: RemoteGroup, items: [GroupItem]) -> ListItemGroup {
        return ListItemGroup(
            uuid: remoteGroup.uuid,
            name: remoteGroup.name,
            items: items,
            bgColor: remoteGroup.color,
            order: remoteGroup.order,
            fav: remoteGroup.fav
        )
    }
}