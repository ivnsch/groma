//
//  RemoteGroupsProvider.swift
//  shoppin
//
//  Created by ischuetz on 08/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteGroupsProvider: RemoteProvider {
    
    func groups(_ handler: @escaping (RemoteResult<[RemoteGroup]>) -> ()) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.groups) {result in
            handler(result)
        }
    }
    
    func addGroup(_ group: ProductGroup, handler: @escaping (RemoteResult<RemoteGroup>) -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.post, Urls.group, params) {result in
            handler(result)
        }
    }
    
    func updateGroup(_ group: ProductGroup, handler: @escaping (RemoteResult<RemoteGroup>) -> ()) {
        let params = toRequestParams(group)
        RemoteProvider.authenticatedRequest(.put, Urls.group, params) {result in
            handler(result)
        }
    }
    
    func updateGroupsOrder(_ orderUpdates: [OrderUpdate], handler: @escaping (RemoteResult<[RemoteOrderUpdate]>) -> ()) {
        let params: [[String: AnyObject]] = orderUpdates.map{
            ["uuid": $0.uuid as AnyObject, "order": $0.order as AnyObject]
        }
        RemoteProvider.authenticatedRequestArray(.put, Urls.groupsOrder, params) {result in
            handler(result)
        }
    }
    
    func incrementFav(_ groupUuid: String, handler: @escaping (RemoteResult<RemoteProduct>) -> ()) {
        RemoteProvider.authenticatedRequest(.put, Urls.favGroup + "/\(groupUuid)") {result in
            handler(result)
        }
    }

    func updateGroups(_ groups: [ProductGroup], handler: @escaping (RemoteResult<[RemoteGroup]>) -> ()) {
        let params = groups.map{toRequestParams($0)}
        RemoteProvider.authenticatedRequestArray(.put, Urls.groups, params) {result in
            handler(result)
        }
    }
    
    func removeGroup(_ group: ProductGroup, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        removeGroup(group.uuid, handler: handler)
    }
    
    func removeGroup(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.group + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func groupsItems(_ group: ProductGroup, handler: @escaping (RemoteResult<RemoteGroupItemsWithDependencies>) -> ()) {
        RemoteProvider.authenticatedRequest(.get, Urls.groupItems, ["groupUuid": group.uuid as AnyObject]) {result in
            handler(result)
        }
    }
    
    func addGroupItem(_ groupItem: GroupItem, handler: @escaping (RemoteResult<RemoteGroupItemsWithDependencies>) -> ()) {
        addGroupItems([groupItem], handler: handler)
    }

    func addGroupItems(_ groupItems: [GroupItem], handler: @escaping (RemoteResult<RemoteGroupItemsWithDependencies>) -> ()) {
        let params = groupItems.map{toRequestParams($0)}
        RemoteProvider.authenticatedRequest(.post, Urls.groupItems, params) {result in
            handler(result)
        }
    }
    
    func updateGroupItem(_ groupItem: GroupItem, handler: @escaping (RemoteResult<RemoteGroupItemsWithDependencies>) -> ()) {
        let params = toRequestParams(groupItem)
        RemoteProvider.authenticatedRequest(.put, Urls.groupItem, params) {result in
            handler(result)
        }
    }
    
    func incrementGroupItem(_ increment: ItemIncrement, handler: @escaping (RemoteResult<RemoteIncrementResult>) -> ()) {
        let params: [String: AnyObject] = [
            "delta": increment.delta as AnyObject,
            "uuid": increment.itemUuid as AnyObject
        ]
        RemoteProvider.authenticatedRequest(.post, Urls.incrementGroupItem, params) {result in
            handler(result)
        }
    }
    
    func removeGroupItem(_ groupItem: GroupItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        removeGroupItem(groupItem.uuid, handler: handler)
    }
    
    func removeGroupItem(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.groupItem + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func toRequestParams(_ group: ProductGroup) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": group.uuid as AnyObject,
            "name": group.name as AnyObject,
            "order": group.order as AnyObject,
            "color": group.color.hexStr as AnyObject,
            "fav": group.fav as AnyObject
        ]
        
        dict["lastUpdate"] = NSNumber(value: Int64(group.lastServerUpdate) as Int64)

        return dict
    }
    
    func toRequestParams(_ groupItem: GroupItem) -> [String: AnyObject] {
        
        let productDict = RemoteListItemProvider().toRequestParams(groupItem.product)
        
        let groupDict = toRequestParams(groupItem.group)
        
        var dict: [String: AnyObject] = [
            "uuid": groupItem.uuid as AnyObject,
            "quantity": groupItem.quantity as AnyObject,
            "product": productDict as AnyObject,
            "group": groupDict as AnyObject
        ]
        
        dict["lastUpdate"] = NSNumber(value: Int64(groupItem.lastServerUpdate) as Int64)
        
        return dict
    }
}
