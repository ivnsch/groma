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

    let inventories: [RemoteInventory]
    let lists: [RemoteList]
    
    // TODO After porting to Swift 2.0 catch exception in these initializers and show msg to client accordingly, or don't use force unwrap
    // if server for some reason doesn't send a field the app currently crashes
    init?(representation: AnyObject) {
        guard
        let inventoriesObj = representation.valueForKeyPath("inventories"),
        let inventories = RemoteInventory.collection(inventoriesObj),
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