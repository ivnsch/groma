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
            price: dbProduct.price,
            category: ProductCategoryMapper.categoryWithDB(dbProduct.category),
            baseQuantity: dbProduct.baseQuantity,
            unit: ProductUnit(rawValue: dbProduct.unit)!,
            fav: dbProduct.fav
        )
    }
    
    class func dbWithProduct(product: Product) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.price = product.price
        dbProduct.category = ProductCategoryMapper.dbWithCategory(product.category)
        dbProduct.baseQuantity = product.baseQuantity
        dbProduct.unit = product.unit.rawValue
        dbProduct.fav = product.fav
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
            price: remoteProduct.price,
            category: category,
            baseQuantity: remoteProduct.baseQuantity,
            unit: ProductUnit(rawValue: remoteProduct.unit)!,
            fav: remoteProduct.fav
        )
    }
    
    class func dbProductWithRemote(product: RemoteProduct, category: RemoteProductCategory) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.price = product.price
        dbProduct.category = ProductCategoryMapper.dbCategoryWithRemote(category)
        dbProduct.baseQuantity = product.baseQuantity
        dbProduct.unit = product.unit
        dbProduct.fav = product.fav
        return dbProduct
    }
}
