//
//  RemoteListItem.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

final class RemoteListItem: ResponseObjectSerializable, ResponseCollectionSerializable, DebugPrintable {
    
    let id: String
    var done: Bool
    let quantity: Int
    let productId: String
    var sectionId: String
    var listId: String
    var order: Int
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.id = representation.valueForKeyPath("id") as! String
        self.done = representation.valueForKeyPath("done") as! Bool
        self.quantity = representation.valueForKeyPath("quantity") as! Int
        self.productId = representation.valueForKeyPath("productId") as! String
        self.sectionId = representation.valueForKeyPath("sectionId") as! String
        self.listId = representation.valueForKeyPath("listId") as! String
        self.order = representation.valueForKeyPath("order") as! Int
    }
    
    @objc static func collection(#response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteListItem] {
        var listItems = [RemoteListItem]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItem(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) id: \(self.id), done: \(self.done), quantity: \(self.quantity), order: \(self.order), productId: \(self.productId), sectionId: \(self.sectionId), listId: \(self.listId)}"
    }
}
