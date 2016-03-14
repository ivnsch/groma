//
//  RealmProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 21/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift
import QorumLogs

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
    
    func loadProductWithUuid(uuid: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBProduct.createFilter(uuid), handler: handler)
    }
    
    // TODO rename method (uses now brand and store too)
    func loadProductWithName(name: String, brand: String, store: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBProduct.createFilterNameBrand(name, brand: brand, store: store), handler: handler)
    }
    
    func loadProducts(range: NSRange, sortBy: ProductSortBy, handler: [Product] -> ()) {
        products(range: range, sortBy: sortBy) {tuple in
            handler(tuple.products)
        }
    }
    
    func products(substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: (substring: String?, products: [Product]) -> ()) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .Alphabetic: return ("name", true)
            case .Fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{DBProduct.createFilterNameContains($0)}
        let mapper = {ProductMapper.productWithDB($0)}
        self.load(mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range) {products in
            handler(substring: substring, products: products)
        }
    }
    
    func countProducts(handler: Int? -> Void) {
        withRealm({realm in
            realm.objects(DBProduct).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }
    
    func deleteProductAndDependencies(product: Product, markForSync: Bool, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductAndDependenciesSync(realm, productUuid: product.uuid, markForSync: markForSync)
            } else {
                print("WARN: RealmListItemProvider.deleteProductAndDependencies: self is nil")
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductAndDependenciesSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        if deleteProductDependenciesSync(realm, productUuid: productUuid, markForSync: markForSync) {
            if let productResult = realm.objects(DBProduct).filter(DBProduct.createFilter(productUuid)).first {
                realm.delete(productResult)
                if markForSync {
                    let toRemove = DBProductToRemove(productResult)
                    realm.add(toRemove, update: true)
                }
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductDependenciesSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        let listItemResult = realm.objects(DBListItem).filter(DBListItem.createFilterWithProduct(productUuid))
        realm.delete(listItemResult)
        if markForSync {
            let toRemoveListItems = listItemResult.map{DBRemoveListItem($0)}
            saveObjsSyncInt(realm, objs: toRemoveListItems, update: true)
        }
        
        let inventoryResult = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterWithProduct(productUuid))
        realm.delete(inventoryResult)
        if markForSync {
            let toRemoteInventoryItems = inventoryResult.map{DBRemoveInventoryItem($0)}
            saveObjsSyncInt(realm, objs: toRemoteInventoryItems, update: true)
        }
        
        let historyResult = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilterWithProduct(productUuid))
        realm.delete(historyResult)
        if markForSync {
            let toRemoteHistoryItems = historyResult.map{DBRemoveHistoryItem($0)}
            saveObjsSyncInt(realm, objs: toRemoteHistoryItems, update: true)
        }
        
        let planResult = realm.objects(DBPlanItem).filter(DBPlanItem.createFilterWithProduct(productUuid))
        realm.delete(planResult)
        if markForSync {
            // TODO plan items either complete or remove this table entirely
        }
        
        return true
    }
    
    func saveProduct(productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: Product? -> ()) {
        
        loadProductWithName(productInput.name, brand: productInput.brand, store: productInput.store) {[weak self] productMaybe in
            
            if productMaybe.isSet && !update {
                print("Product with name: \(productInput.name), already exists, no update")
                handler(nil)
                return
            }
            
            let uuid: String = {
                if let existingProduct = productMaybe { // since realm doesn't support unique besides primary key yet, we have to fetch first possibly existing product
                    return existingProduct.uuid
                } else {
                    return NSUUID().UUIDString
                }
            }()
            
            Providers.productCategoryProvider.categoryWithName(productInput.category) {result in
                
                if result.status == .Success || result.status == .NotFound  {
                    
                    // Create a new category or update existing one
                    let category: ProductCategory? = {
                        if let existingCategory = result.sucessResult {
                            return existingCategory.copy(name: productInput.category, color: productInput.categoryColor)
                        } else if result.status == .NotFound {
                            return ProductCategory(uuid: NSUUID().UUIDString, name: productInput.category, color: productInput.categoryColor)
                        } else {
                            print("Error: RealmListItemProvider.saveProductError, invalid state: status is .Success but there is not successResult")
                            return nil
                        }
                    }()
                    
                    // Save product with new/updated category
                    if let category = category {
                        let product = Product(uuid: uuid, name: productInput.name, price: productInput.price, category: category, baseQuantity: productInput.baseQuantity, unit: productInput.unit, brand: productInput.brand)
                        self?.saveProducts([product]) {saved in
                            if saved {
                                handler(product)
                            } else {
                                print("Error: RealmListItemProvider.saveProductError, could not save product: \(product)")
                                handler(nil)
                            }
                        }
                    } else {
                        print("Error: RealmListItemProvider.saveProduct, category is nill")
                        handler(nil)
                    }
                    
                } else {
                    print("Error: RealmListItemProvider.saveProduct, couldn't fetch category: \(result)")
                    handler(nil)
                }
            }
        }
    }
    
    func saveProducts(products: [Product], updateSuggestions: Bool = true, update: Bool = true, handler: Bool -> ()) {
        
        for product in products { // product marked as var to be able to update uuid
            
            doInWriteTransaction({[weak self] realm in
                let dbProduct = ProductMapper.dbWithProduct(product)
                realm.add(dbProduct, update: update)
                if updateSuggestions {
                    self?.saveProductSuggestionHelper(realm, product: product)
                }
                return true
                
                }, finishHandler: {success in
                    handler(success ?? false)
            })
        }
    }
    
    // TODO!!!! do we still need this?
    // MARK: - Suggestion
    
    func loadProductSuggestions(handler: [Suggestion] -> ()) {
        let mapper = {ProductSuggestionMapper.suggestionWithDB($0)}
        self.load(mapper, handler: handler)
    }

    
    //    /**
    //    Helper to save a list item with optional saving of product and section autosuggestion
    //    Expected to be executed inside a transaction
    //    */
    //    private func saveListItemHelper(realm: Realm, listItem: ListItem, updateSuggestions: Bool = true) {
    //        let dbListItem = ListItemMapper.dbWithListItem(listItem)
    //        realm.add(dbListItem, update: true)
    //
    //        if updateSuggestions {
    //            saveProductSuggestionHelper(realm, product: listItem.product)
    //
    //            let sectionSuggestion = SectionSuggestionMapper.dbWithSection(listItem.section)
    //            realm.add(sectionSuggestion, update: true)
    //        }
    //    }
    
    /**
    Helper to save suggestion corresponding to a product
    Expected to be executed in a write block
    */
    func saveProductSuggestionHelper(realm: Realm, product: Product) {
        // TODO update suggestions - right now only insert - product is updated based on uuid, but with autosuggestion, since no ids old names keep there
        // so we need to either do a query for the product/old name, and delete the autosuggestion with this name or use ids
        let suggestion = ProductSuggestionMapper.dbWithProduct(product)
        realm.add(suggestion, update: true)
    }
    
    // TODO: -
    
    func categoriesContaining(text: String, handler: [String] -> Void) {
        let mapper: DBProduct -> String = {$0.category.name}
        self.load(mapper, filter: DBProduct.createFilterCategoryNameContains(text)) {categories in
            let distinctCategories = NSOrderedSet(array: categories).array as! [String] // TODO re-check: Realm can't distinct yet https://github.com/realm/realm-cocoa/issues/1103
            handler(distinctCategories)
        }
    }
    
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
    
    // MARK: - Sync
    
    func clearProductTombstone(uuid: String, handler: Bool -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(DBProductToRemove.self, DBProductToRemove.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    
    func updateLastSyncTimeStampSync(realm: Realm, product: RemoteProduct) {
        realm.create(DBProduct.self, value: product.timestampUpdateDict, update: true)
    }
}