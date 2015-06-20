//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol InventoryProvider {
   
    func inventory(handler: Try<[InventoryItem]> -> ())
    
    func addToInventory(items:[InventoryItem])
    
    func updateInventoryItem(item:InventoryItem)

}
