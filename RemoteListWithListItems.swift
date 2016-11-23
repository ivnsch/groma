//
//  RemoteListWithListItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListWithListItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let list: RemoteList
    let listItems: RemoteListItemsWithDependenciesNoList
    
    init?(representation: AnyObject) {
        guard
            let listObj = representation.value(forKeyPath: "list") as? [AnyObject],
            let list = RemoteList(representation: listObj as AnyObject),
            let listItemsObjs = representation.value(forKeyPath: "listItems") as? [AnyObject],
            let listItems = RemoteListItemsWithDependenciesNoList(representation: listItemsObjs as AnyObject)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.list = list
        self.listItems = listItems
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteListWithListItems]? {
        var listItems = [RemoteListWithListItems]()
        for obj in representation {
            if let listItem = RemoteListWithListItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) list: \(list), listItems: [\(listItems)]}"
    }
}
