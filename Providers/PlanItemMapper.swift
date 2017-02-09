//
//  PlanItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PlanItemMapper {

    class func dbWith(_ planItem: PlanItem) -> DBPlanItem {
        let dbPlanItem = DBPlanItem()
        dbPlanItem.inventory = planItem.inventory
        dbPlanItem.product  = planItem.product
        dbPlanItem.quantity = planItem.quantity
        if let lastServerUpdate = planItem.lastServerUpdate {
            dbPlanItem.lastServerUpdate = lastServerUpdate
        }
        return dbPlanItem
    }
    
    class func planItemWith(_ dbPlanItem: DBPlanItem, usedQuantity: Float) -> PlanItem {
        return PlanItem(
            inventory: InventoryMapper.inventoryWithDB(dbPlanItem.inventory),
            product: dbPlanItem.product,
            quantity: dbPlanItem.quantity,
            usedQuantity: usedQuantity,
            lastServerUpdate: dbPlanItem.lastServerUpdate
        )
    }
    
    // Note: letting variables with "list" instead of "plan" in names
    class func planItemsWithRemote(_ remoteListItems: RemotePlanItems) -> PlanItemsWithRelations {
        
        func toProductCategoryDict(_ remoteProductsCategories: [RemoteProductCategory]) -> ([String: ProductCategory], [ProductCategory]) {
            var dict: [String: ProductCategory] = [:]
            var arr: [ProductCategory] = []
            for remoteProductCategory in remoteProductsCategories {
                let category = ProductCategoryMapper.categoryWithRemote(remoteProductCategory)
                dict[remoteProductCategory.uuid] = category
                arr.append(category)
                
            }
            return (dict, arr)
        }
        
        func toProductDict(_ remoteProducts: [RemoteProduct], categories: [String: ProductCategory]) -> ([String: Product], [Product]) {
            var dict: [String: Product] = [:]
            var arr: [Product] = []
            for remoteProduct in remoteProducts {
                if let category = categories[remoteProduct.categoryUuid] {
                    let product = ProductMapper.productWithRemote(remoteProduct, category: category)
                    dict[remoteProduct.uuid] = product
                    arr.append(product)
                } else {
                    print("Error: ListItemMapper.listItemsWithRemote: Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categories)")
                }
            }
            return (dict, arr)
        }
        
        
        let (productsCategoriesDict, _) = toProductCategoryDict(remoteListItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, products) = toProductDict(remoteListItems.products, categories: productsCategoriesDict)
        let inventory = InventoryMapper.inventoryWithRemote(remoteListItems.inventory)
        
        let remoteListItemsArr = remoteListItems.planItems
        
        let listItems = remoteListItemsArr.map {remoteListItem in
            PlanItem(
                inventory: inventory,
                product: productsDict[remoteListItem.productUuid]!,
                quantity: remoteListItem.quantity,
                usedQuantity: 0, // TODO review - ensure this is always calculated from history, and not use this "0"
                lastServerUpdate: remoteListItem.lastUpdate
            )
        }
        
        return (
            listItems,
            inventory,
            products
        )
    }
}
