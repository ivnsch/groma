//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmProductProvider: RealmProvider {

    // TODO move product methods from RealmListItemProvider here
    
    func categoryWithName(name: String, handler: ProductCategory? -> ()) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        self.loadFirst(mapper, filter: DBProductCategory.createFilterName(name), handler: handler)
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
            if let existingProduct = realm.objects(DBProduct).filter(DBProduct.createFilter(product.uuid)).first {
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
    
    func save(categories: [ProductCategory], products: [Product], _ handler: Bool -> Void) {
        
        let dbCategories = categories.map{ProductCategoryMapper.dbWithCategory($0)}
        let dbProducts = products.map{ProductMapper.dbWithProduct($0)}
        
        doInWriteTransaction({realm in
            for dbCategory in dbCategories {
//                print("saving cat: \(dbCategory.uuid)")
                realm.add(dbCategory, update: false)
            }
            for dbProduct in dbProducts {
//                print("saving prod: \(dbProduct.uuid)")
                realm.add(dbProduct, update: true) // update: true: apparently the product tries to save again its category and with update: false this results in a duplicate (category) uuid exception!
            }
            return true
            
            }, finishHandler: {(savedMaybe: Bool?) in
                let saved: Bool = savedMaybe.map{$0} ?? false
                if !saved {
                    print("Error: RealmProductProvider.save: couldn't save")
                }
                handler(saved)
        })
    }
    
    func removeAllCategories(handler: Bool -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllCategories: couldn't remove categories")
            }
            handler(success)
        }, objType: DBProductCategory.self)
    }

    func removeAllProducts(handler: Bool -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllProducts: couldn't remove products")
            }
            handler(success)
        }, objType: DBProduct.self)
    }
    
    // Removes all products and categories
    func removeAllProductsAndCategories(handler: Bool -> Void) {
        removeAllProducts {[weak self] success in
            if let weakSelf = self {
                weakSelf.removeAllCategories {success in
                    handler(success)
                }
            } else {
                print("Error: RealmProductProvider.removeAllProductsAndCategories: weakSelf is nil")
                handler(false)
            }

        }
    }
}