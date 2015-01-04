//
//  InventoryItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryItemMapper {
    
    class func inventoryItemWithCD(cdInventoryItem:CDInventoryItem) -> InventoryItem {
        let product = ProductMapper.productWithCD(cdInventoryItem.product)
        return InventoryItem(product: product, quantity: cdInventoryItem.quantity.integerValue)
    }
}
