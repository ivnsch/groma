    //
//  RemoteListItems.swift
//  shoppin
//
//  Created by ischuetz on 13/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

final class RemoteListItems: ResponseObjectSerializable, DebugPrintable {

    let products: [RemoteProduct]
    let sections: [RemoteSection]
    let lists: [RemoteList]
    let listItems: [RemoteListItem]
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let products = representation.valueForKeyPath("products") as! [AnyObject]
        self.products = RemoteProduct.collection(response: response, representation: products)

        let sections = representation.valueForKeyPath("sections") as! [AnyObject]
        self.sections = RemoteSection.collection(response: response, representation: sections)
        
        let lists = representation.valueForKeyPath("lists") as! [AnyObject]
        self.lists = RemoteList.collection(response: response, representation: lists)
        
        let listItems = representation.valueForKeyPath("listItems") as! [AnyObject]
        self.listItems = RemoteListItem.collection(response: response, representation: listItems)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) products: [\(self.products)], lists: [\(self.lists)], listItems: [\(self.listItems)}"
    }
}
