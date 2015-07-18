//
//  InventoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol InventoryProvider {
   
    func inventory(handler: ProviderResult<[InventoryItem]> -> ())
    
    func addToInventory(items: [InventoryItem], handler: ProviderResult<Any> -> ())
    
    func updateInventoryItem(item: InventoryItem)

}
