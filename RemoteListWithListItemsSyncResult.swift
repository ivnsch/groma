//
//  RemoteListWithListItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 07/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation


final class RemoteListItemsSyncResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let listUuid: String
    let listItems: RemoteListItems
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.listUuid = representation.valueForKeyPath("listUuid") as! String
        
        let listItems = representation.valueForKeyPath("listItems")!
        self.listItems = RemoteListItems(response: response, representation: listItems)!
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
    }
    
    @objc static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteListItemsSyncResult] {
        var listItemsSyncResult = [RemoteListItemsSyncResult]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItemsSyncResult(response: response, representation: obj) {
                listItemsSyncResult.append(listItem)
            }
            
        }
        return listItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) listUuid: \(self.listUuid), listItems: \(self.listItems), couldNotUpdate: \(self.couldNotUpdate), couldNotDelete: \(self.couldNotDelete)}"
    }
}


final class RemoteListWithListItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let lists: [RemoteList]
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    let listItemsSyncResults: [RemoteListItemsSyncResult]
    
    init(lists: [RemoteList], couldNotUpdate: [String], couldNotDelete: [String], listItemsSyncResults: [RemoteListItemsSyncResult]) {
        self.lists = lists
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
        self.listItemsSyncResults = listItemsSyncResults
    }
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let lists = representation.valueForKeyPath("lists") as! [AnyObject]
        self.lists = RemoteList.collection(response: response, representation: lists)
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
        
        let listItemsSyncResults = representation.valueForKeyPath("listItems") as! [AnyObject]
        self.listItemsSyncResults = RemoteListItemsSyncResult.collection(response: response, representation: listItemsSyncResults)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) lists: \(self.lists), couldNotUpdate: \(self.couldNotUpdate), couldNotDelete: \(self.couldNotDelete), listItemsSyncResults: \(self.listItemsSyncResults)}"
    }
}