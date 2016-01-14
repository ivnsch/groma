//
//  ListItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ListItemMapper {
    
    class func listItemWithDB(dbListItem: DBListItem) -> ListItem {
        let product = ProductMapper.productWithDB(dbListItem.product)
        let section = SectionMapper.sectionWithDB(dbListItem.section)
        let list = ListMapper.listWithDB(dbListItem.list)
        return ListItem(
            uuid: dbListItem.uuid,
            product: product,
            section: section,
            list: list,
            note: dbListItem.note,
            todoQuantity: dbListItem.todoQuantity,
            todoOrder: dbListItem.todoOrder,
            doneQuantity: dbListItem.doneQuantity,
            doneOrder: dbListItem.doneOrder,
            stashQuantity: dbListItem.stashQuantity,
            stashOrder: dbListItem.stashOrder
        )
    }
    
    class func dbWithListItem(listItem: ListItem) -> DBListItem {
        let dbListItem = DBListItem()
        dbListItem.uuid = listItem.uuid
        dbListItem.note = listItem.note ?? "" // TODO check if db obj can have optional if yes remove ??

        dbListItem.todoQuantity = listItem.todoQuantity
        dbListItem.todoOrder = listItem.todoOrder
        dbListItem.doneQuantity = listItem.doneQuantity
        dbListItem.doneOrder = listItem.doneOrder
        dbListItem.stashQuantity = listItem.stashQuantity
        dbListItem.stashOrder = listItem.stashOrder
        
        dbListItem.product = ProductMapper.dbWithProduct(listItem.product)
        dbListItem.section = SectionMapper.dbWithSection(listItem.section)
        dbListItem.list = ListMapper.dbWithList(listItem.list)
        
        dbListItem.lastUpdate = listItem.lastUpdate
        if let lastServerUpdate = listItem.lastServerUpdate { // needs if let because Realm doesn't support optional NSDate yet
            dbListItem.lastServerUpdate = lastServerUpdate
        }
        return dbListItem
    }
    
    /**
    Parses the remote list items into model objects
    Note that the list items are sorted here by order field. The backend doesn't do this.
    */
    class func listItemsWithRemote(remoteListItems: RemoteListItems) -> ListItemsWithRelations {

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
        
        func toSectionDict(remoteSections: [RemoteSection]) -> ([String: Section], [Section]) {
            var dict: [String: Section] = [:]
            var arr: [Section] = []
            for remoteSection in remoteSections {
                let section = SectionMapper.SectionWithRemote(remoteSection)
                dict[remoteSection.uuid] = section
                arr.append(section)
            }
            return (dict, arr)
        }

        let lists = ListMapper.listsWithRemote(remoteListItems.lists)
        let listDict = lists.toDictionary{($0.uuid, $0)}

        let (productsCategoriesDict, _) = toProductCategoryDict(remoteListItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, products) = toProductDict(remoteListItems.products, categories: productsCategoriesDict)
        let (sectionsDict, sections) = toSectionDict(remoteListItems.sections)

        let remoteListItemsArr = remoteListItems.listItems
        
        let listItems = remoteListItemsArr.map {remoteListItem in
            ListItem(
                uuid: remoteListItem.uuid,
                product: productsDict[remoteListItem.productUuid]!,
                section: sectionsDict[remoteListItem.sectionUuid]!,
                list: listDict[remoteListItem.listUuid]!,
                note: remoteListItem.note,
                todoQuantity: remoteListItem.todoQuantity,
                todoOrder: remoteListItem.todoOrder,
                doneQuantity: remoteListItem.doneQuantity,
                doneOrder: remoteListItem.doneOrder,
                stashQuantity: remoteListItem.stashQuantity,
                stashOrder: remoteListItem.stashOrder
            )
        }
        
        let sortedListItems = listItems.sortedByOrder()

        return (
            sortedListItems,
            products,
            sections
        )
    }
}
