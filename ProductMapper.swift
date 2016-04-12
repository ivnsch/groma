//
//  ProductMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ProductMapper {

    class func productWithDB(dbProduct: DBProduct) -> Product {
        return Product(
            uuid: dbProduct.uuid,
            name: dbProduct.name,
            category: ProductCategoryMapper.categoryWithDB(dbProduct.category),
            fav: dbProduct.fav,
            brand: dbProduct.brand,
            lastServerUpdate: dbProduct.lastServerUpdate
        )
    }
    
    class func dbWithProduct(product: Product) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.category = ProductCategoryMapper.dbWithCategory(product.category)
        dbProduct.fav = product.fav
        dbProduct.brand = product.brand
        if let lastServerUpdate = product.lastServerUpdate {
            dbProduct.lastServerUpdate = lastServerUpdate
        }
        return dbProduct
    }
    
    class func productWithRemote(remoteProduct: RemoteProduct, categoriesDict: [String: RemoteProductCategory]) -> Product? {
        if let category = categoriesDict[remoteProduct.uuid] {
            return productWithRemote(remoteProduct, category: ProductCategoryMapper.categoryWithRemote(category))
        } else {
            print("Error: ProductMapper.productWithRemote: Got product with category uuid: \(remoteProduct.categoryUuid) which is not in the category dict: \(categoriesDict)")
            return nil
        }
    }
    
    class func productWithRemote(remoteProduct: RemoteProduct, category: RemoteProductCategory) -> Product {
        return productWithRemote(remoteProduct, category: ProductCategoryMapper.categoryWithRemote(category))
    }
    
    class func productWithRemote(remoteProduct: RemoteProduct, category: ProductCategory) -> Product {
        return Product(
            uuid: remoteProduct.uuid,
            name: remoteProduct.name,
            category: category,
            fav: remoteProduct.fav,
            brand: remoteProduct.brand,
            lastServerUpdate: remoteProduct.lastUpdate
        )
    }
    
    class func dbProductWithRemote(product: RemoteProduct, category: RemoteProductCategory) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.category = ProductCategoryMapper.dbCategoryWithRemote(category)
        dbProduct.fav = product.fav
        dbProduct.brand = product.brand
        dbProduct.dirty = false
        dbProduct.lastServerUpdate = product.lastUpdate
        return dbProduct
    }
    
    class func listItemsWithRemote(remoteListItems: RemoteProductsWithDependencies) -> [Product] {
        
        let productsCategoriesDict: [String: RemoteProductCategory] = remoteListItems.categories.toDictionary{($0.uuid, $0)}
        
        let products = remoteListItems.products.map {remoteProduct in
            productWithRemote(remoteProduct, category: productsCategoriesDict[remoteProduct.categoryUuid]!)
        }
        
        return products
    }
    
    class func dbListItemsWithRemote(remoteListItems: RemoteProductsWithDependencies) -> [DBProduct] {
        
        let productsCategoriesDict: [String: RemoteProductCategory] = remoteListItems.categories.toDictionary{($0.uuid, $0)}
        
        let products = remoteListItems.products.map {remoteProduct in
            dbProductWithRemote(remoteProduct, category: productsCategoriesDict[remoteProduct.categoryUuid]!)
        }
        
        return products
    }
    
    class func productsWithRemote(remoteProducts: RemoteProductsWithDependencies) -> ProductsWithDependencies {
        
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
        
        
        let (productsCategoriesDict, categories) = toProductCategoryDict(remoteProducts.categories)
        
        let remoteListItemsArr = remoteProducts.products
        
        let products: [Product] = remoteListItemsArr.map {remoteProduct in
            let category = productsCategoriesDict[remoteProduct.categoryUuid]!
            return productWithRemote(remoteProduct, category: category)
        }
        
        return (
            products,
            categories
        )
    }
}
