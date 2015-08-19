//
//  RemoteListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire
import Valet

class RemoteListItemProvider {
    
    func products(handler: RemoteResult<[RemoteProduct]> -> ()) {
        Alamofire.request(.GET, Urls.products).responseMyArray { (request, _, result: RemoteResult<[RemoteProduct]>) in
            handler(result)
        }
    }

    // get product for name + list (unique)
    // this is necessary to find the uuid of a possibly already existing product, which may not be stored in the local database
    // (e.g. user uses 2 devices, device 2 doesn't have the recently added products in device 1 in it's local database, so it has to request the server)
    // Note that this overall needs more development, since device 2 can add products offline and we can get conflicts (same name, diff uuids) with the server
    func product(name: String, list: List, handler: RemoteResult<RemoteProduct> -> ()) {
        let params = [
            "name": name,
            "listUuid": list.uuid,
        ]
        AlamofireHelper.authenticatedRequest(.GET, Urls.productWithUnique, params).responseMyObject {(request, _, result: RemoteResult<RemoteProduct>) in
            handler(result)
        }
    }

    func section(name: String, list: List, handler: RemoteResult<RemoteSection> -> ()) {
        let params = [
            "name": name,
            "listUuid": list.uuid,
        ]
        AlamofireHelper.authenticatedRequest(.GET, Urls.sectionWithUnique, params).responseMyObject {(request, _, result: RemoteResult<RemoteSection>) in
            handler(result)
        }
    }
    
    func sections(handler: RemoteResult<[RemoteSection]> -> ()) {
        Alamofire.request(.GET, Urls.sections).responseMyArray { (request, _, result: RemoteResult<[RemoteSection]>) in
            handler(result)
        }
    }

    
    func lists(handler: RemoteResult<[RemoteList]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.lists).responseMyArray { (request, _, result: RemoteResult<[RemoteList]>) in
            handler(result)
        }
    }

    func listItems(list list: List, handler: RemoteResult<RemoteListItems> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.listItems, ["list": list.uuid]).responseMyObject {(request, _, result: RemoteResult<RemoteListItems>) in
            handler(result)
        }
    }
    
    func remove(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.listItem + "/\(listItem.uuid)").responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func remove(section: Section, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.section + "/\(section.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func remove(list: List, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.list + "/\(list.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func update(list: List, handler: RemoteResult<RemoteList> -> ()) {
        let parameters = self.toRequestParams(list)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.list, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteList>) in
            handler(result)
        }
    }
    
    func add(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(listItem)
        AlamofireHelper.authenticatedRequest(.POST, Urls.addListItem, parameters).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func update(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(listItem)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.listItem, parameters).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>) in
            handler(result)
        }
    }
    
    func update(listItems: [ListItem], handler: RemoteResult<NoOpSerializable> -> ()) {
        // this is handled differently because the parameters are an array and default request in alamofire doesn't support this (the difference is the request.HTTPBody line)
        
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.listItems)!)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let valet = VALValet(identifier: KeychainKeys.ValetIdentifier, accessibility: VALAccessibility.AfterFirstUnlock)

        let maybeToken = valet?.stringForKey(KeychainKeys.token)
        
        if let token = maybeToken {
            request.setValue(token, forHTTPHeaderField: "X-Auth-Token")
        } // TODO if there's no token return status code to direct to login controller or something
        
        let values = listItems.map{self.toRequestParams($0)}
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(values, options: [])
            
            Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>) in
                handler(result)
            }
            
        } catch _ as NSError {
            handler(RemoteResult(status: .ClientParamsParsingError))
        }
    }
    
    func add(list: List, handler: RemoteResult<RemoteList> -> ()) {
        let parameters: [String: AnyObject] = [
            "uuid": list.uuid,
            "name": list.name,
            "users": list.users.map{self.toRequestParams($0)}
        ]
        AlamofireHelper.authenticatedRequest(.POST, Urls.list, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteList>) in
            handler(result)
        }
    }

    func add(section: Section, handler: RemoteResult<RemoteSection> -> ()) {
        let parameters = [
            "uuid": section.uuid,
            "name": section.name
        ]
        AlamofireHelper.authenticatedRequest(.POST, Urls.section, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteSection>) in
            handler(result)
        }
    }
    
    
    func list(listId: String, handler: RemoteResult<RemoteList> -> ()) {
        Alamofire.request(.GET, Urls.list).responseMyObject { (request, _, result: RemoteResult<RemoteList>) in
            handler(result)
        }
    }
    
    func syncListItems(list: List, listItems: [ListItem], toRemove: [ListItem], handler: RemoteResult<RemoteSyncResult<RemoteListItems>> -> ()) {
        
        let listItemsParams = listItems.map{self.toRequestParams($0)}
        let toRemoveParams = toRemove.map{self.toRequestParamsToRemove($0)}
        
        let dictionary: [String: AnyObject] = [
            "list": self.toRequestParamsShort(list),
            "listItems": listItemsParams,
            "toRemove": toRemoveParams
        ]
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.listItemsSync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteSyncResult<RemoteListItems>>) in
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
                "users": sharedUsers,
            ]
            
            if let lastServerUpdate = list.lastServerUpdate {
                dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
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
        
        print("sending: \(dictionary)")
        
        AlamofireHelper.authenticatedRequest(.POST, Urls.listsWithItemsSync, dictionary).responseMyObject { (request, _, result: RemoteResult<RemoteListWithListItemsSyncResult>) in
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
    
    func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "email": sharedUser.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
    
    func toRequestParams(listItem: ListItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [
            "uuid": listItem.uuid,
            "done": listItem.done,
            "quantity": listItem.quantity,
            "productInput": [
                "uuid": listItem.product.uuid,
                "name": listItem.product.name,
                "price": listItem.product.price,
            ],
            "listUuid": listItem.list.uuid,
            "listName": listItem.list.name,
            "sectionInput": [
                "uuid": listItem.section.uuid,
                "name": listItem.section.name
            ],
            "order": listItem.order
        ]
        
        if let lastServerUpdate = listItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        
        return dict
    }
    
    func toRequestParamsShort(list: List) -> [String: AnyObject] {
        return [
            "uuid": list.uuid,
            "name": list.name
        ]
    }
    
    func toRequestParams(list: List) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = list.users.map{self.toRequestParams($0)}
        
        var listDict = self.toRequestParamsShort(list)
        
        listDict["users"] = sharedUsers
        
        return listDict
    }
    
    func toRequestParamsToRemove(listItem: ListItem) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": listItem.uuid]
        if let lastServerUpdate = listItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }

    func toRequestParamsToRemove(list: List) -> [String: AnyObject] {
        var dict: [String: AnyObject] = ["uuid": list.uuid]
        if let lastServerUpdate = list.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }
}




