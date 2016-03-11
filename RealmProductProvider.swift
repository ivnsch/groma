//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

// TODO put these structs somewhere else

struct ProductUnique {
    let name: String
    let brand: String
    let store: String
    
    init(name: String, brand: String, store: String) {
        self.name = name
        self.brand = brand
        self.store = store
    }
}

struct ProductPrototype {
    let name: String
    let price: Float
    let category: String
    let categoryColor: UIColor
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    let store: String
    
    init(name: String, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.name = name
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
}

class RealmProductProvider: RealmProvider {
    
    // TODO move product methods from RealmListItemProvider here
    
    func productWithUniqueSync(realm: Realm, name: String, brand: String, store: String) -> DBProduct? {
        return realm.objects(DBProduct).filter(DBProduct.createFilterNameBrand(name, brand: brand, store: store)).first
    }
    
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

    ///////////////////////////////////////////////////////////////////////////////////////
    // WARN: This is only used for generating prefill database so no tombstones
    ///////////////////////////////////////////////////////////////////////////////////////
    
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
    
    ///////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    
    func overwriteProducts(dbProducts: [DBProduct], clearTombstones: Bool, handler: Bool -> Void) {
        let additionalActions: (Realm -> Void)? = clearTombstones ? {realm in realm.deleteAll(DBProductToRemove)} : nil
        self.overwrite(dbProducts, resetLastUpdateToServer: true, additionalActions: additionalActions, handler: handler)
    }
    
    /**
     * Performs an upsert using a product prototype.
     * This will insert a new product if there's no product with the prototype's unique (name+brand+store). Otherwise it updates the existing one.
     * Analogously for the category, inserts a new one if no one exists with the prototype's category name, or updates the existing one.
     * Ensures that the product points to the correct category which can be 1. The same which already was referenced by the product, if the product exists and the category name is unchanged, 2. An existing category which was not referenced by the product (input category name is different than the name of the category referenced by the existing product), 3. A new category, if no category with prototype's category name exists yet.
     */
    func upsertProductSync(realm: Realm, prototype: ProductPrototype) -> DBProduct {
        
        func findOrCreateCategory(realm: Realm, prototype: ProductPrototype) -> DBProductCategory {
            return realm.objects(DBProductCategory).filter(DBProductCategory.createFilterName(prototype.category)).first ?? DBProductCategory(uuid: NSUUID().UUIDString, name: prototype.name, bgColorHex: prototype.categoryColor.hexStr)
        }
        
        func categoryForExistingProduct(existingProduct: DBProduct, prototype: ProductPrototype) -> DBProductCategory {
            // Make the updated product point to correct category - if category name hasn't changed, no pointer update. If input category name is different, see if a category with this name already exists, and update pointer. Otherwise create a new category and udpate pointer.
            if existingProduct.category.name != prototype.category {
                return findOrCreateCategory(realm, prototype:  prototype)
            } else {
                return existingProduct.category
            }
        }
        
        func updateExistingProduct(realm: Realm, existingProduct: DBProduct, prototype: ProductPrototype) -> DBProduct {
            
            let category = categoryForExistingProduct(existingProduct, prototype: prototype)
            let updatedCategory = category.copy(bgColorHex: prototype.categoryColor.hexStr)
            
            // Udpate product fields
            let updatedProduct = existingProduct.update(prototype)
            updatedProduct.category = updatedCategory
            
            realm.add(updatedProduct, update: true)
            
            return updatedProduct
        }
        
        func insertNewProduct(realm: Realm, prototype: ProductPrototype) -> DBProduct {
            let category = findOrCreateCategory(realm, prototype: prototype)
            let newProduct = DBProduct(prototype: prototype, category: category)
            realm.add(newProduct, update: false)
            return newProduct
        }
        
        if let existingProduct = realm.objects(DBProduct).filter(DBProduct.createFilterUnique(prototype)).first {
            return updateExistingProduct(realm, existingProduct: existingProduct, prototype: prototype)
        } else {
            return insertNewProduct(realm, prototype: prototype)
        }
    }
}