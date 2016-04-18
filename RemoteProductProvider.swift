//
//  RemoteProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 01/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteProductProvider: RemoteProvider {
    
    func products(handler: RemoteResult<[RemoteProduct]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.products) {result in
            handler(result)
        }
    }
    
    func addProduct(product: Product, handler: RemoteResult<RemoteProduct> -> ()) {
        let params = RemoteListItemProvider().toRequestParams(product)
        RemoteProvider.authenticatedRequest(.POST, Urls.product, params) {result in
            handler(result)
        }
    }
    
    func updateProduct(product: Product, handler: RemoteResult<RemoteProduct> -> ()) {
        let params = RemoteListItemProvider().toRequestParams(product)
        RemoteProvider.authenticatedRequest(.PUT, Urls.product, params) {result in
            handler(result)
        }
    }

    func incrementFav(productUuid: String, handler: RemoteResult<RemoteProduct> -> ()) {
        RemoteProvider.authenticatedRequest(.PUT, Urls.favProduct + "/\(productUuid)") {result in
            handler(result)
        }
    }
    
    func deleteProduct(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.product + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func deleteProductsWithBrand(brandName: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.brand + "/\(brandName)") {result in
            handler(result)
        }
    }
}
