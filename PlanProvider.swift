//
//  PlanProvider.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

protocol PlanProvider {

    func planItems(handler: ProviderResult<[PlanItem]> -> Void)

    func planItem(productName: String, _ handler: ProviderResult<PlanItem?> -> Void)
    
    func addPlanItem(itemInput: PlanItemInput, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void)

    func updatePlanItem(planItem: PlanItem, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void)
    
    func removePlanItem(item: PlanItem, _ handler: ProviderResult<Any> -> Void)
    
    func incrementPlanItem(item: PlanItem, delta: Int, _ handler: ProviderResult<Any> -> Void)
}
