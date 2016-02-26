//
//  RemoteGroupsProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteGroupsProvider: RemoteProvider {
    
    func groups(handler: RemoteResult<[RemoteInventory]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.groups) {result in
            handler(result)
        }
    }
    
    func addGroup(group: ListItemGroup, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.POST, Urls.group, params) {result in
            handler(result)
        }
    }
    
    func updateGroup(group: ListItemGroup, handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.PUT, Urls.group, params) {result in
            handler(result)
        }
    }

    func updateGroups(groups: [ListItemGroup], handler: RemoteResult<NoOpSerializable> -> ()) {
        let params = groups.map{toRequestParams($0)}
        RemoteProvider.authenticatedRequest(.PUT, Urls.groups, params) {result in
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
    
    func groupsItems(group: ListItemGroup, handler: RemoteResult<[RemoteInventory]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.groupItems) {result in
            handler(result)
        }
    }
    
    func addGroupItem(groupItem: GroupItem, group: ListItemGroup, handler: RemoteResult<RemoteGroupItemsWithDependencies> -> ()) {
        let params = toRequestParams(groupItem, group: group)
        RemoteProvider.authenticatedRequest(.POST, Urls.groupItem, params) {result in
            handler(result)
        }
    }
    
    func updateGroupItem(groupItem: GroupItem, group: ListItemGroup, handler: RemoteResult<RemoteGroupItemsWithDependencies> -> ()) {
        let params = toRequestParams(groupItem, group: group)
        RemoteProvider.authenticatedRequest(.PUT, Urls.groupItem, params) {result in
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
    
    func toRequestParams(groupItem: GroupItem, group: ListItemGroup) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(groupItem.product)
        
        let groupDict = toRequestParams(group)
        
        let dict: [String: AnyObject] = [
            "uuid": groupItem.uuid,
            "quantity": groupItem.quantity,
            "product": productDict,
            "group": groupDict
        ]
        return dict
    }
}
