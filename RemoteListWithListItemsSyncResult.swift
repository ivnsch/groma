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
    
    
    init?(representation: AnyObject) {
        self.listUuid = representation.valueForKeyPath("listUuid") as! String
        
        let listItems = representation.valueForKeyPath("listItems")!
        self.listItems = RemoteListItems(representation: listItems)!
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
    }
    
    static func collection(representation: AnyObject) -> [RemoteListItemsSyncResult] {
        var listItemsSyncResult = [RemoteListItemsSyncResult]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItemsSyncResult(representation: obj) {
                listItemsSyncResult.append(listItem)
            }
            
        }
        return listItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) listUuid: \(listUuid), listItems: \(listItems), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete)}"
    }
}


final class RemoteListWithListItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
    let lists: RemoteListsWithDependencies
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    let listItemsSyncResults: [RemoteListItemsSyncResult]
    
    init(lists: RemoteListsWithDependencies, couldNotUpdate: [String], couldNotDelete: [String], listItemsSyncResults: [RemoteListItemsSyncResult]) {
        self.lists = lists
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
        self.listItemsSyncResults = listItemsSyncResults
    }
    
    @objc required init?(representation: AnyObject) {
        let lists = representation.valueForKeyPath("lists")! // TODO!!! server
        self.lists = RemoteListsWithDependencies(representation: lists)!
        
        self.couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as! [String]
        self.couldNotDelete = representation.valueForKeyPath("couldNotDelete") as! [String]
        
        let listItemsSyncResults = representation.valueForKeyPath("listItems") as! [AnyObject]
        self.listItemsSyncResults = RemoteListItemsSyncResult.collection(listItemsSyncResults)
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) lists: \(lists), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete), listItemsSyncResults: \(listItemsSyncResults)}"
    }
}