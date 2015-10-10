//
//  PlanItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PlanItemMapper {

    class func dbWith(planItem: PlanItem) -> DBPlanItem {
        let dbPlanItem = DBPlanItem()
        dbPlanItem.inventory = InventoryMapper.dbWithInventory(planItem.inventory)
        dbPlanItem.product  = ProductMapper.dbWithProduct(planItem.product)
        dbPlanItem.quantity = planItem.quantity
        dbPlanItem.lastUpdate = planItem.lastUpdate
        dbPlanItem.lastServerUpdate = planItem.lastUpdate
        return dbPlanItem
    }
    
    class func planItemWith(dbPlanItem: DBPlanItem, usedQuantity: Int) -> PlanItem {
        return PlanItem(
            inventory: InventoryMapper.inventoryWithDB(dbPlanItem.inventory),
            product: ProductMapper.productWithDB(dbPlanItem.product),
            quantity: dbPlanItem.quantity,
            usedQuantity: usedQuantity,
            lastUpdate: dbPlanItem.lastUpdate,
            lastServerUpdate: dbPlanItem.lastServerUpdate
        )
    }
}
