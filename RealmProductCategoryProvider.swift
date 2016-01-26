//
//  RealmProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmProductCategoryProvider: RealmProvider {
    
    func categories(range: NSRange, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, range: range, handler: handler)
    }
    
    func categoriesContainingText(text: String, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: "name CONTAINS[c] '\(text)'", handler: handler)
    }
    
    func updateCategory(category: ProductCategory, _ handler: Bool -> Void) {
        let dbCategory = ProductCategoryMapper.dbWithCategory(category)
        saveObj(dbCategory, update: true, handler: handler)
    }
    
    func removeCategory(category: ProductCategory, _ handler: Bool -> Void) {
        background({
            do {
                let realm = try Realm()
                realm.write {
                    let dbProducts = realm.objects(DBProduct).filter("category.uuid = '\(category.uuid)'")
                    // delete first dependencies of products (realm requires this order, otherwise db is inconsistent. There's no cascade delete yet also).
                    for dbProduct in dbProducts {
                        RealmListItemProvider().deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid)
                    }
                    // delete products
                    realm.delete(dbProducts)
                    // delete cateogories
                    let categoryResults = realm.objects(DBProductCategory).filter("uuid = '\(category.uuid)'")
                    realm.delete(categoryResults)
                }
                return true
            } catch _ {
                print("Error: RealmProductCategoryProvider.removeCategory: creating Realm() in remove")
                return false
            }
        }) {(result: Bool) in
            handler(result)
        }
    }
}
