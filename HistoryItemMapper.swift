//
//  HistoryItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryItemMapper {

    class func dbWithHistoryItem(historyItem: HistoryItem) -> DBHistoryItem {
        let dbHistoryItem = DBHistoryItem()
        dbHistoryItem.uuid = historyItem.uuid
        dbHistoryItem.inventory = InventoryMapper.dbWithInventory(historyItem.inventory)
        dbHistoryItem.product  = ProductMapper.dbWithProduct(historyItem.product)
        dbHistoryItem.addedDate = historyItem.addedDate
        dbHistoryItem.quantity = historyItem.quantity
        dbHistoryItem.user = SharedUserMapper.dbWithSharedUser(historyItem.user)
        dbHistoryItem.lastUpdate = historyItem.lastUpdate
        dbHistoryItem.lastServerUpdate = historyItem.lastUpdate
        return dbHistoryItem
    }
    
    class func dbWith(inventoryItemWithHistory: InventoryItemWithHistoryEntry) -> DBHistoryItem {
        let dbHistoryItem = DBHistoryItem()
        dbHistoryItem.uuid = inventoryItemWithHistory.historyItemUuid
        dbHistoryItem.inventory = InventoryMapper.dbWithInventory(inventoryItemWithHistory.inventoryItem.inventory)
        dbHistoryItem.product  = ProductMapper.dbWithProduct(inventoryItemWithHistory.inventoryItem.product)
        dbHistoryItem.addedDate = inventoryItemWithHistory.addedDate
        dbHistoryItem.quantity = inventoryItemWithHistory.inventoryItem.quantityDelta
        dbHistoryItem.user = SharedUserMapper.dbWithSharedUser(inventoryItemWithHistory.user)
        dbHistoryItem.lastUpdate = inventoryItemWithHistory.inventoryItem.lastUpdate
        if let lastServerUpdate = inventoryItemWithHistory.inventoryItem.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            dbHistoryItem.lastServerUpdate = lastServerUpdate
        }
        return dbHistoryItem
    }
    
    class func historyItemWith(dbHistoryItem: DBHistoryItem) -> HistoryItem {
        return HistoryItem(
            uuid: dbHistoryItem.uuid,
            inventory: InventoryMapper.inventoryWithDB(dbHistoryItem.inventory),
            product: ProductMapper.productWithDB(dbHistoryItem.product),
            addedDate: dbHistoryItem.addedDate,
            quantity: dbHistoryItem.quantity,
            user: SharedUserMapper.sharedUserWithDB(dbHistoryItem.user),
            lastUpdate: dbHistoryItem.lastUpdate,
            lastServerUpdate: dbHistoryItem.lastServerUpdate
        )
    }
    
    class func historyItemsWithRemote(remoteListItems: RemoteHistoryItems) -> HistoryItemsWithRelations {

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
                    print("Error: ListItemMapper.listItemsWithRemote: Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categories)")
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

        let (productsCategoriesDict, productsCategories) = toProductCategoryDict(remoteListItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, products) = toProductDict(remoteListItems.products, categories: productsCategoriesDict)
        let (usersDict, users) = toUserDict(remoteListItems.users)
        let (inventoriesDict, inventories) = toInventoryDict(remoteListItems.inventories)
        
        let remoteListItemsArr = remoteListItems.historyItems
        
        let listItems = remoteListItemsArr.map {remoteListItem in
            HistoryItem(
                uuid: remoteListItem.uuid,
                inventory: inventoriesDict[remoteListItem.inventoryUuid]!,
                product: productsDict[remoteListItem.productUuid]!,
                addedDate: remoteListItem.addedDate,
                quantity: remoteListItem.quantity,
                user: usersDict[remoteListItem.userUuid]!
            )
        }
        
        return (
            listItems,
            inventories,
            products,
            users
        )
    }
}
