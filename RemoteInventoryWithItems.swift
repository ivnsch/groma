//
//  RemoteInventoryWithItems.swift
//  shoppin
//
//  Created by ischuetz on 28/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

final class RemoteInventoryWithItems: ResponseObjectSerializable, ResponseCollectionSerializable, CustomDebugStringConvertible {
    
    let inventory: RemoteInventory
    let inventoryItems: RemoteInventoryItemsWithDependenciesNoInventory
    
    @objc required init?(representation: AnyObject) {
        
        let inventory = representation.valueForKeyPath("inventory")!
        self.inventory = RemoteInventory(representation: inventory)!
        
        let items = representation.valueForKeyPath("items") as! [AnyObject]
        self.inventoryItems = RemoteInventoryItemsWithDependenciesNoInventory(representation: items)!
    }
    
    static func collection(representation: AnyObject) -> [RemoteInventoryWithItems] {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteInventoryWithItems(representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventory: \(inventory), inventoryItems: [\(inventoryItems)]}"
    }
}
