//
//  StoreProductMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class StoreProductMapper {
    
//    class func productWithRemote(remoteProduct: RemoteStoreProduct, productsDict: [String: RemoteProduct]) -> StoreProduct? {
//        if let product = productsDict[remoteProduct.uuid] {
//            return productWithRemote(remoteProduct, category: ProductMapper.productWithRemote(productsDict))
//        } else {
//            QL4("Got product with product uuid: \(remoteProduct.productUuid) which is not in the category dict: \(productsDict)")
//            return nil
//        }
//    }
//    
//    class func productWithRemote(remoteProduct: RemoteStoreProduct, product: RemoteProduct) -> StoreProduct {
//        return productWithRemote(remoteProduct, product: ProductMapper.productWithRemote(product))
//    }
    
    class func productWithRemote(_ storeProduct: RemoteStoreProduct, product: Product) -> StoreProduct {
        return StoreProduct(
            uuid: storeProduct.uuid,
            price: storeProduct.price,
            baseQuantity: storeProduct.baseQuantity,
            unit: StoreProductUnit(rawValue: storeProduct.unit)!,
            store: storeProduct.store,
            product: product,
            lastServerUpdate: storeProduct.lastUpdate
        )
    }
    
//    class func dbProductWithRemote(storeProduct: RemoteStoreProduct, product: RemoteProduct) -> StoreProduct {
//        let dbProduct = StoreProduct()
//        dbProduct.uuid = storeProduct.uuid
//        dbProduct.price = storeProduct.price
//        dbProduct.product = ProductMapper.productWithRemote(product)
//        dbProduct.baseQuantity = storeProduct.baseQuantity
//        dbProduct.unit = storeProduct.unit
//        dbProduct.store = storeProduct.store
//        dbProduct.dirty = false
//        return dbProduct
//    }
    
//    class func listItemsWithRemote(remoteListItems: RemoteProductsWithDependencies) -> [Product] {
//        
//        let productsCategoriesDict: [String: RemoteProductCategory] = remoteListItems.categories.toDictionary{($0.uuid, $0)}
//        
//        let products = remoteListItems.products.map {remoteProduct in
//            productWithRemote(remoteProduct, category: productsCategoriesDict[remoteProduct.categoryUuid]!)
//        }
//        
//        return products
//    }
    
//    class func dbListItemsWithRemote(remoteListItems: RemoteProductsWithDependencies) -> [Product] {
//        
//        let productsCategoriesDict: [String: RemoteProductCategory] = remoteListItems.categories.toDictionary{($0.uuid, $0)}
//        
//        let products = remoteListItems.products.map {remoteProduct in
//            dbProductWithRemote(remoteProduct, category: productsCategoriesDict[remoteProduct.categoryUuid]!)
//        }
//        
//        return products
//    }
    
//    class func productsWithRemote(remoteProducts: RemoteProductsWithDependencies) -> ProductsWithDependencies {
//        
//        func toProductCategoryDict(remoteProductsCategories: [RemoteProductCategory]) -> ([String: ProductCategory], [ProductCategory]) {
//            var dict: [String: ProductCategory] = [:]
//            var arr: [ProductCategory] = []
//            for remoteProductCategory in remoteProductsCategories {
//                let category = ProductCategoryMapper.categoryWithRemote(remoteProductCategory)
//                dict[remoteProductCategory.uuid] = category
//                arr.append(category)
//                
//            }
//            return (dict, arr)
//        }
//        
//        
//        let (productsCategoriesDict, categories) = toProductCategoryDict(remoteProducts.categories)
//        
//        let remoteListItemsArr = remoteProducts.products
//        
//        let products: [Product] = remoteListItemsArr.map {remoteProduct in
//            let category = productsCategoriesDict[remoteProduct.categoryUuid]!
//            return productWithRemote(remoteProduct, category: category)
//        }
//        
//        return (
//            products,
//            categories
//        )
//    }
}
