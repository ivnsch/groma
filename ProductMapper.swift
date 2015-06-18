//
//  ProductMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ProductMapper {
    
    class func productWithCD(cdProduct:CDProduct) -> Product {
        return Product(
            id: cdProduct.id,
            name: cdProduct.name,
            price: cdProduct.price.floatValue)
    }
    
    
    class func ProductWithRemote(remoteProduct: RemoteProduct) -> Product {
        return Product(id: remoteProduct.id, name: remoteProduct.name, price: remoteProduct.price)
    }
}
