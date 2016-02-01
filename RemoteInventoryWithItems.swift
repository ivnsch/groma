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
    
    @objc required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        
        let inventory = representation.valueForKeyPath("inventory")!
        self.inventory = RemoteInventory(response: response, representation: inventory)!
        
        let items = representation.valueForKeyPath("items") as! [AnyObject]
        self.inventoryItems = RemoteInventoryItemsWithDependenciesNoInventory(response: response, representation: items)!
    }
    
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [RemoteInventoryWithItems] {
        var listItems = [RemoteInventoryWithItems]()
        for obj in representation as! [AnyObject] {
            if let listItem = RemoteInventoryWithItems(response: response, representation: obj) {
                listItems.append(listItem)
            }
            
        }
        return listItems
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) inventory: \(inventory), inventoryItems: [\(inventoryItems)]}"
    }
}
