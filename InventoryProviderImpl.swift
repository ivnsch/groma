//
//  InventoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryProviderImpl: InventoryProvider {
   
    let cdProvider = CDInventoryProvider()

    func inventory() -> [InventoryItem] {
        return self.cdProvider.loadInventory().map{InventoryItemMapper.inventoryItemWithCD($0)}
    }
    
    func addToInventory(items:[InventoryItem]) {
        self.cdProvider.addToInventory(items)
    }
    
}
