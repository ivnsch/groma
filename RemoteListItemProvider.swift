//
//  RemoteListItemProvider.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Alamofire


class RemoteListItemProvider {
    
    private struct Urls {
        private static let host: String = "http://localhost:8091/"
        
        static let products = host + "products"
        static let listItems = host + "listItems"
        static let sections = host + "sections"
        static let lists = host + "lists"
        
        static let addListItem = host + "addListItem"
        
        static let listItem = host + "listItem"
        static let section = host + "section"
        static let list = host + "list"
    }
    
    func products(handler: Try<[RemoteProduct]> -> ()) {
        Alamofire.request(.GET, Urls.products).responseCollection { (request, _, products: [RemoteProduct]?, error) in
            if let products = products {
                println("received products: \(products)")
                handler(Try(products))
            } else {
                println("Response error: \(error), request: \(request)")
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
            }
        }
    }

    func listItems(#list: List, handler: Try<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.listItems, parameters: ["list": list.id]).responseObject { (request, _, listItems: RemoteListItems?, error) in
            if let listItems = listItems {
                println("received listItems: \(listItems)")
                handler(Try(listItems))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }
    
    func listItems(handler: Try<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.listItems).responseObject { (request, _, listItems: RemoteListItems?, error) in
            if let listItems = listItems {
                println("received listItems: \(listItems)")
                handler(Try(listItems))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.listItem + "/\(listItem.id)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            }
        }
    }
    
    func remove(section: Section, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.section + "/\(section.id)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
            }
        }
    }
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        Alamofire.request(.DELETE, Urls.section + "/\(list.id)").responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
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
            }
        }
    }
    
    func update(listItem: ListItem, handler: Try<Bool> -> ()) {
        
        let parameters = self.toRequestParams(listItem)
        
        Alamofire.request(.PUT, Urls.listItem + "/\(listItem.id)", parameters: parameters, encoding: .JSON).responseString { (request, _, string, error) in
            if let success = string?.boolValue {
                handler(Try(success))
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
            }
        }
    }
    
    func add(list: List, handler: Try<RemoteList> -> ()) {
        let parameters = [
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
            "name": section.name
        ]
        
        Alamofire.request(.POST, Urls.section, parameters: parameters, encoding: .JSON).responseObject { (request, _, section: RemoteSection?, error) in
            if let section = section {
                println("received listItems: \(section)")
                handler(Try(section))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }
    
    
    func list(listId: String, handler: Try<RemoteList> -> ()) {
        Alamofire.request(.GET, Urls.list).responseObject { (request, _, list: RemoteList?, error) in
            if let list = list {
                handler(Try(list))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }
    
    //////////////////
    
    func toRequestParams(listItem: ListItem) -> [String: AnyObject] {
        return [
            //            "id": listItem.id,
            "done": listItem.done,
            "quantity": listItem.quantity,
            "product": [
                "name": listItem.product.name,
                "price": listItem.product.price,
            ],
            "list": [
                "name": listItem.list.name
            ],
            "section": [
                "name": listItem.section.name
            ],
            "order": listItem.order
        ]
    }
}


//////////////////

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}


//////////////////
//JSON

@objc public protocol ResponseObjectSerializable {
    init?(response: NSHTTPURLResponse, representation: AnyObject)
}

extension Alamofire.Request {
    public func responseObject<T: ResponseObjectSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, T?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            
            println("response: \(response)")
            
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            
            println("JSON: \(JSON)")
            
            if response != nil && JSON != nil {
                return (T(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? T, error)
        })
    }
}


@objc public protocol ResponseCollectionSerializable {
    static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseCollection<T: ResponseCollectionSerializable>(completionHandler: (NSURLRequest, NSHTTPURLResponse?, [T]?, NSError?) -> Void) -> Self {
        let serializer: Serializer = { (request, response, data) in
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let (JSON: AnyObject?, serializationError) = JSONSerializer(request, response, data)
            if response != nil && JSON != nil {
                return (T.collection(response: response!, representation: JSON!), nil)
            } else {
                return (nil, serializationError)
            }
        }
        
        return response(serializer: serializer, completionHandler: { (request, response, object, error) in
            completionHandler(request, response, object as? [T], error)
        })
    }
}
