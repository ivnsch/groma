//
//  ProductMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

class ProductMapper {
    
    class func productWithCD(cdProduct:CDProduct) -> Product {
        return Product(
            uuid: cdProduct.uuid,
            name: cdProduct.name,
            price: cdProduct.price.floatValue)
    }
    

    class func productWithDB(dbProduct: DBProduct) -> Product {
        return Product(
            uuid: dbProduct.uuid,
            name: dbProduct.name,
            price: dbProduct.price)
    }
    
    class func ProductWithRemote(remoteProduct: RemoteProduct) -> Product {
        return Product(uuid: remoteProduct.uuid, name: remoteProduct.name, price: remoteProduct.price)
    }
}
