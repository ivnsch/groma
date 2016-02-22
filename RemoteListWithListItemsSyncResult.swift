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
            let listUuid = representation.valueForKeyPath("listUuid") as? String,
            let listItemsObj = representation.valueForKeyPath("listItems"),
            let listItems = RemoteListItems(representation: listItemsObj),
            let couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as? [String],
            let couldNotDelete = representation.valueForKeyPath("couldNotDelete") as? [String]
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.listUuid = listUuid
        self.listItems = listItems
        self.couldNotUpdate = couldNotUpdate
        self.couldNotDelete = couldNotDelete
    }
    
    static func collection(representation: AnyObject) -> [RemoteListItemsSyncResult]? {
        var listItemsSyncResult = [RemoteListItemsSyncResult]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteListItemsSyncResult(representation: obj) {
                listItemsSyncResult.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItemsSyncResult
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) listUuid: \(listUuid), listItems: \(listItems), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete)}"
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
            let listsObj = representation.valueForKeyPath("lists"), // TODO!!! server
            let lists = RemoteListsWithDependencies(representation: listsObj),
            let couldNotUpdate = representation.valueForKeyPath("couldNotUpdate") as? [String],
            let couldNotDelete = representation.valueForKeyPath("couldNotDelete") as? [String],
            let listItemsSyncResultsObj = representation.valueForKeyPath("listItems") as? [AnyObject],
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
        return "{\(self.dynamicType) lists: \(lists), couldNotUpdate: \(couldNotUpdate), couldNotDelete: \(couldNotDelete), listItemsSyncResults: \(listItemsSyncResults)}"
    }
}