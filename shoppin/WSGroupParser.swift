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
    
    static func parseGroupItem(json: AnyObject) -> GroupItem {
        let remoteGroupItem = RemoteGroupItemsWithDependencies(representation: json)!
        return GroupItemMapper.groupItemsWithRemote(remoteGroupItem).groupItems.first!
    }
}
