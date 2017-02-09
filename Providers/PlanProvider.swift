//
//  PlanProvider.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public protocol PlanProvider {

    func planItems(_ handler: @escaping (ProviderResult<[PlanItem]>) -> Void)

    func planItem(_ productName: String, _ handler: @escaping (ProviderResult<PlanItem?>) -> Void)
    
    func addPlanItem(_ itemInput: PlanItemInput, inventory: DBInventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void)

    func addGroupItems(_ groupItems: [GroupItem], inventory: DBInventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void)

    func addPlanItems(_ planItemsInput: [PlanItemInput], inventory: DBInventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void)

    func addProducts(_ products: [Product], inventory: DBInventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void)

    func addProduct(_ product: Product, inventory: DBInventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void)

    func updatePlanItem(_ planItem: PlanItem, inventory: DBInventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void)
    
    func removePlanItem(_ item: PlanItem, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func incrementPlanItem(_ item: PlanItem, delta: Float, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
