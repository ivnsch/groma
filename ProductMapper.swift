//
//  ProductMapper.swift
//  shoppin
//
//  Created by ischuetz on 14.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

class ProductMapper {
    
    class func productWithCD(cdProduct:CDProduct) -> Product {
        let id = cdProduct.objectID.URIRepresentation().absoluteString
        return Product(
            id: id!,
            name: cdProduct.name,
            price: cdProduct.price.floatValue)
    }
}
