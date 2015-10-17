//
//  RealmListItemGroupProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmListItemGroupProvider: RealmProvider {

    func add(groups: [ListItemGroup], handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }

    func add(groupItem: GroupItem, handler: Bool -> Void) {
        let dbObj = GroupItemMapper.dbWith(groupItem)
        self.saveObj(dbObj, update: true, handler: handler)
    }
    
    func groups(handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
}