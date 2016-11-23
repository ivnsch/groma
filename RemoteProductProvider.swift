//
//  RemoteProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 01/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteProductProvider: RemoteProvider {
    
    func products(_ handler: @escaping (RemoteResult<[RemoteProduct]>) -> ()) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.products) {result in
            handler(result)
        }
    }
    
    func addProduct(_ product: Product, handler: @escaping (RemoteResult<RemoteProduct>) -> ()) {
        let params = RemoteListItemProvider().toRequestParams(product)
        RemoteProvider.authenticatedRequest(.post, Urls.product, params) {result in
            handler(result)
        }
    }
    
    func updateProduct(_ product: Product, handler: @escaping (RemoteResult<RemoteProduct>) -> ()) {
        let params = RemoteListItemProvider().toRequestParams(product)
        RemoteProvider.authenticatedRequest(.put, Urls.product, params) {result in
            handler(result)
        }
    }

    func incrementFav(_ productUuid: String, handler: @escaping (RemoteResult<RemoteProduct>) -> ()) {
        RemoteProvider.authenticatedRequest(.put, Urls.favProduct + "/\(productUuid)") {result in
            handler(result)
        }
    }
    
    func deleteProduct(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.product + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func deleteProductsWithBrand(_ brandName: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let encodedName = brandName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        RemoteProvider.authenticatedRequest(.delete, Urls.brand + "/\(encodedName)") {result in
            handler(result)
        }
    }
}
