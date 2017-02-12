//
//  HistoryItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 12/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class HistoryItemMapper {
    
    class func historyItemWithRemote(_ remoteHistoryItem: RemoteHistoryItem, inventory: DBInventory, product: Product, user: DBSharedUser) -> HistoryItem {
        fatalError("Outdated")
        
        // Structural changes. Quick fix to compile.
//        let dummy = QuantifiableProduct(uuid: "123", baseQuantity: "1", unit: .none, product: product)
//        
//        return HistoryItem(
//            uuid: remoteHistoryItem.uuid,
//            inventory: inventory,
//            product: dummy,
//            addedDate: remoteHistoryItem.addedDate,
//            quantity: remoteHistoryItem.quantity,
//            user: user,
//            paidPrice: remoteHistoryItem.paidPrice,
//            lastServerUpdate: remoteHistoryItem.lastUpdate
//        )
    }
    
    class func historyItemsWithRemote(_ remoteListItems: RemoteHistoryItems) -> HistoryItemsWithRelations {

        func toInventoryDict(_ remoteInventories: [RemoteInventoryWithDependencies]) -> ([String: DBInventory], [DBInventory]) {
            var dict: [String: DBInventory] = [:]
            var arr: [DBInventory] = []
            for remoteInventory in remoteInventories {
                let inventory = InventoryMapper.inventoryWithRemote(remoteInventory)
                dict[remoteInventory.inventory.uuid] = inventory
                arr.append(inventory)
                
            }
            return (dict, arr)
        }
        
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

        let (productsCategoriesDict, _) = toProductCategoryDict(remoteListItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (_, products) = toProductDict(remoteListItems.products, categories: productsCategoriesDict)
        let (_, users) = toUserDict(remoteListItems.users)
        let (_, inventories) = toInventoryDict(remoteListItems.inventories)
        
//        let remoteListItemsArr = remoteListItems.historyItems
        
        let listItems: [HistoryItem] = []
        // Commented because structural changes
//        let listItems = remoteListItemsArr.map {remoteListItem in
//            HistoryItem(
//                uuid: remoteListItem.uuid,
//                inventory: inventoriesDict[remoteListItem.inventoryUuid]!,
//                product: productsDict[remoteListItem.productUuid]!,
//                addedDate: remoteListItem.addedDate,
//                quantity: remoteListItem.quantity,
//                user: usersDict[remoteListItem.userUuid]!,
//                paidPrice: remoteListItem.paidPrice,
//                lastServerUpdate: remoteListItem.lastUpdate
//            )
//        }
        
        return (
            listItems,
            inventories,
            products,
            users
        )
    }
}
