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
            price: dbProduct.price)
    }
    
    class func dbWithProduct(product: Product) -> DBProduct {
        let dbProduct = DBProduct()
        dbProduct.uuid = product.uuid
        dbProduct.name = product.name
        dbProduct.price = product.price
        return dbProduct
    }
    
    class func ProductWithRemote(remoteProduct: RemoteProduct) -> Product {
        return Product(uuid: remoteProduct.uuid, name: remoteProduct.name, price: remoteProduct.price)
    }
}
