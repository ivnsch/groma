//
//  RemoteListWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 17/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteListWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let inventory: RemoteInventoryWithDependencies
    let list: RemoteList
    
    init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.valueForKeyPath("inventory"),
            let inventory = RemoteInventoryWithDependencies(representation: inventoryObj),
            let listObj = representation.valueForKeyPath("list"),
            let list = RemoteList(representation: listObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.list = list
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventories: \(inventory), lists: \(list)}"
    }
}