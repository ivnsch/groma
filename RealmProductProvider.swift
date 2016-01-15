//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

class RealmProductProvider: RealmProvider {

    // TODO move product methods from RealmListItemProvider here
    
    func categoryWithName(name: String, handler: ProductCategory? -> ()) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        self.loadFirst(mapper, filter: "name = '\(name)'", handler: handler)
    }
    
    func loadCategorySuggestions(handler: [Suggestion] -> ()) {
        // TODO review why section and product suggestion have their own database objects, was it performance, prefill etc? Do we also need this here?
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        self.load(mapper) {dbCategories in
            let suggestions = dbCategories.map{Suggestion(name: $0.name)}
            handler(suggestions)
        }
    }
    
    func incrementFav(product: Product, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let existingProduct = realm.objects(DBProduct).filter("uuid == '\(product.uuid)'").first {
                existingProduct.fav++
                realm.add(existingProduct, update: true)
                return true
            } else { // product not found
                return false
            }
        }, finishHandler: {savedMaybe in
            handler(savedMaybe ?? false)
        })
    }
}