//
//  GroupItemMapper.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class GroupItemMapper {

    class func groupItemWithRemote(_ remoteGroupItem: RemoteGroupItem, product: Product, group: ProductGroup) -> GroupItem {
        return GroupItem(uuid: remoteGroupItem.uuid, quantity: remoteGroupItem.quantity, product: product, group: group)
    }
    
    /**
     Parses the remote group items into model objects
     */
    class func groupItemsWithRemote(_ remoteGroupItems: RemoteGroupItemsWithDependencies) -> GroupItemsWithRelations {
        
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
        
        func toGroupDict(_ remoteSections: [RemoteGroup]) -> ([String: ProductGroup], [ProductGroup]) {
            var dict: [String: ProductGroup] = [:]
            var arr: [ProductGroup] = []
            for remoteSection in remoteSections {
                let group = ProductGroupMapper.listItemGroupWithRemote(remoteSection)
                dict[remoteSection.uuid] = group
                arr.append(group)
            }
            return (dict, arr)
        }
        
        
        
        let (productsCategoriesDict, _) = toProductCategoryDict(remoteGroupItems.productsCategories) // TODO review if productsCategories array is necessary if not remove
        let (productsDict, products) = toProductDict(remoteGroupItems.products, categories: productsCategoriesDict)
        let (groupsDict, groups) = toGroupDict(remoteGroupItems.groups)
        
        let remoteListItemsArr = remoteGroupItems.groupItems
        
        let groupItems: [GroupItem] = remoteListItemsArr.map {remoteListItem in
            let product = productsDict[remoteListItem.productUuid]!
            let group = groupsDict[remoteListItem.groupUuid]!
            
            return GroupItemMapper.groupItemWithRemote(remoteListItem, product: product, group: group)
        }
        
        // TODO
//        let sortedGroupItems: [GroupItem] = groupItems.sortedByOrder()
        
        return (
            groupItems,
            products,
            groups
        )
    }
}
