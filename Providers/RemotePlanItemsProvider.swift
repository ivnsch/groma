//
//  RemotePlanItemsProvider.swift
//  shoppin
//
//  Created by ischuetz on 02/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class RemotePlanItemsProvider {
    
    func planItems(_ inventory: DBInventory? = nil, handler: @escaping (RemoteResult<RemoteHistoryItems>) -> ()) {
        let params: [String: AnyObject] = inventory.map{["inventory": $0.uuid as AnyObject]} ?? [String: AnyObject]()
        RemoteProvider.authenticatedRequest(.get, Urls.planItems, params) {result in
            handler(result)
        }
    }

    func addPlanItem(_ planItem: PlanItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        addUpdatePlanItem(planItem, handler: handler)
    }
    
    func updatePlanItem(_ planItem: PlanItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        addUpdatePlanItem(planItem, handler: handler)
    }

    func addUpdatePlanItem(_ planItem: PlanItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let params = toRequestParams(planItem)
        RemoteProvider.authenticatedRequest(.put, Urls.planItem, params) {result in
            handler(result)
        }
    }
    
    func removePlanItem(_ planItem: PlanItem, handler: @escaping (RemoteResult<NoOpSerializable>) -> Void) {
        let params = toRequestParams(planItem)
        RemoteProvider.authenticatedRequest(.delete, Urls.planItem, params) {result in
            handler(result)
        }
    }
    
    func toRequestParams(_ planItems: [PlanItem]) -> [[String: AnyObject]] {
        return planItems.map{toRequestParams($0)}
    }
    
    func toRequestParams(_ planItem: PlanItem) -> [String: AnyObject] {
        let inventory = RemoteInventoryProvider().toRequestParams(planItem.inventory)
        
        var dict: [String: AnyObject] = [
            "inventory": inventory as AnyObject,
            "quantity": planItem.quantity as AnyObject,
            "productInput": [
                "uuid": planItem.product.uuid,
                "name": planItem.product.item.name,
                "category": RemoteListItemProvider().toRequestParams(planItem.product.category)
            ] as AnyObject
        ]
        if let lastServerUpdate = planItem.lastServerUpdate {
            dict["lastUpdate"] = NSNumber(value: Int64(lastServerUpdate) as Int64)
        }
        return dict
    }
}
