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

    func allListItems(handler: Try<RemoteListItems> -> ()) {
        Alamofire.request(.GET, Urls.listItems).responseObject { (request, _, listItems: RemoteListItems?, error) in
            if let listItems = listItems {
                println("received listItems: \(listItems)")
                handler(Try(listItems))
            } else {
                println("Response error: \(error), request: \(request)")
            }
        }
    }
    
//    func listItems(list: List, handler: Try<RemoteListItems> -> ()) {
//        Alamofire.request(.GET, Urls.listItems).responseObject { (request, _, listItems: RemoteListItems?, error) in
//            if let listItems = listItems {
//                println("received listItems: \(listItems)")
//                handler(Try(listItems))
//            } else {
//                println("Response error: \(error), request: \(request)")
//            }
//        }
//    }
    
    
    func remove(listItem: ListItem, handler: Try<Bool> -> ()) {
        
    }
    
    func remove(section: Section, handler: Try<Bool> -> ()) {
        
    }
    
    func remove(list: List, handler: Try<Bool> -> ()) {
        
        
    }
    
    func add(listItem: ListItem, handler: Try<RemoteListItemWithData> -> ()) {
        
        let parameters = [
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
        
    }
    
    func update(listItems: [ListItem], handler: Try<Bool> -> ()) {
        
    }
    
    func add(list: List, handler: Try<List> -> ()) {
        
    }

    func list(listId: String, handler: Try<List> -> ()) {
        
    }
    
    func updateDone(listItems:[ListItem], handler: Try<Bool> -> ()) {
        
    }
    
    func firstList(handler: Try<List> -> ()) {
        
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
