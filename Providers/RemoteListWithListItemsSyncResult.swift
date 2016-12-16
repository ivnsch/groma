//
//  RemoteListWithListItemsSyncResult.swift
//  shoppin
//
//  Created by ischuetz on 07/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListItemsSyncResult: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    let listUuid: String
    let listItems: RemoteListItems
    let couldNotUpdate: [String]
    let couldNotDelete: [String]
    
    
    init?(representation: AnyObject) {
        guard
            let listUuid = representation.value(forKeyPath: "listUuid") as? String,
            let listItemsObj = representation.value(forKeyPath: "listItems"),
            let listItems = RemoteListItems(representation: listItemsObj as AnyObject),
            let couldNotUpdate = representation.value(forKeyPath: "couldNotUpdate") as? [String],
            let couldNotDelete = representation.value(forKeyPath: "couldNotDelete") as? [String]
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.listUuid = listUuid
        self.listItems = listItems
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    static func collection(_ representation: [AnyObject]) -> [RemoteListItemsSyncResult]? {
        var listItemsSyncResult = [RemoteListItemsSyncResult]()
        for obj in representation {
            if let listItem = RemoteListItemsSyncResult(representation: obj) {
                listItemsSyncResult.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) listUuid: \(listUuid), listItems: \(listItems), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete)}"
    }
}


struct RemoteListWithListItemsSyncResult: ResponseObjectSerializable, CustomDebugStringConvertible {
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
    
    init?(representation: AnyObject) {
        guard
            let listsObj = representation.value(forKeyPath: "lists"), // TODO!!! server
            let lists = RemoteListsWithDependencies(representation: listsObj as AnyObject),
            let couldNotUpdate = representation.value(forKeyPath: "couldNotUpdate") as? [String],
            let couldNotDelete = representation.value(forKeyPath: "couldNotDelete") as? [String],
            let listItemsSyncResultsObj = representation.value(forKeyPath: "listItems") as? [AnyObject],
            let listItemsSyncResults = RemoteListItemsSyncResult.collection(listItemsSyncResultsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.lists = lists
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
        self.listItemsSyncResults = listItemsSyncResults
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) lists: \(lists), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete), listItemsSyncResults: \(listItemsSyncResults)}"
    }
}
