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

    
    func products(handler: Try<[RemoteProduct]> -> ()) {
        Alamofire.request(.GET, Urls.products).responseCollection { (request, _, products: [RemoteProduct]?, error) in
            if let products = products {
                println("received products: \(products)")
                handler(Try(products))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func sections(handler: Try<[RemoteSection]> -> ()) {
        Alamofire.request(.GET, Urls.sections).responseCollection { (request, _, sections: [RemoteSection]?, error) in
            if let sections = sections {
                println("received sections: \(sections)")
                handler(Try(sections))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }

    
    func lists(handler: Try<[RemoteList]> -> ()) {
        Alamofire.request(.GET, Urls.lists).responseCollection { (request, _, lists: [RemoteList]?, error) in
            if let lists = lists {
                println("received lists: \(lists)")
                handler(Try(lists))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }

    func listItems(#list: List, handler: Try<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.listItems, parameters: ["list": list.uuid]).responseObject { (request, _, listItems: RemoteListItems?, error) in
            if let listItems = listItems {
                println("received listItems: \(listItems)")
                handler(Try(listItems))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func listItems(handler: Try<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.allListItems).responseObject { (request, _, listItems: RemoteListItems?, error) in
            if let listItems = listItems {
                println("received listItems: \(listItems)")
                handler(Try(listItems))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.listItem + "/\(listItem.uuid)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func remove(section: Section, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.section + "/\(section.uuid)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.list + "/\(list.uuid)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func update(list: List, handler: Try<Bool> -> ()) {
        let parameters = self.toRequestParams(list)
        Alamofire.request(.PUT, Urls.list, parameters: parameters, encoding: .JSON).responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func add(listItem: ListItem, handler: Try<RemoteListItemWithData> -> ()) {
        
        let parameters = self.toRequestParams(listItem)
        
        Alamofire.request(.POST, Urls.addListItem, parameters: parameters, encoding: .JSON).responseObject { (request, _, listItem: RemoteListItemWithData?, error) in
            if let listItem = listItem {
                println("received listItems: \(listItem)")
                handler(Try(listItem))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func update(listItem: ListItem, handler: Try<Bool> -> ()) {
        
        let parameters = self.toRequestParams(listItem)
        
        Alamofire.request(.PUT, Urls.listItem, parameters: parameters, encoding: .JSON).responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func update(listItems: [ListItem], handler: Try<Bool> -> ()) {
        let request = NSMutableURLRequest(URL: NSURL(string: Urls.listItems)!)
        request.HTTPMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let values = listItems.map{self.toRequestParams($0)}
        
        var error: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(values, options: nil, error: &error)
        
        Alamofire.request(request).responseString {request, _, string, error in
            if let success = string?.boolValue {
                handler(Try(success))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    func add(list: List, handler: Try<RemoteList> -> ()) {
        let parameters = [
            "uuid": list.uuid,
            "name": list.name
        ]
        
        Alamofire.request(.POST, Urls.list, parameters: parameters, encoding: .JSON).responseObject { (request, _, list: RemoteList?, error) in
            if let list = list {
                println("received listItems: \(list)")
                handler(Try(list))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }

    func add(section: Section, handler: Try<RemoteSection> -> ()) {
        let parameters = [
            "uuid": section.uuid,
            "name": section.name
        ]
        
        Alamofire.request(.POST, Urls.section, parameters: parameters, encoding: .JSON).responseObject { (request, _, section: RemoteSection?, error) in
            if let section = section {
                println("received listItems: \(section)")
                handler(Try(section))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
        }
    }
    
    
    func list(listId: String, handler: Try<RemoteList> -> ()) {
        Alamofire.request(.GET, Urls.list).responseObject { (request, _, list: RemoteList?, error) in
            if let list = list {
                handler(Try(list))
            } else {
                println("Response error: \(error), request: \(request)")
                handler(Try(error ?? NSError()))
            }
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
            "product": [
                "uuid": listItem.product.uuid,
                "name": listItem.product.name,
                "price": listItem.product.price,
            ],
            "list": [
                "uuid": listItem.list.uuid,
                "name": listItem.list.name
            ],
            "section": [
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




