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
        dbListItemGroup.setBgColor(listItemGroup.bgColor)
        dbListItemGroup.fav  = listItemGroup.fav
        return dbListItemGroup
    }
    
    class func listItemGroupWith(dbListItemGroup: DBListItemGroup) -> ListItemGroup {
        return ListItemGroup(
            uuid: dbListItemGroup.uuid,
            name: dbListItemGroup.name,
            bgColor: dbListItemGroup.bgColor(),
            order: dbListItemGroup.order,
            fav: dbListItemGroup.fav
        )
    }
    
    class func listItemGroupWithRemote(remoteGroup: RemoteGroup) -> ListItemGroup {
        return ListItemGroup(
            uuid: remoteGroup.uuid,
            name: remoteGroup.name,
            bgColor: remoteGroup.color,
            order: remoteGroup.order,
            fav: remoteGroup.fav
        )
    }
}