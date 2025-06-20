//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation


class ListItemMapper {
    
//    class func listItemWithDB(_ dbListItem: ListItem) -> ListItem {
//        let product = StoreProductMapper.productWithDB(dbListItem.product)
//        let section = dbListItem.section
//        return ListItem(
//            uuid: dbListItem.uuid,
//            product: product.copy(),
//            section: section,
//            list: dbListItem.list.copy(),
//            note: dbListItem.note,
//            todoQuantity: dbListItem.todoQuantity,
//            todoOrder: dbListItem.todoOrder,
//            doneQuantity: dbListItem.doneQuantity,
//            doneOrder: dbListItem.doneOrder,
//            stashQuantity: dbListItem.stashQuantity,
//            stashOrder: dbListItem.stashOrder,
//            lastServerUpdate: dbListItem.lastServerUpdate
//        )
//    }
//    
//    class func dbWithListItem(_ listItem: ListItem) -> ListItem {
//        let dbListItem = ListItem()
//        dbListItem.uuid = listItem.uuid
//        dbListItem.note = listItem.note ?? "" // TODO check if db obj can have optional if yes remove ??
//
//        dbListItem.todoQuantity = listItem.todoQuantity
//        dbListItem.todoOrder = listItem.todoOrder
//        dbListItem.doneQuantity = listItem.doneQuantity
//        dbListItem.doneOrder = listItem.doneOrder
//        dbListItem.stashQuantity = listItem.stashQuantity
//        dbListItem.stashOrder = listItem.stashOrder
//        
//        dbListItem.product = StoreProductMapper.dbWithProduct(listItem.product)
//        dbListItem.section = listItem.section
//        dbListItem.list = listItem.list
//        
//        if let lastServerUpdate = listItem.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
//            dbListItem.lastServerUpdate = lastServerUpdate
//        }
//        return dbListItem
//    }
//    
    /**
    Parses the remote list items into model objects
    Note that the list items are sorted here by order field. The backend doesn't do this.
    */
    class func listItemsWithRemote(_ remoteListItems: RemoteListItems, sortOrderByStatus: ListItemStatus?) -> ListItemsWithRelations {

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
                    logger.e("Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categories)")
                }
            }
            return (dict, arr)
        }
        
        func toStoreProductDict(_ remoteProducts: [RemoteStoreProduct], products: [String: Product]) -> ([String: StoreProduct], [StoreProduct]) {
            return ([:], [])
            // Commented because structural changes
//            var dict: [String: StoreProduct] = [:]
//            var arr: [StoreProduct] = []
//            for remoteProduct in remoteProducts {
//                if let product = products[remoteProduct.productUuid] {
//                    let storeProduct = StoreProductMapper.productWithRemote(remoteProduct, product: product)
//                    dict[remoteProduct.uuid] = storeProduct
//                    arr.append(storeProduct)
//                } else {
//                    logger.e("Got store product with product uuid: \(remoteProduct.productUuid) which is not in the products dict: \(products)")
//                }
//            }
//            return (dict, arr)
        }
        
        func toSectionDict(_ remoteSections: [RemoteSection], lists: [String: List]) -> ([String: Section], [Section]) {
            var dict: [String: Section] = [:]
            var arr: [Section] = []
            for remoteSection in remoteSections {
                if let list = lists[remoteSection.listUuid] {
                    let section = SectionMapper.SectionWithRemote(remoteSection, list: list)
                    dict[remoteSection.uuid] = section
                    arr.append(section)
                } else {
                    logger.e("Got section with list uuid: \(remoteSection.listUuid) which is not in the list dict: \(lists)")
                }
            }
            return (dict, arr)
        }

        let lists = ListMapper.listsWithRemote(remoteListItems.lists)
        let listDict = lists.toDictionary{($0.uuid, $0)}

        let (productsCategoriesDict, _) = toProductCategoryDict(remoteListItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, products) = toProductDict(remoteListItems.products, categories: productsCategoriesDict)
        let (storeProductsDict, storeProducts) = toStoreProductDict(remoteListItems.storeProducts, products: productsDict)
        let (sectionsDict, sections) = toSectionDict(remoteListItems.sections, lists: listDict)

        let remoteListItemsArr = remoteListItems.listItems
        
        let listItems = remoteListItemsArr.map {remoteListItem in
            ListItem(
                uuid: remoteListItem.uuid,
                product: storeProductsDict[remoteListItem.productUuid]!,
                section: sectionsDict[remoteListItem.sectionUuid]!,
                list: listDict[remoteListItem.listUuid]!,
                note: remoteListItem.note,
                todoQuantity: remoteListItem.todoQuantity,
                todoOrder: remoteListItem.todoOrder,
                doneQuantity: remoteListItem.doneQuantity,
                doneOrder: remoteListItem.doneOrder,
                stashQuantity: remoteListItem.stashQuantity,
                stashOrder: remoteListItem.stashOrder,
                lastServerUpdate: remoteListItem.lastUpdate
            )
        }
        
        let maybeSortedItems: [ListItem] = {
            if let sortOrderByStatus = sortOrderByStatus {
                return listItems.sortedByOrder(sortOrderByStatus)
            } else {
                return listItems
            }
        }()
        
        return (
            maybeSortedItems,
            storeProducts,
            products,
            sections
        )
    }
}
