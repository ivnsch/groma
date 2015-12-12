//
//  WSPlanItemParser.swift
//  shoppin
//
//  Created by ischuetz on 09/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct WSPlanItemParser {

    static func parsePlanItem(json: AnyObject) -> PlanItem {
        let quantity = json.valueForKeyPath("quantity") as! Int
        
        let productObj = json.valueForKeyPath("productInput")!
        let product = ListItemParser.parseProduct(productObj)

        let inventoryObj = json.valueForKeyPath("inventoryInput")!
        let inventory = WSInventoryParser.parseInventory(inventoryObj)
        
        let usedQuantity = 0 // TODO review - used quantity is computed using history, so this value is not used
        
        return PlanItem(inventory: inventory, product: product, quantity: quantity, usedQuantity: usedQuantity)
    }
}