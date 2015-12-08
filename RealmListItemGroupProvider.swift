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
    
    func groups(range: NSRange, handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, range: range, handler: handler)
    }
    
    func groupsContainingText(text: String, handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        let filter = "name CONTAINS[c] '\(text)'"
        self.load(mapper, filter: filter, handler: handler)
    }
    
    func groupItems(group: ListItemGroup, handler: [GroupItem] -> Void) {
        let mapper = {GroupItemMapper.groupItemWith($0)}
        self.load(mapper, filter: "uuid = '\(group.uuid)'", handler: handler)
    }

    // TODO remove
    func groups(handler: [ListItemGroup] -> Void) {
        let mapper = {ListItemGroupMapper.listItemGroupWith($0)}
        self.load(mapper, handler: handler)
    }
    
    // TODO add group -> update: false, but show an alert to the user that group already exists instead of crash
    func add(group: ListItemGroup, handler: Bool -> Void) {
        update(group, handler: handler)
    }

    func update(group: ListItemGroup, handler: Bool -> Void) {
        let dbObj = ListItemGroupMapper.dbWith(group)
        saveObj(dbObj, update: true, handler: handler)
    }

    func remove(group: ListItemGroup, handler: Bool -> Void) {
        self.remove("uuid = '\(group.uuid)'", handler: handler, objType: DBListItemGroup.self)
    }
    
    func add(groupItem: GroupItem, handler: Bool -> Void) {
        update(groupItem, handler: handler)
    }

    func update(groupItem: GroupItem, handler: Bool -> Void) {
        let dbObj = GroupItemMapper.dbWith(groupItem)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(groupItem: GroupItem, handler: Bool -> Void) {
        remove("uuid = '\(groupItem.uuid)'", handler: handler, objType: DBGroupItem.self)
    }
}