//
//  RemoteListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import Alamofire

class RemoteListItemProvider {
    
    func products(handler: RemoteResult<[RemoteProduct]> -> ()) {
        Alamofire.request(.GET, Urls.products).responseMyArray { (request, _, result: RemoteResult<[RemoteProduct]>, error) in
            handler(result)
        }
    }
    
    func sections(handler: RemoteResult<[RemoteSection]> -> ()) {
        Alamofire.request(.GET, Urls.sections).responseMyArray { (request, _, result: RemoteResult<[RemoteSection]>, error) in
            handler(result)
        }
    }

    
    func lists(handler: RemoteResult<[RemoteList]> -> ()) {
        Alamofire.request(.GET, Urls.lists).responseMyArray { (request, _, result: RemoteResult<[RemoteList]>, error) in
            handler(result)
        }
    }

    func listItems(#list: List, handler: RemoteResult<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.listItems, parameters: ["list": list.uuid]).responseMyObject { (request, _, result: RemoteResult<RemoteListItems>, error) in
            handler(result)
        }
    }
    
    func listItems(handler: RemoteResult<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.allListItems).responseMyObject { (request, _, result: RemoteResult<RemoteListItems>, error) in
            handler(result)
        }
    }
    
    func remove(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        Alamofire.request(.DELETE, Urls.listItem + "/\(listItem.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func remove(section: Section, handler: RemoteResult<NoOpSerializable> -> ()) {
        Alamofire.request(.DELETE, Urls.section + "/\(section.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func remove(list: List, handler: RemoteResult<NoOpSerializable> -> ()) {
        Alamofire.request(.DELETE, Urls.list + "/\(list.uuid)").responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func update(list: List, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(list)
        Alamofire.request(.PUT, Urls.list, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func add(listItem: ListItem, handler: RemoteResult<RemoteListItemWithData> -> ()) {
        let parameters = self.toRequestParams(listItem)
        Alamofire.request(.POST, Urls.addListItem, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, result: RemoteResult<RemoteListItemWithData>, error) in
            handler(result)
        }
    }
    
    func update(listItem: ListItem, handler: RemoteResult<NoOpSerializable> -> ()) {
        let parameters = self.toRequestParams(listItem)
        Alamofire.request(.PUT, Urls.listItem, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func update(listItems: [ListItem], handler: RemoteResult<NoOpSerializable> -> ()) {
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.listItems)!)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let values = listItems.map{self.toRequestParams($0)}
        
        var error: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(values, options: nil, error: &error)
        
        Alamofire.request(request).responseMyObject {(request, _, result: RemoteResult<NoOpSerializable>, error) in
            handler(result)
        }
    }
    
    func add(list: List, handler: RemoteResult<RemoteList> -> ()) {
        let parameters = [
            "uuid": list.uuid,
            "name": list.name
        ]
        
        Alamofire.request(.POST, Urls.list, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, result: RemoteResult<RemoteList>, error) in
            handler(result)
        }
    }

    func add(section: Section, handler: RemoteResult<RemoteSection> -> ()) {
        let parameters = [
            "uuid": section.uuid,
            "name": section.name
        ]
        
        Alamofire.request(.POST, Urls.section, parameters: parameters, encoding: .JSON).responseMyObject { (request, _, result: RemoteResult<RemoteSection>, error) in
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
            "listInput": [
                "uuid": listItem.list.uuid,
                "name": listItem.list.name
            ],
            "sectionInput": [
                "uuid": listItem.section.uuid,
                "name": listItem.section.name
            ],
            "order": listItem.order
        ]
    }
    
    
    func toRequestParams(list: List) -> [String: AnyObject] {
        return [
            "uuid": list.uuid,
            "name": list.name
        ]
    }
}




