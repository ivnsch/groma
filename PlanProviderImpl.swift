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
    let remoteProvider = RemotePlanItemsProvider()
    
    func planItems(_ handler: @escaping (ProviderResult<[PlanItem]>) -> Void) {
        dbProvider.planItems(Date().startOfMonth) {dbItems in
            handler(ProviderResult(status: .success, sucessResult: dbItems))
        }
    }
    
    func planItem(_ productName: String, _ handler: @escaping (ProviderResult<PlanItem?>) -> Void) {
        dbProvider.planItem(productName, startDate: Date().startOfMonth) {planItemMaybe in
            if let planItem = planItemMaybe {
                handler(ProviderResult(status: .success, sucessResult: planItem))
            } else {
                handler(ProviderResult(status: .success, sucessResult: nil))
            }
        }
    }

    func addPlanItem(_ itemInput: PlanItemInput, inventory: Inventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void) {
        addOrIncrementPlanItem(itemInput, inventory: inventory, handler)
    }

    func addGroupItems(_ groupItems: [GroupItem], inventory: Inventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void) {
        let planItems = groupItems.map{
            PlanItem(inventory: inventory, product: $0.product, quantity: $0.quantity, usedQuantity: 0)
        }
        addPlanItems(planItems, inventory: inventory, handler)
    }
    
    // TODO remote
    func addPlanItems(_ planItems: [PlanItem], inventory: Inventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void) {
        dbProvider.addOrIncrementPlanItems(planItems, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // TODO is this used? if yes needs remote
    func addPlanItems(_ planItemsInput: [PlanItemInput], inventory: Inventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void) {
        dbProvider.addOrUpdateWithIncrement(planItemsInput, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    // TODO is this used? if yes needs remote
    func addProducts(_ products: [Product], inventory: Inventory, _ handler: @escaping (ProviderResult<[PlanItem]>) -> Void) {
        dbProvider.addOrIncrementProducts(products, inventory: inventory) {planItemsMaybe in
            if let planItems = planItemsMaybe {
                handler(ProviderResult(status: .success, sucessResult: planItems))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func addProduct(_ product: Product, inventory: Inventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void) {
        addProducts([product], inventory: inventory) {[weak self] result in
            if let planItem = result.sucessResult?.first {
                handler(ProviderResult(status: .success, sucessResult: planItem))
                
                self?.remoteProvider.addUpdatePlanItem(planItem) {remoteResult in
                    if !remoteResult.success {
                        print("Error: addOrIncrementPlanItem: \(planItem), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
                
            } else {
                print("Error: Could not get the plan item: \(result)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func updatePlanItem(_ planItem: PlanItem, inventory: Inventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void) {
        dbProvider.update(planItem) {[weak self] updated in
            if updated {
                // update product can change the name or price, and the products can be referenced by list items, so we have to invalidate memory cache.
                Providers.listItemsProvider.invalidateMemCache()

                handler(ProviderResult(status: .success, sucessResult: planItem))
                
                self?.remoteProvider.addUpdatePlanItem(planItem) {remoteResult in
                    if !remoteResult.success {
                        print("Error: addOrIncrementPlanItem: \(planItem), result: \(remoteResult)")
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: handler)
                    }
                }
                
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }

    // TODO review this, adding product with existing name shows a new items in list this shouldn't happen. Maybe it's only the tableview
    fileprivate func addOrIncrementPlanItem(_ itemInput: PlanItemInput, inventory: Inventory, _ handler: @escaping (ProviderResult<PlanItem>) -> Void) {
        
        func onHasProduct(_ product: Product, isUpdate: Bool) {
            let planItem = PlanItem(inventory: inventory, product: product, quantity: itemInput.quantity, usedQuantity: -1)
            dbProvider.add(planItem) {[weak self] saved in
                if saved {
                    if isUpdate {
                        // update product can change the name or price, and the products can be referenced by list items, so we have to invalidate memory cache.
                        Providers.listItemsProvider.invalidateMemCache()
                    }
                    handler(ProviderResult(status: .success, sucessResult: planItem))
                    
                    self?.remoteProvider.addUpdatePlanItem(planItem) {remoteResult in
                        if !remoteResult.success {
                            DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<PlanItem>) in
                                print("Error: addOrIncrementPlanItem: \(planItem), result: \(remoteResult)")
                            }
                        }
                    }
                    
                } else {
                    handler(ProviderResult(status: .databaseSavingError))
                }
            }
        }
        
        planItem(itemInput.name) {[weak self] result in
            if let existingPlanItemMaybe = result.sucessResult, let existingPlanItem = existingPlanItemMaybe {
         
                // if item with product and inventory already exists, increment it
                let updatedCategory = existingPlanItem.product.category.copy(name: itemInput.category, color: itemInput.categoryColor)
                let updatedProduct = existingPlanItem.product.copy(name: itemInput.name, category: updatedCategory)
                let updatedPlanItem = existingPlanItem.copy(product: updatedProduct, quantity: existingPlanItem.quantity + itemInput.quantity, quantityDelta: existingPlanItem.quantityDelta + itemInput.quantity)
                self?.updatePlanItem(updatedPlanItem, inventory: inventory, handler)
                
            } else { // if it doesn't exist, add it
                
                // check if product exists
                Providers.productProvider.product(itemInput.name, brand: itemInput.brand) {result in
                    if let product = result.sucessResult { // products exists - update it and reference it
                        let mergedCategory = product.category.copy(name: itemInput.category, color: itemInput.categoryColor)
                        let mergedProduct = Product(uuid: product.uuid, name: itemInput.name, category: mergedCategory, brand: itemInput.brand)
                        onHasProduct(mergedProduct, isUpdate: true)
                    } else { // product doesn't exist - add it
                        
                        // check if category exists
                        Providers.productCategoryProvider.categoryWithName(itemInput.category, {result in
                            
                            // if category doesn't exist, create a new one
                            let category: ProductCategory = result.sucessResult ?? ProductCategory(uuid: UUID().uuidString, name: itemInput.category, color: itemInput.categoryColor)

                            // add the product
                            let product = Product(uuid: UUID().uuidString, name: itemInput.name, category: category, brand: itemInput.brand)
                            Providers.productProvider.add(product, remote: true) {result in
                                if result.success {
                                    onHasProduct(product, isUpdate: false)
                                } else {
                                    handler(ProviderResult(status: .databaseSavingError))
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func addPlanItem(_ item: PlanItem, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.add(item) {saved in
            if saved {
                handler(ProviderResult(status: .success))
                
                // TODO server
                
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }
    
    func removePlanItem(_ item: PlanItem, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.remove(item) {removed in
            handler(ProviderResult(status: removed ? ProviderStatusCode.success : ProviderStatusCode.databaseUnknown))
        }
    }
    
    func incrementPlanItem(_ item: PlanItem, delta: Int, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.increment(item, delta: delta) {saved in
            if saved {
                handler(ProviderResult(status: .success))
                
                // TODO server
                
            } else {
                handler(ProviderResult(status: .databaseSavingError))
            }
        }
    }
}
