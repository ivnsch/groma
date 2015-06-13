//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

class InventoryProviderImpl: InventoryProvider {
   
    let cdProvider = CDInventoryProvider()

    func inventory(handler: Try<[InventoryItem]> -> ()) {
        
        self.cdProvider.loadInventory{try in
            if let cdItems = try.success {
                let items = cdItems.map{InventoryItemMapper.inventoryItemWithCD($0)}
                handler(Try(items))
            }
        }
    }
    
    func addToInventory(items: [InventoryItem]) {
        self.cdProvider.addToInventory(items, handler: {try in
        })
    }
 
    func updateInventoryItem(item:InventoryItem) {
        self.cdProvider.updateInventoryItem(item, handler: {try in
        })
    }
}
