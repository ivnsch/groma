//
//  RemoteInventoryWithItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

struct RemoteInventoryWithItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let inventory: RemoteInventory
    let inventoryItems: RemoteInventoryItemsWithDependenciesNoInventory
    
    init?(representation: AnyObject) {
        guard
            let inventoryObj = representation.valueForKeyPath("inventory"),
            let inventory = RemoteInventory(representation: inventoryObj),
            let itemsObj = representation.valueForKeyPath("items") as? [AnyObject],
            let inventoryItems = RemoteInventoryItemsWithDependenciesNoInventory(representation: itemsObj)
            else {
                QL4("Invalid json: \(representation)")
                return nil}
        
        self.inventory = inventory
        self.inventoryItems = inventoryItems
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryWithItems]? {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteInventoryWithItems(representation: obj) {
                listItems.append(listItem)
            } else {
                return nil
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventory: \(inventory), inventoryItems: [\(inventoryItems)]}"
    }
}
