//
//  RemoteListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteListItemProvider {


    // get product for name + list (unique)
    // this is necessary to find the uuid of a possibly already existing product, which may not be stored in the local database
    // (e.g. user uses 2 devices, device 2 doesn't have the recently added products in device 1 in it's local database, so it has to request the server)
    // Note that this overall needs more development, since device 2 can add products offline and we can get conflicts (same name, diff uuids) with the server
    // TODO do we really need list here ? didnt we want to make products global?
    func product(_ name: String, list: List, handler: @escaping (RemoteResult<RemoteProduct>) -> ()) {
        let params: [String: AnyObject] = [
            "name": name as AnyObject,
            "listUuid": list.uuid as AnyObject,
        ]
        RemoteProvider.authenticatedRequest(.get, Urls.productWithUnique, params) {result in
            handler(result)
        }
    }

    func section(_ name: String, list: List, handler: @escaping (RemoteResult<RemoteSection>) -> ()) {
        let params: [String: AnyObject] = [
            "name": name as AnyObject,
            "listUuid": list.uuid as AnyObject,
        ]
        RemoteProvider.authenticatedRequest(.get, Urls.sectionWithUnique, params) {result in
            handler(result)
        }
    }
    
    func lists(_ handler: @escaping (RemoteResult<RemoteListsWithDependencies>) -> ()) {
        RemoteProvider.authenticatedRequest(.get, Urls.lists) {result in
            handler(result)
        }
    }

    func listItems(list: List, handler: @escaping (RemoteResult<RemoteListItems>) -> ()) {
        let params: [String: AnyObject] = ["list": list.uuid as AnyObject]
        RemoteProvider.authenticatedRequest(.get, Urls.listItems, params) {result in
            handler(result)
        }
    }
    
    func removeListItem(_ listItemUuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.listItem + "/\(listItemUuid)") {result in
            handler(result)
        }
    }
    
    func remove(_ section: Section, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.section + "/\(section.uuid)", toRequestParams(section)) {result in
            handler(result)
        }
    }
    
    
    func remove(_ listUuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.list + "/\(listUuid)") {result in
            handler(result)
        }
    }
    
    func update(_ list: List, handler: @escaping (RemoteResult<RemoteListsWithDependencies>) -> ()) {
        let parameters = self.toRequestParams(list)
        RemoteProvider.authenticatedRequest(.put, Urls.list, parameters) {result in
            handler(result)
        }
    }
    
    func update(_ lists: [List], handler: @escaping (RemoteResult<Int64>) -> ()) {
        let parameters = lists.map{self.toRequestParams($0)}
        RemoteProvider.authenticatedRequestArrayParamsTimestamp(.put, Urls.lists, parameters) {result in
            handler(result)
        }
    }
    
    func add(_ listItem: ListItem, handler: @escaping (RemoteResult<RemoteListItems>) -> ()) {
        let parameters = self.toRequestParams(listItem)
        RemoteProvider.authenticatedRequest(.post, Urls.addListItem, parameters) {result in
            handler(result)
        }
    }

    func add(_ listItems: [ListItem], handler: @escaping (RemoteResult<RemoteListItems>) -> ()) {
        let parameters = toRequestParams(listItems)
        RemoteProvider.authenticatedRequest(.post, Urls.addListItems, parameters) {result in
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
    func updateStatus(_ listItem: ListItem, statusUpdate: ListItemStatusUpdate, handler: @escaping (RemoteResult<RemoteSwitchListItemResult>) -> Void) {
        let parameters = toRequestParamsForStatusUpdate(listItem, statusUpdate: statusUpdate)
        RemoteProvider.authenticatedRequest(.put, Urls.updateListItemStatus, parameters) {result in
            handler(result)
        }
    }

    func buyCart(_ listUuid: String, inventoryItems: [InventoryItemWithHistoryItem], handler: @escaping (RemoteResult<Int64>) -> Void) {
        let parameters = toRequestParams(listUuid, items: inventoryItems)
        RemoteProvider.authenticatedRequestTimestamp(.post, Urls.buyCart, parameters) {result in
            handler(result)
        }
    }
    
    // IMPORTANT: Assumes that the passed list items are ALL the existing list items in src status. If this is not the case, the remaining items/sections in src status will likely be left with a wrong order.
    func updateAllStatus(_ listUuid: String, statusUpdate: ListItemStatusUpdate, handler: @escaping (RemoteResult<RemoteSwitchAllListItemsResult>) -> ()) {
        let parameters: [String: AnyObject] = ["listUuid": listUuid as AnyObject, "src": statusUpdate.src.rawValue as AnyObject, "dst": statusUpdate.dst.rawValue as AnyObject]
        RemoteProvider.authenticatedRequest(.put, Urls.updateAllListItemsStatus, parameters) {result in
            handler(result)
        }
    }
    
    // TODO use update
    func update(_ listItems: [ListItem], handler: @escaping (RemoteResult<RemoteListItems>) -> ()) {
        let parameters = listItems.map{self.toRequestParams($0)}
        RemoteProvider.authenticatedRequest(.put, Urls.listItems, parameters) {result in
            handler(result)
        }
    }
    
    // TODO!!!! review these responses, the server isn't sending anything back. Do we want to update timestamp on order updates (list, inventory, group, listitem) or not?
    func updateListItemsOrder(_ listItems: [ListItem], status: ListItemStatus, handler: @escaping (RemoteResult<[RemoteOrderUpdate]>) -> ()) {
        let params: [[String: AnyObject]] = listItems.map{
            ["uuid": $0.uuid as AnyObject, "sectionUuid": $0.section.uuid as AnyObject, "order": $0.order(status) as AnyObject]
        }
        let url: String = {
            switch status {
            case .todo: return Urls.listItemsOrder
            case .done: return Urls.listItemsDoneOrder
            case .stash: return Urls.listItemsStashOrder
            }
        }()
        
        RemoteProvider.authenticatedRequestArray(.put, url, params) {result in
            handler(result)
        }
    }
    
    func updateListsOrder(_ orderUpdates: [OrderUpdate], handler: @escaping (RemoteResult<[RemoteOrderUpdate]>) -> ()) {
        let params: [[String: AnyObject]] = orderUpdates.map{
            ["uuid": $0.uuid as AnyObject, "order": $0.order as AnyObject]
        }
        RemoteProvider.authenticatedRequestArray(.put, Urls.listsOrder, params) {result in
            handler(result)
        }
    }
    
    func incrementListItem(_ listItem: ListItem, delta: Int, status: ListItemStatus, handler: @escaping (RemoteResult<RemoteListItemIncrementResult>) -> ()) {
        let params: [String: AnyObject] = [
            "uuid": listItem.uuid as AnyObject,
            "status": status.rawValue as AnyObject,
            "delta": delta as AnyObject
        ]
        RemoteProvider.authenticatedRequest(.post, Urls.incrementListItem, params) {result in
            handler(result)
        }
    }
    
    func add(_ list: List, handler: @escaping (RemoteResult<Int64>) -> Void) {
        let parameters = toRequestPrams(list)
        RemoteProvider.authenticatedRequestTimestamp(.post, Urls.list, parameters) {result in
            handler(result)
        }
    }

    func add(_ section: Section, handler: @escaping (RemoteResult<RemoteSection>) -> ()) {

        let listDict = toRequestParams(section.list)

        let parameters: [String: AnyObject] = [
            "uuid": section.uuid as AnyObject,
            "name": section.name as AnyObject,
            "color": section.color.hexStr as AnyObject,
            "list": listDict as AnyObject,
            "todoOrder": section.todoOrder as AnyObject,
            "doneOrder": section.doneOrder as AnyObject,
            "stashOrder": section.stashOrder as AnyObject
        ]
        RemoteProvider.authenticatedRequest(.post, Urls.section, parameters) {result in
            handler(result)
        }
    }

    func syncListsWithListItems(_ listsSync: ListsSync, handler: @escaping (RemoteResult<RemoteListWithListItemsSyncResult>) -> ()) {
        
        let lystsSyncDicts: [[String: AnyObject]] = listsSync.listsSyncs.map {listSync in
            
            let list = listSync.list
            
            let sharedUsers: [[String: AnyObject]] = list.users.map{self.toRequestParams($0)}
            
            var dict: [String: AnyObject] = [
                "uuid": list.uuid as AnyObject,
                "name": list.name as AnyObject,
                "order": list.order as AnyObject,
                "users": sharedUsers as AnyObject,
            ]
            
            dict["lastUpdate"] = NSNumber(value: Int64(list.lastServerUpdate) as Int64)
            
            let listItemsDicts = listSync.listItemsSync.listItems.map {toRequestParams($0)}
            let toRemoveDicts = listSync.listItemsSync.toRemove.map{self.toRequestParamsToRemove($0)}
            let listItemsSyncDict: [String: AnyObject] = [
                "listItems": listItemsDicts as AnyObject,
                "toRemove": toRemoveDicts as AnyObject
            ]

            dict["listItems"] = listItemsSyncDict as AnyObject?
            
            return dict
        }
        
        let toRemoveDicts = listsSync.toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "lists": lystsSyncDicts as AnyObject,
            "toRemove": toRemoveDicts as AnyObject
        ]

        RemoteProvider.authenticatedRequest(.post, Urls.listsWithItemsSync, dictionary) {result in
            handler(result)
        }
    }
    
    func acceptInvitation(_ invitation: RemoteListInvitation, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let parameters = toRequestParams(invitation, accept: true)
        RemoteProvider.authenticatedRequest(.post, Urls.listInvitation, parameters) {result in
            handler(result)
        }
    }

    func rejectInvitation(_ invitation: RemoteListInvitation, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let parameters = toRequestParams(invitation, accept: false)
        RemoteProvider.authenticatedRequest(.post, Urls.listInvitation, parameters) {result in
            handler(result)
        }
    }
    
    func findInvitedUsers(_ listUuid: String, handler: @escaping (RemoteResult<[RemoteSharedUser]>) -> Void) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.listInvitedUsers + "/\(listUuid)") {result in
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
    
    
    func toRequestParams(_ invitation: RemoteListInvitation, accept: Bool) -> [String: AnyObject] {
        
        let sharedUser = DBSharedUser(email: invitation.sender) // TODO as commented in the invitation objs, these should contain shared user not only email (this means the server has to send us the shared user)
        
        return [
            "uuid": invitation.list.uuid as AnyObject,
            "accept": accept as AnyObject,
            "sender": toRequestParams(sharedUser) as AnyObject
        ]
    }
    
    func toRequestPrams(_ list: List) -> [String: AnyObject] {
        
        let inventoryDict = RemoteInventoryProvider().toRequestParams(list.inventory)

        var dict: [String: AnyObject] = [
            "uuid": list.uuid as AnyObject,
            "name": list.name as AnyObject,
            "order": list.order as AnyObject,
            "color": list.color.hexStr as AnyObject,
            "users": list.users.map{self.toRequestParams($0)} as AnyObject,
            "inventory": inventoryDict as AnyObject
        ]
        
        if let store = list.store {
            dict["store"] = store as AnyObject?
        }
        
        dict["lastUpdate"] = NSNumber(value: Int64(list.lastServerUpdate) as Int64)
        
        return dict
    }
    
    func toRequestParams(_ sharedUser: DBSharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email as AnyObject,
            "foo": "" as AnyObject // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }

    func toRequestParams(_ listItems: [ListItem]) -> [[String: AnyObject]] {
        return listItems.map{toRequestParams($0)}
    }

    func toRequestParams(_ section: Section) -> [String: AnyObject] {
        
        let listDict = toRequestParams(section.list)

        var dict: [String: AnyObject] = [
            "uuid": section.uuid as AnyObject,
            "name": section.name as AnyObject,
            "color": section.color.hexStr as AnyObject,
            "todoOrder": section.todoOrder as AnyObject,
            "doneOrder": section.doneOrder as AnyObject,
            "stashOrder": section.stashOrder as AnyObject,
            "listInput": listDict as AnyObject
        ]
        
        if let lastServerUpdate = section.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        }

        return dict
    }
    
    func toRequestParams(_ listItem: ListItem) -> [String: AnyObject] {
        // Commented to improve compile time - we don't need this provider now
//        var dict: [String: AnyObject] = [
//            "uuid": listItem.uuid as AnyObject,
//            "note": listItem.note as AnyObject? ?? "" as AnyObject,
//            "todoQuantity": listItem.todoQuantity as AnyObject,
//            "todoOrder": listItem.todoOrder as AnyObject,
//            "doneQuantity": listItem.doneQuantity as AnyObject,
//            "doneOrder": listItem.doneOrder as AnyObject,
//            "stashQuantity": listItem.stashQuantity as AnyObject,
//            "stashOrder": listItem.stashOrder as AnyObject,
//            "storeProductInput": toRequestParams(listItem.product) as AnyObject,
//            "listUuid": listItem.list.uuid as AnyObject,
//            "listName": listItem.list.name as AnyObject,
//            "sectionInput": toRequestParams(listItem.section) as AnyObject,
//        ]
//        
//        if let lastServerUpdate = listItem.lastServerUpdate {
//            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
//        }
//        
//        return dict
        
        
        return [:]

    }

    func toRequestParamsForStatusUpdate(_ listItem: ListItem, statusUpdate: ListItemStatusUpdate) -> [String: AnyObject] {
        return [
            "uuid": listItem.uuid as AnyObject,
            "src": statusUpdate.src.rawValue as AnyObject,
            "dst": statusUpdate.dst.rawValue as AnyObject,
            "l": listItem.list.uuid as AnyObject,
            "s": listItem.section.uuid as AnyObject
        ]
    }

    func toRequestParams(_ product: StoreProduct) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": product.uuid as AnyObject,
            "price": product.price as AnyObject,
            "baseQuantity": product.baseQuantity as AnyObject,
            "unit": product.unit.rawValue as AnyObject,
            "store": product.store as AnyObject,            
            "product": toRequestParams(product.product) as AnyObject
        ]
        
        if let lastServerUpdate = product.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        }
        
        return dict
    }
    
    func toRequestParams(_ product: Product) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": product.uuid as AnyObject,
            "name": product.name as AnyObject,
            "brand": product.brand as AnyObject,
            "category": toRequestParams(product.category) as AnyObject,
            "fav": product.fav as AnyObject
        ]
        
        dict["lastUpdate"] = NSNumber(value: Int64(product.lastServerUpdate) as Int64)
        
        return dict
    }
    
    func toRequestParams(_ productCategory: ProductCategory) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": productCategory.uuid as AnyObject,
            "name": productCategory.name as AnyObject,
            "color": productCategory.color.hexStr as AnyObject
        ]
        
        
        dict["lastUpdate"] = NSNumber(value: Int64(productCategory.lastServerUpdate) as Int64)
        
        return dict
    }
    
    func toRequestParamsShort(_ list: List) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": list.uuid as AnyObject,
            "name": list.name as AnyObject,
            "order": list.order as AnyObject,
            "color": list.color.hexStr as AnyObject
        ]

        if let store = list.store {
            dict["store"] = store as AnyObject?
        }
        dict["lastUpdate"] = NSNumber(value: Int64(list.lastServerUpdate) as Int64)
        
        return dict
    }
    
    func toRequestParams(_ list: List) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = list.users.map{self.toRequestParams($0)}
        var listDict = self.toRequestParamsShort(list)
        listDict["users"] = sharedUsers as AnyObject?
        let inventoryDict = RemoteInventoryProvider().toRequestParams(list.inventory)
        listDict["inventory"] = inventoryDict as AnyObject
        return listDict
    }
    
    func toRequestParamsToRemove(_ listItem: ListItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": listItem.uuid as AnyObject]
        if let lastServerUpdate = listItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        }
        return dict
    }

    func toRequestParamsToRemove(_ list: List) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": list.uuid as AnyObject]
        dict["lastUpdate"] = NSNumber(value: Int64(list.lastServerUpdate) as Int64)
        return dict
    }
    
    func toRequestParams(_ listUuid: String, items: [InventoryItemWithHistoryItem]) -> [String: AnyObject] {
        
        let remoteInventoryItemsProvider = RemoteInventoryItemsProvider()
        var dict: [String: AnyObject] = ["listUuid": listUuid as AnyObject]
        let itemsDicts = items.map{remoteInventoryItemsProvider.toDictionary($0)}
        
        dict["items"] = itemsDicts as AnyObject
        
        return dict
    }
}




