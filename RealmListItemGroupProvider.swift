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
        self.load(mapper, filter: "group.uuid = '\(group.uuid)'", handler: handler)
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
    
    func update(groups: [ListItemGroup], handler: Bool -> Void) {
        let dbObjs = groups.map{ListItemGroupMapper.dbWith($0)}
        saveObjs(dbObjs, update: true, handler: handler)
    }
    
    func remove(group: ListItemGroup, handler: Bool -> Void) {
        self.remove("uuid = '\(group.uuid)'", handler: handler, objType: DBListItemGroup.self)
    }
    
    func add(groupItem: GroupItem, handler: Bool -> Void) {
        addOrUpdate(groupItem, handler: handler)
    }

    func addOrIncrement(groupItems: [GroupItem], handler: Bool -> Void) {
        
        func addOrIncrement(groupItems: [GroupItem]) -> Bool {
            do {
                // load items
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                let groupItemsUuidsStr: String = groupItems.map{"'\($0.uuid)'"}.joinWithSeparator(",")
                
                let items = loadSync(realm, mapper: mapper, filter: "uuid IN {\(groupItemsUuidsStr)}")
                // decide if add/increment
                let dict: [String: GroupItem] = items.toDictionary{($0.uuid, $0)}
                let newOrIncrementedGroupItems: [DBGroupItem] = groupItems.map {groupItem in
                    let item: GroupItem = {
                        if let storedGroupItem = dict[groupItem.uuid] { // item exists - update existing one with incremented copy
                            return storedGroupItem.incrementQuantityCopy(groupItem.quantity)
                        } else { // item doesn't exist - create a new one
                            return groupItem
                        }
                    }()
                    return GroupItemMapper.dbWith(item)
                }
                //save
                saveObjsSync(newOrIncrementedGroupItems, update: true)
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(success: Bool) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItems)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(false)
            }
        })
    }
    
    func addOrIncrement(groupItem: GroupItem, handler: Bool -> Void) {
        
        func addOrIncrement(item: GroupItem) -> Bool {
            do {
                let realm = try Realm()
                let mapper = {GroupItemMapper.groupItemWith($0)}
                if let item = loadSync(realm, mapper: mapper, filter: "product.name = '\(groupItem.product.name)' && group.uuid = '\(groupItem.group.uuid)'").first {
                    let incremented = item.incrementQuantityCopy(groupItem.quantity)
                    let dbItem = GroupItemMapper.dbWith(incremented)
                    saveObjSync(dbItem, update: true)
                } else {
                    let dbItem = GroupItemMapper.dbWith(groupItem)
                    saveObjSync(dbItem, update: true)
                }
                return true
                
            } catch let error {
                print("Error: creating Realm() in load, returning empty results. Error: \(error)")
                return false // for now return empty array - review this in the future, maybe it's better to return nil or a custom result object, or make function throws...
            }
        }
        
        func finished(success: Bool) {
            dispatch_async(dispatch_get_main_queue(), {
                handler(success)
            })
        }
    
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {[weak self] in
            if let weakSelf = self {
                let success = syncedRet(weakSelf) {
                    addOrIncrement(groupItem)
                }
                finished(success)
            } else {
                print("Error: RealmListItemGroupProvider.addOrIncrement: no self")
                finished(false)
            }
        })
    }
    
    func update(groupItem: GroupItem, handler: Bool -> Void) {
        addOrUpdate(groupItem, handler: handler)
    }
    
    func addOrUpdate(groupItem: GroupItem, handler: Bool -> Void) {
        let dbObj = GroupItemMapper.dbWith(groupItem)
        saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(groupItem: GroupItem, handler: Bool -> Void) {
        remove("uuid = '\(groupItem.uuid)'", handler: handler, objType: DBGroupItem.self)
    }
}