//
//  RemoteListWithDependencies.swift
//  shoppin
//
//  Created by ischuetz on 17/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation


struct RemoteListWithDependencies: ResponseObjectSerializable, CustomDebugStringConvertible {
    
    let inventory: RemoteInventoryWithDependencies
    let list: RemoteList
    
    init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.value(forKeyPath: "inventory"),
            let inventory = RemoteInventoryWithDependencies(representation: inventoryObj as AnyObject),
            let listObj = representation.value(forKeyPath: "list"),
            let list = RemoteList(representation: listObj as AnyObject)
            else {
                logger.e("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.list = list
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) inventories: \(inventory), lists: \(list)}"
    }
}
