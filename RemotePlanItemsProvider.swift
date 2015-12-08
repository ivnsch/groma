//
//  RemotePlanItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemotePlanItemsProvider {
    
    func planItems(inventory: Inventory? = nil, handler: RemoteResult<RemoteHistoryItems> -> ()) {
        let params: [String: AnyObject] = inventory.map{["inventory": $0.uuid]} ?? [String: AnyObject]()
        RemoteProvider.authenticatedRequest(.GET, Urls.planItems, params) {result in
            handler(result)
        }
    }

    func addPlanItem(planItem: PlanItem, handler: RemoteResult<NoOpSerializable> -> Void) {
        addUpdatePlanItem(planItem, handler: handler)
    }
    
    func updatePlanItem(planItem: PlanItem, handler: RemoteResult<NoOpSerializable> -> Void) {
        addUpdatePlanItem(planItem, handler: handler)
    }

    func addUpdatePlanItem(planItem: PlanItem, handler: RemoteResult<NoOpSerializable> -> Void) {
        let params = toRequestParams(planItem)
        RemoteProvider.authenticatedRequest(.PUT, Urls.planItem, params) {result in
            handler(result)
        }
    }
    
    func removePlanItem(planItem: PlanItem, handler: RemoteResult<NoOpSerializable> -> Void) {
        let params = toRequestParams(planItem)
        RemoteProvider.authenticatedRequest(.DELETE, Urls.planItem, params) {result in
            handler(result)
        }
    }
    
    func toRequestParams(planItems: [PlanItem]) -> [[String: AnyObject]] {
        return planItems.map{toRequestParams($0)}
    }
    
    func toRequestParams(planItem: PlanItem) -> [String: AnyObject] {
        let inventory = RemoteInventoryProvider().toRequestParams(planItem.inventory)
        
        var dict: [String: AnyObject] = [
            "inventory": inventory,
            "quantity": planItem.quantity,
            "productInput": [
                "uuid": planItem.product.uuid,
                "name": planItem.product.name,
                "price": planItem.product.price,
                "baseQuantity": planItem.product.baseQuantity,
                "unit": planItem.product.unit.rawValue,
                "category": RemoteListItemProvider().toRequestParams(planItem.product.category)
            ]
        ]
        if let lastServerUpdate = planItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(double: lastServerUpdate.timeIntervalSince1970).longValue
        }
        return dict
    }
}
