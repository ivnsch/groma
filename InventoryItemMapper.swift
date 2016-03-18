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
    
    class func inventoryItemWithDB(dbInventoryItem: DBInventoryItem) -> InventoryItem {
        let product = ProductMapper.productWithDB(dbInventoryItem.product)
        let inventory = InventoryMapper.inventoryWithDB(dbInventoryItem.inventory)
        return InventoryItem(uuid: dbInventoryItem.uuid, quantity: dbInventoryItem.quantity, quantityDelta: dbInventoryItem.quantityDelta, product: product, inventory: inventory)
    }
    
    class func inventoryItemWithRemote(remoteItem: RemoteInventoryItemWithProduct, inventory: Inventory) -> InventoryItem {
        let product = ProductMapper.productWithRemote(remoteItem.product, category: remoteItem.productCategory)
        return InventoryItem(uuid: remoteItem.inventoryItem.uuid, quantity: remoteItem.inventoryItem.quantity, product: product, inventory: inventory)
    }
    
    class func dbWithInventoryItem(item: InventoryItem) -> DBInventoryItem {
        let db = DBInventoryItem()
        db.uuid = item.uuid
        db.quantity = item.quantity
        db.quantityDelta = item.quantityDelta
        db.product = ProductMapper.dbWithProduct(item.product)
        db.inventory = InventoryMapper.dbWithInventory(item.inventory)
        db.lastUpdate = item.lastUpdate
        if let lastServerUpdate = item.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            db.lastServerUpdate = lastServerUpdate
        }
        return db
    }
    
    class func dbInventoryItemWithRemote(item: RemoteInventoryItemWithProduct, inventory: DBInventory) -> DBInventoryItem {
        let product = ProductMapper.dbProductWithRemote(item.product, category: item.productCategory)
        
        let db = DBInventoryItem()
        db.uuid = item.inventoryItem.uuid
        db.quantity = item.inventoryItem.quantity
        db.product = product
        db.inventory = inventory
        db.lastServerUpdate = item.inventoryItem.lastUpdate
        db.dirty = false
        return db
    }
    
    class func itemsWithRemote(remoteItems: RemoteInventoryItemsWithHistoryAndDependencies) -> (inventoryItems: [InventoryItem], historyItems: [HistoryItem]) {
        
        func toInventoryDict(remoteInventories: [RemoteInventory]) -> ([String: Inventory], [Inventory]) {
            var dict: [String: Inventory] = [:]
            var arr: [Inventory] = []
            for remoteInventory in remoteInventories {
                let inventory = InventoryMapper.inventoryWithRemote(remoteInventory)
                dict[remoteInventory.uuid] = inventory
                arr.append(inventory)
                
            }
            return (dict, arr)
        }
        
        func toProductCategoryDict(remoteProductsCategories: [RemoteProductCategory]) -> ([String: ProductCategory], [ProductCategory]) {
            var dict: [String: ProductCategory] = [:]
            var arr: [ProductCategory] = []
            for remoteProductCategory in remoteProductsCategories {
                let category = ProductCategoryMapper.categoryWithRemote(remoteProductCategory)
                dict[remoteProductCategory.uuid] = category
                arr.append(category)
                
            }
            return (dict, arr)
        }
        
        func toProductDict(remoteProducts: [RemoteProduct], categories: [String: ProductCategory]) -> ([String: Product], [Product]) {
            var dict: [String: Product] = [:]
            var arr: [Product] = []
            for remoteProduct in remoteProducts {
                if let category = categories[remoteProduct.categoryUuid] {
                    let product = ProductMapper.productWithRemote(remoteProduct, category: category)
                    dict[remoteProduct.uuid] = product
                    arr.append(product)
                } else {
                    QL4("Error: Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categories)")
                }
            }
            return (dict, arr)
        }
        
        func toUserDict(remoteUsers: [RemoteSharedUser]) -> ([String: SharedUser], [SharedUser]) {
            var dict: [String: SharedUser] = [:]
            var arr: [SharedUser] = []
            for remoteSection in remoteUsers {
                let section = SharedUserMapper.sharedUserWithRemote(remoteSection)
                dict[remoteSection.uuid] = section
                arr.append(section)
            }
            return (dict, arr)
        }
        
        func toHistoryItemDict(remoteHistoryItems: [RemoteHistoryItem], products: [String: Product], inventories: [String: Inventory], users: [String: SharedUser]) -> ([String: HistoryItem], [HistoryItem]) {
            var dict: [String: HistoryItem] = [:]
            var arr: [HistoryItem] = []
            for remoteHistoryItem in remoteHistoryItems {
                if let product = products[remoteHistoryItem.productUuid],
                    inventory = inventories[remoteHistoryItem.inventoryUuid],
                    user = users[remoteHistoryItem.userUuid]
                {
                    let historyItem = HistoryItemMapper.historyItemWithRemote(remoteHistoryItem, inventory: inventory, product: product, user: user)
                    dict[remoteHistoryItem.uuid] = historyItem
                    arr.append(historyItem)
                } else {
                    QL4("Error: Either product or inventory or user are not set for item: \(remoteHistoryItems), product: \(products[remoteHistoryItem.productUuid]), inventory: \(inventories[remoteHistoryItem.inventoryUuid]), user: \(users[remoteHistoryItem.userUuid])")
                }
            }
            return (dict, arr)
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
                quantityDelta: 0,
                product: productsDict[remoteInventoryItem.productUuid]!,
                inventory: inventoriesDict[remoteInventoryItem.inventoryUuid]!
            )
        }

        return (inventoryItems, historyItems)
    }
}