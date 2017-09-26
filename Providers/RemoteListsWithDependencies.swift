//
//  RemoteListsWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 07/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteListsWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {

    let inventories: [RemoteInventoryWithDependencies]
    let lists: [RemoteList]
    
    init?(representation: AnyObject) {
        guard
        let inventoriesObj = representation.value(forKeyPath: "inventories") as? [AnyObject],
        let inventories = RemoteInventoryWithDependencies.collection(inventoriesObj),
        let listsObj = representation.value(forKeyPath: "lists") as? [AnyObject],
        let lists = RemoteList.collection(listsObj)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.inventories = inventories
        self.lists = lists
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventories: \(inventories), lists: \(lists)}"
    }
}
