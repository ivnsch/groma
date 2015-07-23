//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol InventoryProvider {
    
    func inventories(handler: ProviderResult<[Inventory]> -> ())
    
    func addInventory(inventory: InventoryInput, _ handler: ProviderResult<Any> -> ())
    
    func updateInventory(inventory: InventoryInput, _ handler: ProviderResult<Any> -> ())
}
