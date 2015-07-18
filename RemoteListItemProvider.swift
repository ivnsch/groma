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
        Alamofire.request(.GET, Urls.products).responseMyArray { (request, _, result: RemoteResult<[RemoteProduct]>, error) in
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
        AlamofireHelper.authenticatedRequest(.GET, Urls.productWithUnique, params).responseMyObject {(request, _, result: RemoteResult<RemoteProduct>, error) in
            handler(result)
        }
    }

    func section(name: String, list: List, handler: RemoteResult<RemoteSection> -> ()) {
        let params = [
            "name": name,
            "listUuid": list.uuid,
        ]
        AlamofireHelper.authenticatedRequest(.GET, Urls.sectionWithUnique, params).responseMyObject {(request, _, result: RemoteResult<RemoteSection>, error) in
            handler(result)
        }
    }
    
    func sections(handler: RemoteResult<[RemoteSection]> -> ()) {
        Alamofire.request(.GET, Urls.sections).responseMyArray { (request, _, result: RemoteResult<[RemoteSection]>, error) in
            handler(result)
        }
    }

    
    func lists(handler: RemoteResult<[RemoteList]> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.lists).responseMyArray { (request, _, result: RemoteResult<[RemoteList]>, error) in
            handler(result)
        }
    }

    func listItems(#list: List, handler: RemoteResult<RemoteListItems> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.listItems, ["list": list.uuid]).responseMyObject {(request, _, result: RemoteResult<RemoteListItems>, error) in
            handler(result)
        }
    }
    
    func listItems(handler: RemoteResult<RemoteListItems> -> ()) {
        AlamofireHelper.authenticatedRequest(.GET, Urls.allListItems).responseMyObject {(request, _, result: RemoteResult<RemoteListItems>, error) in
            handler(result)
        }
    }
    
    func remove(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.listItem + "/\(listItem.uuid)").responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func remove(section: Section, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.section + "/\(section.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func remove(list: List, handler: RemoteResult<NoOpSerializable> -> ()) {
        AlamofireHelper.authenticatedRequest(.DELETE, Urls.list + "/\(list.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func update(list: ListWithSharedUsersInput, handler: RemoteResult<RemoteList> -> ()) {
        let parameters = self.toRequestParams(list)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.list, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteList>, error) in
            handler(result)
        }
    }
    
    func add(listItem: ListItem, handler: RemoteResult<RemoteListItemWithData> -> ()) {
        let parameters = self.toRequestParams(listItem)
        AlamofireHelper.authenticatedRequest(.POST, Urls.addListItem, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteListItemWithData>, error) in
            handler(result)
        }
    }
    
    func update(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(listItem)
        AlamofireHelper.authenticatedRequest(.PUT, Urls.listItem, parameters).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
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
        
        var error: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(values, options: nil, error: &error)
        
        Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func add(list: ListWithSharedUsersInput, handler: RemoteResult<RemoteList> -> ()) {
        let parameters: [String: AnyObject] = [
            "uuid": list.list.uuid,
            "name": list.list.name,
            "users": list.users.map{self.toRequestParams($0)}
        ]
        AlamofireHelper.authenticatedRequest(.POST, Urls.list, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteList>, error) in
            handler(result)
        }
    }

    func add(section: Section, handler: RemoteResult<RemoteSection> -> ()) {
        let parameters = [
            "uuid": section.uuid,
            "name": section.name
        ]
        AlamofireHelper.authenticatedRequest(.POST, Urls.section, parameters).responseMyObject { (request, _, result: RemoteResult<RemoteSection>, error) in
            handler(result)
        }
    }
    
    
    func list(listId: String, handler: RemoteResult<RemoteList> -> ()) {
        Alamofire.request(.GET, Urls.list).responseMyObject { (request, _, result: RemoteResult<RemoteList>, error) in
            handler(result)
        }
    }
    
//    // for unit tests
//    func removeAll(handler: Try<Bool> -> ()) {
//        Alamofire.request(.GET, Urls.removeAll).responseString { (request, _, string: String?, error) in
//            if let success = string?.boolValue {
//                handler(Try(success))
//            }
//        }
//    }
    
    //////////////////
    
    func toRequestParams(sharedUser: SharedUser) -> [String: AnyObject] {
        return [
            "uuid": sharedUser.uuid,
            "email": sharedUser.email,
            "firstName": sharedUser.firstName,
            "lastName": sharedUser.lastName
        ]
    }
    
    func toRequestParams(listItem: ListItem) -> [String: AnyObject] {
        return [
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
    }
    
    func toRequestParams(sharedUserInput: SharedUserInput) -> [String: AnyObject] {
        return [
            "email": sharedUserInput.email,
            "foo": "" // FIXME this is a workaround for serverside, for some reason case class & serialization didn't work with only one field
        ]
    }
    
    
    func toRequestParams(listWithSharedUsersInput: ListWithSharedUsersInput) -> [String: AnyObject] {
        let sharedUsers: [[String: AnyObject]] = listWithSharedUsersInput.users.map{self.toRequestParams($0)}
        
        var listDict = self.toRequestParams(listWithSharedUsersInput.list)
        
        listDict["users"] = sharedUsers
        
        return listDict
    }
    
    func toRequestParams(list: List) -> [String: AnyObject] {
        return [
            "uuid": list.uuid,
            "name": list.name
        ]
    }
}




