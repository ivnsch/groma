//
//  RemoteListWithListItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteListWithListItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let list: RemoteList
    let listItems: RemoteListItemsWithDependenciesNoList
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let list = representation.valueForKeyPath("list")!
        self.list = RemoteList(response: response, representation: list)!
        
        let listItems = representation.valueForKeyPath("listItems") as! [AnyObject]
        self.listItems = RemoteListItemsWithDependenciesNoList(response: response, representation: listItems)!
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteListWithListItems] {
        var listItems = [RemoteListWithListItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListWithListItems(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) list: \(list), listItems: [\(listItems)]}"
    }
}
