//
//  PlanProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PlanProviderImpl: PlanProvider {

    let dbProvider = RealmPlanProvider()

    func planItems(handler: ProviderResult<[PlanItem]> -> Void) {
        dbProvider.planItems(NSDate().startOfMonth) {dbItems in
            handler(ProviderResult(status: .Success, sucessResult: dbItems))
        }
    }
    
    func planItem(productName: String, _ handler: ProviderResult<PlanItem?> -> Void) {
        dbProvider.planItem(productName, startDate: NSDate().startOfMonth) {planItemMaybe in
            if let planItem = planItemMaybe {
                handler(ProviderResult(status: .Success, sucessResult: planItem))
            } else {
                handler(ProviderResult(status: .Success, sucessResult: nil))
            }
        }
    }

    func addPlanItem(itemInput: PlanItemInput, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        addOrUpdatePlanItem(itemInput, inventory: inventory, handler)
    }
    
    func updatePlanItem(itemInput: PlanItemInput, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        addOrUpdatePlanItem(itemInput, inventory: inventory, handler)
    }
    
    private func addOrUpdatePlanItem(itemInput: PlanItemInput, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        
        func onHasProduct(product: Product, isUpdate: Bool) {
            let planItem = PlanItem(inventory: inventory, product: product, quantity: itemInput.quantity, usedQuantity: -1)
            dbProvider.add(planItem) {saved in
                if saved {
                    if isUpdate {
                        // update product can change the name or price, and the products can be referenced by list items, so we have to invalidate memory cache.
                        Providers.listItemsProvider.invalidateMemCache()
                    }
                    handler(ProviderResult(status: .Success, sucessResult: planItem))
                } else {
                    handler(ProviderResult(status: .DatabaseSavingError))
                }
            }
        }
        
        Providers.listItemsProvider.product(itemInput.name) {result in
            if let product = result.sucessResult {
                let mergedProduct = Product(uuid: product.uuid, name: itemInput.name, price: itemInput.price)
                onHasProduct(mergedProduct, isUpdate: true)
            } else {
                let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price)
                Providers.listItemsProvider.add(product) {result in
                    if result.success {
                        onHasProduct(product, isUpdate: false)
                    } else {
                        handler(ProviderResult(status: .DatabaseSavingError))
                    }
                }
            }
        }
    }
    
    func addPlanItem(item: PlanItem, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.add(item) {saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                // TODO server
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
    
    func removePlanItem(item: PlanItem, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.remove(item) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func incrementPlanItem(item: PlanItem, delta: Int, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.increment(item, delta: delta) {saved in
            if saved {
                handler(ProviderResult(status: .Success))
                
                // TODO server
                
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }
}
