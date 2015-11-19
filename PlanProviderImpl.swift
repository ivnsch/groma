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
        addOrIncrementPlanItem(itemInput, inventory: inventory, handler)
    }

    func addGroupItems(groupItems: [GroupItem], inventory: Inventory, _ handler: ProviderResult<[PlanItem]> -> Void) {
        let planItems = groupItems.map{
            PlanItem(inventory: inventory, product: $0.product, quantity: $0.quantity, usedQuantity: 0)
        }
        addPlanItems(planItems, inventory: inventory, handler)
    }
    
    func addPlanItems(planItems: [PlanItem], inventory: Inventory, _ handler: ProviderResult<[PlanItem]> -> Void) {
        dbProvider.addOrIncrementPlanItems(planItems, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .Success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addPlanItems(planItemsInput: [PlanItemInput], inventory: Inventory, _ handler: ProviderResult<[PlanItem]> -> Void) {
        dbProvider.addOrUpdateWithIncrement(planItemsInput, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .Success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addProducts(products: [Product], inventory: Inventory, _ handler: ProviderResult<[PlanItem]> -> Void) {
        dbProvider.addOrIncrementProducts(products, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .Success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func addProduct(product: Product, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        addProducts([product], inventory: inventory) {result in
            if let planItem = result.sucessResult?.first {
                handler(ProviderResult(status: .Success, sucessResult: planItem))
            } else {
                print("Error: Could not get the plan item: \(result)")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }

    func updatePlanItem(planItem: PlanItem, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        dbProvider.update(planItem) {updated in
            if updated {
                // update product can change the name or price, and the products can be referenced by list items, so we have to invalidate memory cache.
                Providers.listItemsProvider.invalidateMemCache()

                handler(ProviderResult(status: .Success, sucessResult: planItem))
            } else {
                handler(ProviderResult(status: .DatabaseSavingError))
            }
        }
    }

    // TODO review this, adding product with existing name shows a new items in list this shouldn't happen. Maybe it's only the tableview
    private func addOrIncrementPlanItem(itemInput: PlanItemInput, inventory: Inventory, _ handler: ProviderResult<PlanItem> -> Void) {
        
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
        
        planItem(itemInput.name) {[weak self] result in
            if let existingPlanItemMaybe = result.sucessResult, existingPlanItem = existingPlanItemMaybe {
         
                // if item with product and inventory already exists, increment it
                let updatedProduct = existingPlanItem.product.copy(name: itemInput.name, price: itemInput.price, category: itemInput.category)
                let updatedPlanItem = existingPlanItem.copy(product: updatedProduct, quantity: existingPlanItem.quantity + itemInput.quantity, quantityDelta: existingPlanItem.quantityDelta + itemInput.quantity)
                self?.updatePlanItem(updatedPlanItem, inventory: inventory, handler)
                
            } else { // if it doesn't exist, add it
                
                // check if product exists
                Providers.productProvider.product(itemInput.name) {result in
                    if let product = result.sucessResult { // products exists - update it and reference it
                        let mergedProduct = Product(uuid: product.uuid, name: itemInput.name, price: itemInput.price, category: itemInput.category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit)
                        onHasProduct(mergedProduct, isUpdate: true)
                    } else { // product doesn't exist - add it
                        let product = Product(uuid: NSUUID().UUIDString, name: itemInput.name, price: itemInput.price, category: itemInput.category, baseQuantity: itemInput.baseQuantity, unit: itemInput.unit)
                        Providers.productProvider.add(product) {result in
                            if result.success {
                                onHasProduct(product, isUpdate: false)
                            } else {
                                handler(ProviderResult(status: .DatabaseSavingError))
                            }
                        }
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
