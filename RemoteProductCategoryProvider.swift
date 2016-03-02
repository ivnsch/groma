//
//  RemoteProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteProductCategoryProvider {
    
    func categories(handler: RemoteResult<[RemoteProductCategory]> -> ()) {
        RemoteProvider.authenticatedRequestArray(.GET, Urls.productCategories) {result in
            handler(result)
        }
    }
    
    func addCategory(category: ProductCategory, handler: RemoteResult<RemoteProductCategory> -> ()) {
        let params = RemoteListItemProvider().toRequestParams(category)
        RemoteProvider.authenticatedRequest(.POST, Urls.productCategory, params) {result in
            handler(result)
        }
    }
    
    func updateCategory(category: ProductCategory, handler: RemoteResult<RemoteProductCategory> -> ()) {
        let params = RemoteListItemProvider().toRequestParams(category)
        RemoteProvider.authenticatedRequest(.PUT, Urls.productCategory, params) {result in
            handler(result)
        }
    }
    
    func removeCategory(uuid: String, handler: RemoteResult<NoOpSerializable> -> ()) {
        RemoteProvider.authenticatedRequest(.DELETE, Urls.productCategory + "/\(uuid)") {result in
            handler(result)
        }
    }
}
