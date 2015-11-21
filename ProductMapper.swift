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
            unit: ProductUnit(rawValue: dbProduct.unit)!
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
        return dbProduct
    }
    
    class func ProductWithRemote(remoteProduct: RemoteProduct) -> Product {
        return Product(
            uuid: remoteProduct.uuid,
            name: remoteProduct.name,
            price: remoteProduct.price,
            category: ProductCategoryMapper.categoryWithRemote(remoteProduct.category),
            baseQuantity: remoteProduct.baseQuantity,
            unit: ProductUnit(rawValue: remoteProduct.unit)!
        )
    }
    
    class func dbProductWithRemote(product: RemoteProduct) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.price = product.price
        dbProduct.category = ProductCategoryMapper.dbCategoryWithRemote(product.category)
        dbProduct.baseQuantity = product.baseQuantity
        dbProduct.unit = product.unit
        return dbProduct
    }
}
