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
    
    init(name: String, brand: String) {
        self.name = name
        self.brand = brand
    }
}

struct ProductPrototype {
    let name: String
    let category: String
    let categoryColor: UIColor
    let brand: String
    
    init(name: String, category: String, categoryColor: UIColor, brand: String) {
        self.name = name
        self.category = category
        self.categoryColor = categoryColor
        self.brand = brand
    }
}

struct StoreProductUnique {
    let name: String
    let brand: String
    let store: String
    
    init(name: String, brand: String, store: String) {
        self.name = name
        self.brand = brand
        self.store = store
    }
}

class RealmProductProvider: RealmProvider {
    
    func loadProductWithUuid(uuid: String, handler: Product? -> ()) {
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBProduct.createFilter(uuid), handler: handler)
    }
    
    // TODO rename method (uses now brand too)
    func loadProductWithName(name: String, brand: String, handler: Product? -> ()) {
        
        let mapper = {ProductMapper.productWithDB($0)}
        self.loadFirst(mapper, filter: DBProduct.createFilterNameBrand(name, brand: brand), handler: handler)
        
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

    func productsWithPosibleSections(substring: String? = nil, list: List, range: NSRange? = nil, sortBy: ProductSortBy, handler: (substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)]?) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .Alphabetic: return ("name", true)
            case .Fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{DBProduct.createFilterNameContains($0)}
        let mapper = {ProductMapper.productWithDB($0)}
        
        // Note that we are load the sections from db for each range - this could be optimised (load sections only once for all pages) but it shouldn't be an issue since usually there are not a lot of sections and it's performing well.
        
        withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
            let products = weakSelf.loadSync(realm, mapper: mapper, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
            
            let categoryNames = products.map{$0.category.name}.distinct()
        
            let sectionsDict: [String: DBSection] = realm.objects(DBSection).filter(DBSection.createFilterWithNames(categoryNames, listUuid: list.uuid)).toDictionary{($0.name, $0)}
            
            let productsWithMaybeSections: [(product: Product, section: Section?)] = products.map {product in
                let sectionMaybe = sectionsDict[product.category.name].map{SectionMapper.sectionWithDB($0)}
                return (product, sectionMaybe)
            }

            return productsWithMaybeSections
            
        }, resultHandler: {(productsWithMaybeSections: [(product: Product, section: Section?)]?) in
            handler(substring: substring, productsWithMaybeSections: productsWithMaybeSections)
        })
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
    
    func deleteProductAndDependencies(productUuid: String, markForSync: Bool, handler: Bool -> Void) {
        doInWriteTransaction({[weak self] realm in
            if let weakSelf = self {
                return weakSelf.deleteProductAndDependenciesSync(realm, productUuid: productUuid, markForSync: markForSync)
            } else {
                print("WARN: RealmListItemProvider.deleteProductAndDependencies: self is nil")
                return false
            }
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    func deleteProductAndDependencies(product: Product, markForSync: Bool, handler: Bool -> Void) {
        deleteProductAndDependencies(product.uuid, markForSync: markForSync, handler: handler)
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductAndDependenciesSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        if let productResult = realm.objects(DBProduct).filter(DBProduct.createFilter(productUuid)).first {
            return deleteProductAndDependenciesSync(realm, dbProduct: productResult, markForSync: markForSync)
        } else {
            return false
        }
    }
    
    func deleteProductAndDependenciesSync(realm: Realm, dbProduct: DBProduct, markForSync: Bool) -> Bool {
        if deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync) {
            if markForSync {
                let toRemove = DBProductToRemove(dbProduct)
                realm.add(toRemove, update: true)
            }
            realm.delete(dbProduct)
            return true
        } else {
            return false
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductDependenciesSync(realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        
        DBProviders.storeProductProvider.deleteStoreProductsAndDependenciesForProductSync(realm, productUuid: productUuid, markForSync: markForSync)
        
        DBProviders.groupItemProvider.removeGroupItemsForProductSync(realm, productUuid: productUuid, markForSync: markForSync)
        
        let inventoryResult = realm.objects(DBInventoryItem).filter(DBInventoryItem.createFilterWithProduct(productUuid))
        if markForSync {
            let toRemoteInventoryItems = inventoryResult.map{DBRemoveInventoryItem($0)}
            saveObjsSyncInt(realm, objs: toRemoteInventoryItems, update: true)
        }
        realm.delete(inventoryResult)
        
        let historyResult = realm.objects(DBHistoryItem).filter(DBHistoryItem.createFilterWithProduct(productUuid))
        if markForSync {
            let toRemoteHistoryItems = historyResult.map{DBRemoveHistoryItem($0)}
            saveObjsSyncInt(realm, objs: toRemoteHistoryItems, update: true)
        }
        realm.delete(historyResult)
        
        let planResult = realm.objects(DBPlanItem).filter(DBPlanItem.createFilterWithProduct(productUuid))
        if markForSync {
            // TODO plan items either complete or remove this table entirely
        }
        realm.delete(planResult)
        
        return true
    }
    
    // Expected to be executed in do/catch and write block
    func removeProductsForCategorySync(realm: Realm, categoryUuid: String, markForSync: Bool) -> Bool {
        let dbProducts = realm.objects(DBProduct).filter(DBProduct.createFilterCategory(categoryUuid))
        for dbProduct in dbProducts {
            deleteProductAndDependenciesSync(realm, dbProduct: dbProduct, markForSync: markForSync)
        }
        return true
    }
    
    func saveProduct(productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: Product? -> ()) {
        
        loadProductWithName(productInput.name, brand: productInput.brand) {[weak self] productMaybe in
            
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
                        let product = Product(uuid: uuid, name: productInput.name, category: category, brand: productInput.brand)
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
    
    func saveProducts(products: [Product], update: Bool = true, handler: Bool -> ()) {
        
        for product in products { // product marked as var to be able to update uuid
            
            doInWriteTransaction({realm in
                let dbProduct = ProductMapper.dbWithProduct(product)
                realm.add(dbProduct, update: update)
                return true
                
                }, finishHandler: {success in
                    handler(success ?? false)
            })
        }
    }
    
    // TODO: -
    
    func categoriesContaining(text: String, handler: [String] -> Void) {
        let mapper: DBProduct -> String = {$0.category.name}
        self.load(mapper, filter: DBProduct.createFilterCategoryNameContains(text)) {categories in
            let distinctCategories = NSOrderedSet(array: categories).array as! [String] // TODO re-check: Realm can't distinct yet https://github.com/realm/realm-cocoa/issues/1103
            handler(distinctCategories)
        }
    }

    func productWithUniqueSync(realm: Realm, name: String, brand: String) -> DBProduct? {
        return realm.objects(DBProduct).filter(DBProduct.createFilterNameBrand(name, brand: brand)).first
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
    
    func incrementFav(productUuid: String, _ handler: Bool -> Void) {
        doInWriteTransaction({realm in
            if let existingProduct = realm.objects(DBProduct).filter(DBProduct.createFilter(productUuid)).first {
                existingProduct.fav += 1
                realm.add(existingProduct, update: true)                
                return true
            } else { // product not found
                return false
            }
        }, finishHandler: {savedMaybe in
            handler(savedMaybe ?? false)
        })
    }
    
    func save(dbCategories: [DBProductCategory], dbProducts: [DBProduct], _ handler: Bool -> Void) {
        
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
        self.overwrite(dbProducts, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
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
    
    // MARK: - Store
    
    func storesContainingText(text: String, handler: [String] -> Void) {
        // this is for now an "infinite" range. This method is ussed for autosuggestions, we assume use will not have more than 10000 brands. If yes it's not critical for autosuggestions.
        storesContainingText(text, range: NSRange(location: 0, length: 10000), handler)
    }
    
    func storesContainingText(text: String, range: NSRange, _ handler: [String] -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("store", ascending: true)
                let stores = Array(Set(realm.objects(DBStoreProduct).filter(DBStoreProduct.createFilterStoreContains(text)).map{$0.store}))[range].filter{!$0.isEmpty}.sort()
                return stores
            } catch let e {
                QL4("Couldn't load stores, returning empty array. Error: \(e)")
                return []
            }
            }) {(result: [String]) in
                handler(result)
        }
    }
    
    // Returns: true if restored a product, false if didn't restore a product, nil if error ocurred
    func restorePrefillProducts(handler: Bool? -> Void) {
        
        doInWriteTransaction({realm in
            
            let prefillProducts = SuggestionsPrefiller().prefillProducts(LangManager().appLang).products
            
            var restoredSomething: Bool = false
            
            for prefillProduct in prefillProducts {
                if realm.objects(DBProduct).filter(DBProduct.createFilterNameBrand(prefillProduct.name, brand: prefillProduct.brand)).isEmpty {
                    QL1("Restoring prefill product: \(prefillProduct)")
                    realm.add(prefillProduct, update: false)
                    restoredSomething = true
                }
            }
            return restoredSomething
            
            }, finishHandler: {successMaybe in
                handler(successMaybe)
        })
    }
}