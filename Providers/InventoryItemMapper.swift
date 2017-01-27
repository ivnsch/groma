//
//  InventoryItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class InventoryItemMapper {
    
    class func inventoryItemWithDB(_ dbInventoryItem: InventoryItem) -> InventoryItem {
        let inventory = InventoryMapper.inventoryWithDB(dbInventoryItem.inventory)
        return InventoryItem(uuid: dbInventoryItem.uuid, quantity: dbInventoryItem.quantity, product: dbInventoryItem.product, inventory: inventory, lastServerUpdate: dbInventoryItem.lastServerUpdate)
    }
    
    class func inventoryItemWithRemote(_ remoteItem: RemoteInventoryItemWithProduct, inventory: DBInventory) -> InventoryItem {
        let product = ProductMapper.productWithRemote(remoteItem.product, category: remoteItem.productCategory)
        let dummy = QuantifiableProduct(uuid: "123", baseQuantity: "1", unit: .none, product: product) // quick fix for structural changes (to get it to compile)
        return InventoryItem(uuid: remoteItem.inventoryItem.uuid, quantity: remoteItem.inventoryItem.quantity, product: dummy, inventory: inventory, lastServerUpdate: remoteItem.inventoryItem.lastUpdate)
    }
    
    class func dbInventoryItemWithRemote(_ item: RemoteInventoryItemWithProduct, inventory: DBInventory) -> InventoryItem {
        let product = ProductMapper.dbProductWithRemote(item.product, category: item.productCategory)
        let dummy = QuantifiableProduct(uuid: "123", baseQuantity: "1", unit: .none, product: product) // quick fix for structural changes (to get it to compile)
        
        let db = InventoryItem()
        db.uuid = item.inventoryItem.uuid
        db.quantity = item.inventoryItem.quantity
        db.product = dummy
        db.inventory = inventory
        db.lastServerUpdate = item.inventoryItem.lastUpdate
        db.dirty = false
        return db
    }

    
    fileprivate class func toInventoryDict(_ remoteInventories: [RemoteInventoryWithDependencies]) -> ([String: DBInventory], [DBInventory]) {
        var dict: [String: DBInventory] = [:]
        var arr: [DBInventory] = []
        for remoteInventory in remoteInventories {
            let inventory = InventoryMapper.inventoryWithRemote(remoteInventory)
            dict[remoteInventory.inventory.uuid] = inventory
            arr.append(inventory)
            
        }
        return (dict, arr)
    }
    
    fileprivate class func toProductCategoryDict(_ remoteProductsCategories: [RemoteProductCategory]) -> ([String: ProductCategory], [ProductCategory]) {
        var dict: [String: ProductCategory] = [:]
        var arr: [ProductCategory] = []
        for remoteProductCategory in remoteProductsCategories {
            let category = ProductCategoryMapper.categoryWithRemote(remoteProductCategory)
            dict[remoteProductCategory.uuid] = category
            arr.append(category)
            
        }
        return (dict, arr)
    }
    
    fileprivate class func toProductDict(_ remoteProducts: [RemoteProduct], categories: [String: ProductCategory]) -> ([String: QuantifiableProduct], [QuantifiableProduct]) {
        return ([:], [])
        // Commented because structural changes
//        var dict: [String: Product] = [:]
//        var arr: [Product] = []
//        for remoteProduct in remoteProducts {
//            if let category = categories[remoteProduct.categoryUuid] {
//                let product = ProductMapper.productWithRemote(remoteProduct, category: category)
//                dict[remoteProduct.uuid] = product
//                arr.append(product)
//            } else {
//                QL4("Error: Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categories)")
//            }
//        }
//        return (dict, arr)
    }
    
    class func itemsWithRemote(_ remoteItems: RemoteInventoryItemsWithDependencies) -> [InventoryItem] {
        
        let (productsCategoriesDict, _) = toProductCategoryDict(remoteItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, _) = toProductDict(remoteItems.products, categories: productsCategoriesDict)
        let (inventoriesDict, _) = toInventoryDict(remoteItems.inventories)
        
        let remoteListItemsArr = remoteItems.inventoryItems
        
        let inventoryItems = remoteListItemsArr.map {remoteInventoryItem in
            InventoryItem(
                uuid: remoteInventoryItem.uuid,
                quantity: remoteInventoryItem.quantity,
                product: productsDict[remoteInventoryItem.productUuid]!,
                inventory: inventoriesDict[remoteInventoryItem.inventoryUuid]!,
                lastServerUpdate: remoteInventoryItem.lastUpdate
            )
        }
        
        return inventoryItems
    }
    
    class func itemsWithRemote(_ remoteItems: RemoteInventoryItemsWithHistoryAndDependencies) -> (inventoryItems: [InventoryItem], historyItems: [HistoryItem]) {
        
        func toUserDict(_ remoteUsers: [RemoteSharedUser]) -> ([String: DBSharedUser], [DBSharedUser]) {
            var dict: [String: DBSharedUser] = [:]
            var arr: [DBSharedUser] = []
            for remoteSection in remoteUsers {
                let section = SharedUserMapper.sharedUserWithRemote(remoteSection)
                dict[remoteSection.uuid] = section
                arr.append(section)
            }
            return (dict, arr)
        }
        
        func toHistoryItemDict(_ remoteHistoryItems: [RemoteHistoryItem], products: [String: QuantifiableProduct], inventories: [String: DBInventory], users: [String: DBSharedUser]) -> ([String: HistoryItem], [HistoryItem]) {
            return ([:], [])
            // Commented because structural changes
//            var dict: [String: HistoryItem] = [:]
//            var arr: [HistoryItem] = []
//            for remoteHistoryItem in remoteHistoryItems {
//                if let product = products[remoteHistoryItem.productUuid],
//                    let inventory = inventories[remoteHistoryItem.inventoryUuid],
//                    let user = users[remoteHistoryItem.userUuid]
//                {
//                    let historyItem = HistoryItemMapper.historyItemWithRemote(remoteHistoryItem, inventory: inventory, product: product, user: user)
//                    dict[remoteHistoryItem.uuid] = historyItem
//                    arr.append(historyItem)
//                } else {
//                    QL4("Error: Either product or inventory or user are not set for item: \(remoteHistoryItems), product: \(products[remoteHistoryItem.productUuid]), inventory: \(inventories[remoteHistoryItem.inventoryUuid]), user: \(users[remoteHistoryItem.userUuid])")
//                }
//            }
//            return (dict, arr)
        }
        
        let (productsCategoriesDict, _) = toProductCategoryDict(remoteItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, _) = toProductDict(remoteItems.products, categories: productsCategoriesDict)
        let (usersDict, _) = toUserDict(remoteItems.users)
        let (inventoriesDict, _) = toInventoryDict(remoteItems.inventories)
        let (_, historyItems) = toHistoryItemDict(remoteItems.historyItems, products: productsDict, inventories: inventoriesDict, users: usersDict)
        
        let remoteListItemsArr = remoteItems.inventoryItems
        
        let inventoryItems = remoteListItemsArr.map {remoteInventoryItem in
            InventoryItem(
                uuid: remoteInventoryItem.uuid,
                quantity: remoteInventoryItem.quantity,
                product: productsDict[remoteInventoryItem.productUuid]!,
                inventory: inventoriesDict[remoteInventoryItem.inventoryUuid]!,
                lastServerUpdate: remoteInventoryItem.lastUpdate
            )
        }

        return (inventoryItems, historyItems)
    }
}
