//
//  RemoteListsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 07/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {

    let inventories: [RemoteInventoryWithDependencies]
    let lists: [RemoteList]
    
    init?(representation: AnyObject) {
        guard
        let inventoriesObj = representation.valueForKeyPath("inventories"),
        let inventories = RemoteInventoryWithDependencies.collection(inventoriesObj),
        let listsObj = representation.valueForKeyPath("lists"),
        let lists = RemoteList.collection(listsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventories = inventories
        self.lists = lists
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventories: \(inventories), lists: \(lists)}"
    }
}