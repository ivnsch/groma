//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol InventoryProvider {
   
    func inventory() -> [InventoryItem]
    
    func addToInventory(items:[InventoryItem])
    
    func updateInventoryItem(item:InventoryItem)

}
