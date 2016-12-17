//
//  RealmPlanProvider.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO! move filter strings to db classes like everywhere else (and add "Opt" at the end to linked optionals) - skipping this for now since we don't use plan. Otherwise maybe remove plan code entirely.
class RealmPlanProvider: RealmProvider {

    let dbHistoryProvider = RealmHistoryProvider()

    // NOTE: Disabled because we added now inventories to history fetch, since plan will not be in the release for now changes not implemented
    // TODO optimize - fetch first plan items, is it possible (and better) to fetch only history items for the fetched plan items?
    func planItems(_ startDate: Date, handler: @escaping ([PlanItem]) -> ()) {

//        dbHistoryProvider.loadHistoryItems(startDate: NSDate().startOfMonth) {[weak self] historyItems in
//            
//            if let weakSelf = self {
//                let productQuantities = weakSelf.productsTotalQuantities(historyItems)
//                // Use history to calculate how much has been already consumed of each product in current time period
//                let mapper: DBPlanItem -> PlanItem = {dbPlanItem in
//                    let usedQuantity = productQuantities[dbPlanItem.product.uuid] ?? 0
//                    return PlanItemMapper.planItemWith(dbPlanItem, usedQuantity: usedQuantity)
//                }
//                weakSelf.load(mapper, handler: handler)
//                
//            } else {
//                print("Error: RealmPlanProvider.planItems, self is nil")
//            }
//        }
    }

    // NOTE: Disabled because we added now inventories to history fetch, since plan will not be in the release for now changes not implemented
    // TODO optimize - fetch first plan item, if there's no plan item, there's no need to fetch the history
    func planItem(_ productName: String, startDate: Date, handler: @escaping (PlanItem?) -> ()) {
//        dbHistoryProvider.loadHistoryItems(productName, startDate: NSDate().startOfMonth) {[weak self] historyItems in
//            if let weakSelf = self {
//                // Use history to calculate how much has been already consumed product in current time period
//                let mapper: DBPlanItem -> PlanItem = {dbPlanItem in
//                    let usedQuantity = historyItems.totalQuantity
//                    return PlanItemMapper.planItemWith(dbPlanItem, usedQuantity: usedQuantity)
//                }
//                weakSelf.loadFirst(mapper, filter: "product.name == '\(productName)'", handler: handler)
//                
//            } else {
//                print("Error: RealmPlanProvider.planItems, self is nil")
//            }
//        }
    }
    
    /**
    * Calculates total amount of product in history items
    * Returns dictionary product uuid -> total amount
    */
    fileprivate func productsTotalQuantities(_ historyItems: [HistoryItem]) -> [String: Int] {
        var dict: [String: Int] = [:]
        for historyItem in historyItems {
            if dict[historyItem.product.uuid] == nil {
                dict[historyItem.product.uuid] = historyItem.quantity
            } else {
                dict[historyItem.product.uuid]! += historyItem.quantity
            }
        }
        return dict
    }

    func addOrIncrementProducts(_ products: [Product], inventory: DBInventory, _ handler: @escaping ([PlanItem]?) -> Void) {
        
        doInWriteTransaction ({[weak self] realm in
            if let weakSelf = self {
                
                return syncedRet(weakSelf) {
                    
                    let productNames = products.map{$0.name}
                    let productNamesStr: String = productNames.map{"'\($0)'"}.joined(separator: ",")

                    // get all possible already existing plan items in a dictionary
                    let existingPlanItems = realm.objects(DBPlanItem.self).filter("product.name IN {\(productNamesStr)}").distinctArray()
                    let existingPlanItemsDict: [String: DBPlanItem] = productNames.toDictionary {productName in
                        (productName, existingPlanItems.filter{$0.product.name == productName}.first)
                    }
                    
                    // the items that we will write to the database both new as to be updated
                    var planItemsToSave: [DBPlanItem] = []
                    
                    // iterate through input items and update or create depending if item with same product name already exists or not
                    for product in products {
                        if let existingPlanItem = existingPlanItemsDict[product.name] {
                            
                            // update the plan item
                            // TODO review + 1 in relation with product's base unit (if this is e.g. 100g, does it makes sense to add only 1? Note also that it seems natural that plan item displays quantity in this units - that is 100g, 200g
                            existingPlanItem.quantity = existingPlanItem.quantity + 1
                            existingPlanItem.quantityDelta = existingPlanItem.quantityDelta + 1 // TODO review this
                            //                            existingPlanItem.product = existingPlanItemProduct
                            
                            planItemsToSave.append(existingPlanItem)
                            
                        } else { // plan item with same product name doesn't exist - create a new one
                            
                            let planItem = DBPlanItem()
                            planItem.inventory = inventory
                            planItem.product = product
                            
                            planItemsToSave.append(planItem)
                        }
                    }
                    
                    realm.add(planItemsToSave, update: true)
                    
                    
                    // fetch history to see how many items have been used so far
//                    let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
                    let dbHistoryItems: [HistoryItem] = weakSelf.loadSync(realm, predicate: NSPredicate(format: "addedDate >= %@", Date().startOfMonth as CVarArg))
                    let productQuantities = weakSelf.productsTotalQuantities(dbHistoryItems)
                    let savedPlanItems: [PlanItem] = planItemsToSave.map{
                        let usedQuantity = productQuantities[$0.product.uuid] ?? 0
                        return PlanItemMapper.planItemWith($0, usedQuantity: usedQuantity)
                    }
                    
                    return savedPlanItems
                }
                
            } else {
                print("Warn: RealmPlanProvider.addOrIncrementProducts weakSelf is nil")
                return nil
            }
            
            }) {savedPlanItemsMaybe in
                handler(savedPlanItemsMaybe)
        }
    }
    
    func addOrIncrementPlanItems(_ planItems: [PlanItem], inventory: DBInventory, _ handler: @escaping ([PlanItem]?) -> Void) {
        
        doInWriteTransaction ({[weak self] realm in
            if let weakSelf = self {
                
                return syncedRet(weakSelf) {
                    
                    let productNames = planItems.map{$0.product.name}
                    let productNamesStr: String = productNames.map{"'\($0)'"}.joined(separator: ",")
                    
                    // get all possible already existing plan items in a dictionary
                    let existingPlanItems = realm.objects(DBPlanItem.self).filter("product.name IN {\(productNamesStr)}").distinctArray()
                    let existingPlanItemsDict: [String: DBPlanItem] = productNames.toDictionary {productName in
                        (productName, existingPlanItems.filter{$0.product.name == productName}.first)
                    }
                    
                    // the items that we will write to the database both new as to be updated
                    var planItemsToSave: [DBPlanItem] = []
                    
                    // iterate through input items and update or create depending if item with same product name already exists or not
                    for planItemInput in planItems {
                        if let existingPlanItem = existingPlanItemsDict[planItemInput.product.name] {
                            
                            // update the plan item
                            existingPlanItem.quantity = existingPlanItem.quantity + planItemInput.quantity
                            existingPlanItem.quantityDelta = existingPlanItem.quantityDelta + planItemInput.quantity // TODO review this
//                            existingPlanItem.product = existingPlanItemProduct
                            
                            planItemsToSave.append(existingPlanItem)
                            
                        } else { // plan item with same product name doesn't exist - create a new one
                            let planItem = DBPlanItem()
                            planItem.inventory = inventory
                            planItem.product = planItemInput.product
                            planItem.quantity = planItemInput.quantity
                            planItem.quantityDelta = planItemInput.quantity // on a new obj quantity delta is always quantity (quantity which has not been synced yet)
                            
                            planItemsToSave.append(planItem)
                        }
                    }
                    
                    realm.add(planItemsToSave, update: true)
                    
                    // fetch history to see how many items have been used so far
//                    let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
                    let dbHistoryItems: [HistoryItem] = weakSelf.loadSync(realm, predicate: NSPredicate(format: "addedDate >= %@",  Date().startOfMonth as CVarArg))
                    let productQuantities = weakSelf.productsTotalQuantities(dbHistoryItems)
                    let savedPlanItems: [PlanItem] = planItemsToSave.map{
                        let usedQuantity = productQuantities[$0.product.uuid] ?? 0
                        return PlanItemMapper.planItemWith($0, usedQuantity: usedQuantity)
                    }
                    
                    return savedPlanItems

                }
                
            } else {
                print("Warn: RealmPlanProvider.addOrIncrementProducts weakSelf is nil")
                return nil
            }
            
            }) {savedPlanItemsMaybe in
                handler(savedPlanItemsMaybe)
        }
    }
    
    func addOrUpdateWithIncrement(_ planItemsInput: [PlanItemInput], inventory: DBInventory, _ handler: @escaping ([PlanItem]?) -> Void) {
        
        doInWriteTransaction ({[weak self] realm in
            if let weakSelf = self {
                
                return syncedRet(weakSelf) {
                    
                    let productNames = planItemsInput.map{$0.name}
                    let productNamesStr: String = productNames.map{"'\($0)'"}.joined(separator: ",")
                    
                    // get all possible already existing plan items in a dictionary
                    let existingPlanItems = realm.objects(DBPlanItem.self).filter("product.name IN {\(productNamesStr)}").distinctArray()
                    let existingPlanItemsDict: [String: DBPlanItem] = productNames.toDictionary {productName in
                        (productName, existingPlanItems.filter{$0.product.name == productName}.first)
                    }
                    
                    // the items that we will write to the database both new as to be updated
                    var planItemsToSave: [DBPlanItem] = []
                    
                    // iterate through input items and update or create depending if item with same product name already exists or not
                    for planItemInput in planItemsInput {
                        if let existingPlanItem = existingPlanItemsDict[planItemInput.name] {
                            
                            // update the product - if the new plan item has e.g. a different category, we overwrite the old one
                            // note that this will update the product for all the app
                            let existingPlanItemProduct = existingPlanItem.product
                            let updatedCategory = ProductCategory()
                            updatedCategory.uuid = existingPlanItemProduct.category.uuid
                            updatedCategory.name = planItemInput.category
                            updatedCategory.setColor(planItemInput.categoryColor)
                            existingPlanItemProduct.category = updatedCategory
                            
                            // update the plan item
                            existingPlanItem.quantity = existingPlanItem.quantity + planItemInput.quantity
                            existingPlanItem.quantityDelta = existingPlanItem.quantityDelta + planItemInput.quantity // TODO review this
                            existingPlanItem.product = existingPlanItemProduct
                            
                            planItemsToSave.append(existingPlanItem)
                            
                        } else { // plan item with same product name doesn't exist - create a new one
                            
                            // TODO this could be optimised by fetching all the products in advance, at once. But for now we do a single fetch for each product
                            // code would need some structure changes for this
                            //                            let productsNamesStr: String = ",".join(productNames.map{"'\($0)'"})
                            //                            let existingProducts = realm.objects(Product).filter("name IN {\(productsNamesStr)}")
                            
                            // check if a product with the plan item name's already exist, to reference it, otherwise create a new product
                            let product: Product = {
                               
                                return (realm.objects(Product.self).filter("name == '\(planItemInput.name)'").first) ?? {
                                    
                                    // check if category with given name exists or create a new one
                                    let category: ProductCategory = (realm.objects(ProductCategory.self).filter("name == '\(planItemInput.category)'").first) ?? {
                                        let category = ProductCategory()
                                        category.uuid = NSUUID().uuidString
                                        category.name = planItemInput.category
                                        category.setColor(planItemInput.categoryColor)
                                        return category
                                    }()
                                    
                                    let product = Product()
                                    product.uuid = NSUUID().uuidString
                                    product.name = planItemInput.name
                                    product.category = category
                                    return product
                                }()
                            }()
                            
                            // create the new plan item
                            let planItem = DBPlanItem()
                            planItem.inventory = inventory
                            planItem.product = product
                            planItem.quantity = planItemInput.quantity
                            planItem.quantityDelta = planItemInput.quantity // on a new obj quantity delta is always quantity (quantity which has not been synced yet)
                            
                            planItemsToSave.append(planItem)
                        }
                    }
                    
                    realm.add(planItemsToSave, update: true)
                    
                    // fetch history to see how many items have been used so far
//                    let mapper = {HistoryItemMapper.historyItemWith($0)} // TODO loading shared users (when there are shared users) when accessing, crash: BAD_ACCESS, re-test after realm update
                    let dbHistoryItems: [HistoryItem] = weakSelf.loadSync(realm, predicate: NSPredicate(format: "addedDate >= %@",  Date().startOfMonth as CVarArg))
                    let productQuantities = weakSelf.productsTotalQuantities(dbHistoryItems)
                    let savedPlanItems: [PlanItem] = planItemsToSave.map{
                        let usedQuantity = productQuantities[$0.product.uuid] ?? 0
                        return PlanItemMapper.planItemWith($0, usedQuantity: usedQuantity)
                    }
                    
                    return savedPlanItems
                }
                
            } else {
                print("Warn: RealmPlanProvider.addOrIncrementProducts weakSelf is nil")
                return nil
            }
            
            }) {savedPlanItemsMaybe in
                handler(savedPlanItemsMaybe)
        }
    }
    
    func add(_ item: PlanItem, handler: @escaping (Bool) -> ()) {
        update(item, handler: handler)
    }

    func update(_ item: PlanItem, handler: @escaping (Bool) -> ()) {
        let dbObj = PlanItemMapper.dbWith(item)
        self.saveObj(dbObj, update: true, handler: handler)
    }
    
    func remove(_ item: PlanItem, handler: @escaping (Bool) -> ()) {
        self.remove("product.name = '\(item.product.name)'", handler: handler, objType: DBPlanItem.self)
    }
    
    func increment(_ item: PlanItem, delta: Int, onlyDelta: Bool = false, handler: @escaping (Bool) -> ()) {

        doInWriteTransaction ({[weak self] realm in
            if let weakSelf = self {
            
                return syncedRet(weakSelf) {
                    // load
                    var results = realm.objects(DBPlanItem.self)
                    results = results.filter(NSPredicate(format: "product.name = '\(item.product.name)'", argumentArray: []))
                    let objs: [DBPlanItem] = results.toArray(nil)
                    let dbPlanItems = objs.map{PlanItemMapper.planItemWith($0, usedQuantity: -1)} // usedQuantity is ignored here (we only convert to DB object and it doesn't use this), FIXME it's not good to have not used fields like this
                    let planItemMaybe = dbPlanItems.first
                    
                    if let planItem = planItemMaybe {
                        // increment
                        let incrementedPlanItem: PlanItem =  {
                            if onlyDelta {
                                return planItem.copy(quantityDelta: planItem.quantityDelta + delta)
                            } else {
                                return planItem.incrementQuantityCopy(delta)
                            }
                        }()
                        
                        // convert to db object
                        let dbIncrementedPlanItem = PlanItemMapper.dbWith(incrementedPlanItem)
                        
                        // save
                        realm.add(dbIncrementedPlanItem, update: true)
                        
                        return true
                        
                    } else {
                        print("Plan item not found: \(item)")
                        return false
                    }
                }

            } else {
                print("Warn: RealmPlanProvider.increment weakSelf is nil")
                return false
            }

            
            }) {success in
                handler(success ?? false)
        }
    }
}
