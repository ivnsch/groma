//
//  ProductProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO move product-only method from list item provider here
class ProductProviderImpl: ProductProvider {

    let dbProvider = RealmListItemProvider()

    // TODO pagination
    func products(handler: ProviderResult<[Product]> -> Void) {
        dbProvider.loadProducts {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
}
