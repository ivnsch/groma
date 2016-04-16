//
//  RemoteListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Valet

class RemoteListItemProvider {


    // get product for name + list (unique)
    // this is necessary to find the uuid of a possibly already existing product, which may not be stored in the local database
    // (e.g. user uses 2 devices, device 2 doesn't have the recently added products in device 1 in it's local database, so it has to request the server)
    // Note that this overall needs more development, since device 2 can add products offline and we can get conflicts (same name, diff uuids) with the server
    // TODO do we really need list here ? didnt we want to make products global?
    func product(name: String, list: List, handler: RemoteResult<RemoteProduct> -> ()) {
        let params = [
            "name": name,
            "listUuid": list.uuid,
        ]
        RemoteProvider.authenticatedRequest(.GET, Urls.productWithUnique, params) {result in
            handler(result)
        }
    }

    func section(name: String, list: List, handler: RemoteResult<RemoteSection> -> ()) {
        let params = [
            "name": name,
            "listUuid": list.uuid,
        ]
        RemoteProvider.authenticatedRequest(.GET, Urls.sectionWithUnique, params) {result in
            handler(result)
        }
    }
    
    func lists(handler: RemoteResult<RemoteListsWithDependencies> -> ()) {
        RemoteProvider.authenticatedRequest(.GET, Urls.lists) {result in
            handler(result)
        }
    }

    func listItems(list list: List, handler: RemoteResult<RemoteListItems> -> ()) {
        RemoteProvider.authenticatedRequest(.GET, Urls.listItems, ["list": list.uuid]) {result in
            handler(result)
        }
    }
    
    func removeListItem(listItemUuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.listItem + "/\(listItemUuid)") {result in
            handler(result)
        }
    }
    
    func remove(section: Section, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.section + "/\(section.uuid)", toRequestParams(section)) {result in
            handler(result)
        }
    }
    
    
    func remove(listUuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.list + "/\(listUuid)") {result in
            handler(result)
        }
    }
    
    func update(list: List, handler: RemoteResult<RemoteListsWithDependencies> -> ()) {
        let parameters = self.toRequestParams(list)
        RemoteProvider.authenticatedRequest(.PUT, Urls.list, parameters) {result in
            handler(result)
        }
    }
    
    func update(lists: [List], handler: RemoteResult<RemoteListsWithDependencies> -> ()) {
        let parameters = lists.map{self.toRequestParams($0)}
        RemoteProvider.authenticatedRequest(.PUT, Urls.lists, parameters) {result in
            handler(result)
        }
    }
    
    func add(listItem: ListItem, handler: RemoteResult<RemoteListItems> -> ()) {
        let parameters = self.toRequestParams(listItem)
        RemoteProvider.authenticatedRequest(.POST, Urls.addListItem, parameters) {result in
            handler(result)
        }
    }

    func add(listItems: [ListItem], handler: RemoteResult<RemoteListItems> -> ()) {
        let parameters = toRequestParams(listItems)
        RemoteProvider.authenticatedRequest(.POST, Urls.addListItems, parameters) {result in
            handler(result)
        }
    }
    
//    func update(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
//        let parameters = self.toRequestParams(listItem)
//        RemoteProvider.authenticatedRequest(.PUT, Urls.listItem, parameters) {result in
//            handler(result)
//        }
//    }
    
//    RemoteSwitchListItemResult
    func updateStatus(listItem: ListItem, statusUpdate: ListItemStatusUpdate, handler: RemoteResult<RemoteSwitchListItemResult> -> Void) {
        let parameters = toRequestParamsForStatusUpdate(listItem, statusUpdate: statusUpdate)
        RemoteProvider.authenticatedRequest(.PUT, Urls.updateListItemStatus, parameters) {result in
            handler(result)
        }
    }
    
    // IMPORTANT: Assumes that the passed list items are ALL the existing list items in src status. If this is not the case, the remaining items/sections in src status will likely be left with a wrong order.
    func updateAllStatus(listUuid: String, statusUpdate: ListItemStatusUpdate, handler: RemoteResult<RemoteSwitchAllListItemsResult> -> ()) {
        let parameters: [String: AnyObject] = ["listUuid": listUuid, "src": statusUpdate.dst.rawValue, "dst": statusUpdate.dst.rawValue]
        RemoteProvider.authenticatedRequest(.PUT, Urls.updateAllListItemsStatus, parameters) {result in
            handler(result)
        }
    }
    
    // TODO use update
    func update(listItems: [ListItem], handler: RemoteResult<RemoteListItems> -> ()) {
        let parameters = listItems.map{self.toRequestParams($0)}
        RemoteProvider.authenticatedRequest(.PUT, Urls.listItems, parameters) {result in
            handler(result)
        }
    }
    
    // TODO!!!! review these responses, the server isn't sending anything back. Do we want to update timestamp on order updates (list, inventory, group, listitem) or not?
    func updateListItemsOrder(listItems: [ListItem], status: ListItemStatus, handler: RemoteResult<[RemoteOrderUpdate]> -> ()) {
        let params: [[String: AnyObject]] = listItems.map{
            ["uuid": $0.uuid, "sectionUuid": $0.section.uuid, "order": $0.todoOrder]
        }
        let url: String = {
            switch status {
            case .Todo: return Urls.listItemsOrder
            case .Done: return Urls.listItemsDoneOrder
            case .Stash: return Urls.listItemsStashOrder
            }
        }()
        
        RemoteProvider.authenticatedRequestArray(.PUT, url, params) {result in
            handler(result)
        }
    }
    
    func updateListsOrder(orderUpdates: [OrderUpdate], handler: RemoteResult<[RemoteOrderUpdate]> -> ()) {
        let params: [[String: AnyObject]] = orderUpdates.map{
            ["uuid": $0.uuid, "order": $0.order]
        }
        RemoteProvider.authenticatedRequestArray(.PUT, Urls.listsOrder, params) {result in
            handler(result)
        }
    }
    
    func incrementListItem(listItem: ListItem, delta: Int, status: ListItemStatus, handler: RemoteResult<RemoteListItemIncrementResult> -> ()) {
        let params: [String: AnyObject] = [
            "uuid": listItem.uuid,
            "status": status.rawValue,
            "delta": delta
        ]
        RemoteProvider.authenticatedRequest(.POST, Urls.incrementListItem, params) {result in
            handler(result)
        }
    }
    
    func add(list: List, handler: RemoteResult<RemoteListsWithDependencies> -> ()) {
        let parameters = toRequestPrams(list)
        RemoteProvider.authenticatedRequest(.POST, Urls.list, parameters) {result in
            handler(result)
        }
    }

    func add(section: Section, handler: RemoteResult<RemoteSection> -> ()) {

        let listDict = toRequestParams(section.list)

        let parameters: [String: AnyObject] = [
            "uuid": section.uuid,
            "name": section.name,
            "color": section.color.hexStr,
            "list": listDict,
            "todoOrder": section.todoOrder,
            "doneOrder": section.doneOrder,
            "stashOrder": section.stashOrder
        ]
        RemoteProvider.authenticatedRequest(.POST, Urls.section, parameters) {result in
            handler(result)
        }
    }

    func syncListsWithListItems(listsSync: ListsSync, handler: RemoteResult<RemoteListWithListItemsSyncResult> -> ()) {
        
        let lystsSyncDicts: [[String: AnyObject]] = listsSync.listsSyncs.map {listSync in
            
            let list = listSync.list
            
            let sharedUsers: [[String: AnyObject]] = list.users.map{self.toRequestParams($0)}
            
            var dict: [String: AnyObject] = [
                "uuid": list.uuid,
                "name": list.name,
                "order": list.order,
                "users": sharedUsers,
            ]
            
            if let lastServerUpdate = list.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
            }
            
            let listItemsDicts = listSync.listItemsSync.listItems.map {toRequestParams($0)}
            let toRemoveDicts = listSync.listItemsSync.toRemove.map{self.toRequestParamsToRemove($0)}
            let listItemsSyncDict: [String: AnyObject] = [
                "listItems": listItemsDicts,
                "toRemove": toRemoveDicts
            ]

            dict["listItems"] = listItemsSyncDict
            
            return dict
        }
        
        let toRemoveDicts = listsSync.toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "lists": lystsSyncDicts,
            "toRemove": toRemoveDicts
        ]

        RemoteProvider.authenticatedRequest(.POST, Urls.listsWithItemsSync, dictionary) {result in
            handler(result)
        }
    }
    
    func acceptInvitation(invitation: RemoteListInvitation, handler: RemoteResult<NoOpSerializable> -> Void) {
        let parameters = toRequestParams(invitation, accept: true)
        RemoteProvider.authenticatedRequest(.POST, Urls.listInvitation, parameters) {result in
            handler(result)
        }
    }

    func rejectInvitation(invitation: RemoteListInvitation, handler: RemoteResult<NoOpSerializable> -> Void) {
        let parameters = toRequestParams(invitation, accept: false)
        RemoteProvider.authenticatedRequest(.POST, Urls.listInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func findInvitedUsers(listUuid: String, handler: RemoteResult<[RemoteSharedUser]> -> Void) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.listInvitedUsers + "/\(listUuid)") {result in
            handler(result)
        }
    }
    
//    // for unit tests
//    func removeAll(handler: Try<Bool> -> ()) {
//        Alamofire.request(.GET, Urls.removeAll).responseString { (request, _, string: String?) in
//            if let success = string?.boolValue {
//                handler(Try(success))
//            }
//        }
//    }
    
    //////////////////
    
    
    func toRequestParams(invitation: RemoteListInvitation, accept: Bool) -> [String: AnyObject] {
        
        let sharedUser = SharedUser(email: invitation.sender) // TODO as commented in the invitation objs, these should contain shared user not only email (this means the server has to send us the shared user)
        
        return [
            "uuid": invitation.list.uuid,
            "accept": accept,
            "sender": toRequestParams(sharedUser)
        ]
    }
    
    func toRequestPrams(list: List) -> [String: AnyObject] {
        
        let inventoryDict = RemoteInventoryProvider().toRequestParams(list.inventory)

        var dict: [String: AnyObject] = [
            "uuid": list.uuid,
            "name": list.name,
            "order": list.order,
            "color": list.bgColor.hexStr,
            "users": list.users.map{self.toRequestParams($0)},
            "inventory": inventoryDict
        ]
        
        if let lastServerUpdate = list.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
    
    func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }

    func toRequestParams(listItems: [ListItem]) -> [[String: AnyObject]] {
        return listItems.map{toRequestParams($0)}
    }

    func toRequestParams(section: Section) -> [String: AnyObject] {
        
        let listDict = toRequestParams(section.list)

        var dict: [String: AnyObject] = [
            "uuid": section.uuid,
            "name": section.name,
            "color": section.color.hexStr,
            "todoOrder": section.todoOrder,
            "doneOrder": section.doneOrder,
            "stashOrder": section.stashOrder,
            "listInput": listDict
        ]
        
        if let lastServerUpdate = section.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }

        return dict
    }
    
    func toRequestParams(listItem: ListItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": listItem.uuid,
            "note": listItem.note ?? "",
            "todoQuantity": listItem.todoQuantity,
            "todoOrder": listItem.todoOrder,
            "doneQuantity": listItem.doneQuantity,
            "doneOrder": listItem.doneOrder,
            "stashQuantity": listItem.stashQuantity,
            "stashOrder": listItem.stashOrder,
            "storeProductInput": toRequestParams(listItem.product),
            "listUuid": listItem.list.uuid,
            "listName": listItem.list.name,
            "sectionInput": toRequestParams(listItem.section),
        ]
        
        if let lastServerUpdate = listItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict

    }

    func toRequestParamsForStatusUpdate(listItem: ListItem, statusUpdate: ListItemStatusUpdate) -> [String: AnyObject] {
        return [
            "uuid": listItem.uuid,
            "src": statusUpdate.src.rawValue,
            "dst": statusUpdate.dst.rawValue,
            "l": listItem.list.uuid,
            "s": listItem.section.uuid
        ]
    }

    func toRequestParams(product: StoreProduct) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": product.uuid,
            "price": product.price,
            "baseQuantity": product.baseQuantity,
            "unit": product.unit.rawValue,
            "store": product.store,            
            "product": toRequestParams(product.product)
        ]
        
        if let lastServerUpdate = product.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
    
    func toRequestParams(product: Product) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": product.uuid,
            "name": product.name,
            "brand": product.brand,
            "category": toRequestParams(product.category),
            "fav": product.fav
        ]
        
        if let lastServerUpdate = product.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
    
    func toRequestParams(productCategory: ProductCategory) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": productCategory.uuid,
            "name": productCategory.name,
            "color": productCategory.color.hexStr
        ]
        
        if let lastServerUpdate = productCategory.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
    
    func toRequestParamsShort(list: List) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": list.uuid,
            "name": list.name,
            "order": list.order,
            "color": list.bgColor.hexStr
        ]
        
        if let lastServerUpdate = list.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        
        return dict
    }
    
    func toRequestParams(list: List) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = list.users.map{self.toRequestParams($0)}
        var listDict = self.toRequestParamsShort(list)
        listDict["users"] = sharedUsers
        let inventoryDict = RemoteInventoryProvider().toRequestParams(list.inventory)
        listDict["inventory"] = inventoryDict
        return listDict
    }
    
    func toRequestParamsToRemove(listItem: ListItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": listItem.uuid]
        if let lastServerUpdate = listItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        return dict
    }

    func toRequestParamsToRemove(list: List) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": list.uuid]
        if let lastServerUpdate = list.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(longLong: Int64(lastServerUpdate))
        }
        return dict
    }
}




