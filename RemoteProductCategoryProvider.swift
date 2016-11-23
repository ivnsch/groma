//
//  RemoteProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 02/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

class RemoteProductCategoryProvider {
    
    func categories(_ handler: @escaping (RemoteResult<[RemoteProductCategory]>) -> ()) {
        RemoteProvider.authenticatedRequestArray(.get, Urls.productCategories) {result in
            handler(result)
        }
    }
    
    func addCategory(_ category: ProductCategory, handler: @escaping (RemoteResult<RemoteProductCategory>) -> ()) {
        let params = RemoteListItemProvider().toRequestParams(category)
        RemoteProvider.authenticatedRequest(.post, Urls.productCategory, params) {result in
            handler(result)
        }
    }
    
    func updateCategory(_ category: ProductCategory, handler: @escaping (RemoteResult<RemoteProductCategory>) -> ()) {
        let params = RemoteListItemProvider().toRequestParams(category)
        RemoteProvider.authenticatedRequest(.put, Urls.productCategory, params) {result in
            handler(result)
        }
    }
    
    func removeCategory(_ uuid: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        RemoteProvider.authenticatedRequest(.delete, Urls.productCategory + "/\(uuid)") {result in
            handler(result)
        }
    }
    
    func removeCategoriesWithName(_ name: String, handler: @escaping (RemoteResult<NoOpSerializable>) -> ()) {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        RemoteProvider.authenticatedRequest(.delete, Urls.productCategoriesName + "/\(encodedName)") {result in
            handler(result)
        }
    }
}
