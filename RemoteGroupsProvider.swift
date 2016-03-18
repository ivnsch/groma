//
//  RemoteGroupsProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteGroupsProvider: RemoteProvider {
    
    func groups(handler: RemoteResult<[RemoteGroup]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.groups) {result in
            handler(result)
        }
    }
    
    func addGroup(group: ListItemGroup, handler: RemoteResult<RemoteGroup> -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.POST, Urls.group, params) {result in
            handler(result)
        }
    }
    
    func updateGroup(group: ListItemGroup, handler: RemoteResult<RemoteGroup> -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.PUT, Urls.group, params) {result in
            handler(result)
        }
    }

    func updateGroups(groups: [ListItemGroup], handler: RemoteResult<[RemoteGroup]> -> ()) {
        let params = groups.map{toRequestParams($0)}
        RemoteProvider.authenticatedRequestArray(.PUT, Urls.groups, params) {result in
            handler(result)
        }
    }
    
    func removeGroup(group: ListItemGroup, handler: RemoteResult<NoOpSerializable> -> ()) {
        removeGroup(group.uuid, handler: handler)
    }
    
    func removeGroup(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.group + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func groupsItems(group: ListItemGroup, handler: RemoteResult<RemoteGroupItemsWithDependencies> -> ()) {
        RemoteProvider.authenticatedRequest(.GET, Urls.groupItems, ["groupUuid": group.uuid]) {result in
            handler(result)
        }
    }
    
    func addGroupItem(groupItem: GroupItem, handler: RemoteResult<RemoteGroupItemsWithDependencies> -> ()) {
        let params = toRequestParams(groupItem)
        RemoteProvider.authenticatedRequest(.POST, Urls.groupItem, params) {result in
            handler(result)
        }
    }
    
    func updateGroupItem(groupItem: GroupItem, handler: RemoteResult<RemoteGroupItemsWithDependencies> -> ()) {
        let params = toRequestParams(groupItem)
        RemoteProvider.authenticatedRequest(.PUT, Urls.groupItem, params) {result in
            handler(result)
        }
    }
    
    func incrementGroupItem(increment: ItemIncrement, delta: Int, handler: RemoteResult<NSDate> -> ()) {
        let params: [String: AnyObject] = [
            "delta": increment.delta,
            "uuid": increment.itemUuid
        ]
        RemoteProvider.authenticatedRequestTimestamp(.POST, Urls.incrementGroupItem, params) {result in
            handler(result)
        }
    }
    
    func removeGroupItem(groupItem: GroupItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        removeGroupItem(groupItem.uuid, handler: handler)
    }
    
    func removeGroupItem(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.groupItem + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func toRequestParams(group: ListItemGroup) -> [String: AnyObject] {
        let dict: [String: AnyObject] = [
            "uuid": group.uuid,
            "name": group.name,
            "order": group.order,
            "color": group.bgColor.hexStr,
            "fav": group.fav
        ]
        return dict
    }
    
    func toRequestParams(groupItem: GroupItem) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(groupItem.product)
        
        let groupDict = toRequestParams(groupItem.group)
        
        let dict: [String: AnyObject] = [
            "uuid": groupItem.uuid,
            "quantity": groupItem.quantity,
            "product": productDict,
            "group": groupDict
        ]
        return dict
    }
}
