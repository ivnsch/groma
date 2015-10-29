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

    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(groups: [ListItemGroup], handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }

    func update(groups: [ListItemGroup], handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func add(groupItems: [GroupItem], handler: Bool -> Void) {
        let dbObjs = groupItems.map{GroupItemMapper.dbWith($0)}
        self.saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func groups(handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
    
    func groupItems(group: ListItemGroup, handler: [GroupItem] -> Void) {
        let mapper = {GroupItemMapper.groupItemWith($0)}
        self.load(mapper, filter: "uuid = '\(group.uuid)'", handler: handler)
    }
    
    func remove(group: ListItemGroup, handler: Bool -> Void) {
        self.remove("uuid = '\(group.uuid)'", handler: handler, objType: DBListItemGroup.self)
    }
}