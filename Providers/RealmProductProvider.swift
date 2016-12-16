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

public struct ProductUnique {
    let name: String
    let brand: String
    
    init(name: String, brand: String) {
        self.name = name
        self.brand = brand
    }
}

public struct ProductPrototype {
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

public struct StoreProductUnique {
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
    
    func loadProductWithUuid(_ uuid: String, handler: @escaping (Product?) -> ()) {
        do {
            let realm = try Realm()
            // TODO review if it's necessary to pass the sort descriptor here again
            let productMaybe: Product? = self.loadSync(realm, filter: Product.createFilter(uuid)).first
            handler(productMaybe)
            
        } catch let e {
            QL4("Error: creating Realm, returning empty results, error: \(e)")
            handler(nil)
        }
    }
    
    // TODO rename method (uses now brand too)
    func loadProductWithName(_ name: String, brand: String, handler: @escaping (Product?) -> ()) {
        
        background({() -> String? in
            do {
                let realm = try Realm()
                let product: Product? = self.loadSync(realm, filter: Product.createFilterNameBrand(name, brand: brand)).first
                return product?.uuid
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidMaybe in
            do {
                if let productUuid = productUuidMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let productMaybe: Product? = self.loadSync(realm, filter: Product.createFilter(productUuid)).first
                    if productMaybe == nil {
                        QL4("Unexpected: product with just fetched uuid is not there")
                    }
                    handler(productMaybe)
                    
                } else {
                    QL1("No product found for name: \(name), brand: \(brand)")
                    handler(nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }

    func loadProductsWithNameBrands(_ nameBrands: [(name: String, brand: String)], handler: @escaping ([Product]) -> Void) {
        withRealm({realm -> [String]? in
            var productUuids: [String] = []
            for nameBrand in nameBrands {
                let dbProduct: Results<Product> = realm.objects(Product.self).filter(Product.createFilterNameBrand(nameBrand.name, brand: nameBrand.brand))
                productUuids.appendAll(dbProduct.map{$0.uuid})
            }
            return productUuids
        }) {productUuidsMaybe in
            do {
                if let productUuids = productUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let products: Results<Product> = self.loadSync(realm, filter: Product.createFilterUuids(productUuids))
                    handler(products.toArray())
                    
                } else {
                    QL4("No product uuids")
                    handler([])
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler([])
            }
        }
    }
    
    func loadProducts(_ range: NSRange, sortBy: ProductSortBy, handler: @escaping (Results<Product>?) -> ()) {
        // For now duplicate code with products, to use Results and plain objs api together (for search text for now it's easier to use plain obj api)
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        load(filter: nil, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)/*, range: range*/) {(products: Results<Product>?) in
            handler(products)
        }
    }
    
    
    // IMPORTANT: This cannot be used for real time updates (add) since the final results are fetched using uuids, so these results don't notice products with new uuids
    func products(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: Results<Product>?) -> Void) {
        
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{Product.createFilterNameContains($0)}
        
        background({() -> [String]? in
            do {
                let realm = try Realm()
                let products: [Product] = self.loadSync(realm, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending), range: range)
                return products.map{$0.uuid}
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {productUuidsMaybe in
            do {
                if let productUuids = productUuidsMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let products: Results<Product> = self.loadSync(realm, filter: Product.createFilterUuids(productUuids), sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending))
                    handler(substring, products)
                    
                } else {
                    QL4("No product uuids")
                    handler(substring, nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(substring, nil)
            }
        })
    
    }

    func products(_ substring: String? = nil, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ products: [Product]?) -> Void) {
        products(substring, range: range, sortBy: sortBy) {(substring, result) in
            handler(substring, result?.toArray())
        }
    }
    
    // TODO range
    func productsWithPosibleSections(_ substring: String? = nil, list: List, range: NSRange? = nil, sortBy: ProductSortBy, handler: @escaping (_ substring: String?, _ productsWithMaybeSections: [(product: Product, section: Section?)]?) -> Void) {
        let sortData: (key: String, ascending: Bool) = {
            switch sortBy {
            case .alphabetic: return ("name", true)
            case .fav: return ("fav", false)
            }
        }()
        
        let filterMaybe = substring.map{Product.createFilterNameContains($0)}
        
        // Note that we are load the sections from db for each range - this could be optimised (load sections only once for all pages) but it shouldn't be an issue since usually there are not a lot of sections and it's performing well.
        
        withRealm({[weak self] realm in guard let weakSelf = self else {return nil}
            let products: Results<Product> = weakSelf.loadSync(realm, filter: filterMaybe, sortDescriptor: NSSortDescriptor(key: sortData.key, ascending: sortData.ascending)/*, range: range*/)
            
            let categoryNames = products.map{$0.category.name}.distinct()
        
            let sectionsDict: [String: DBSection] = realm.objects(DBSection.self).filter(DBSection.createFilterWithNames(categoryNames, listUuid: list.uuid)).toDictionary{($0.name, $0)}
            
            let productsWithMaybeSections: [(product: Product, section: Section?)] = products.map {product in
                let sectionMaybe = sectionsDict[product.category.name].map{SectionMapper.sectionWithDB($0)}
                return (product, sectionMaybe)
            }

            return productsWithMaybeSections
            
        }, resultHandler: {(productsWithMaybeSections: [(product: Product, section: Section?)]?) in
            handler(substring, productsWithMaybeSections)
        })
    }
    
    func countProducts(_ handler: @escaping (Int?) -> Void) {
        withRealm({realm in
            realm.objects(Product.self).count
            }) { (countMaybe: Int?) -> Void in
                if let count = countMaybe {
                    handler(count)
                } else {
                    QL4("No count")
                    handler(nil)
                }
        }
    }
    
    func deleteProductAndDependencies(_ productUuid: String, markForSync: Bool, handler: @escaping (Bool) -> Void) {
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
    
    func deleteProductAndDependencies(_ product: Product, markForSync: Bool, handler: @escaping (Bool) -> Void) {
        deleteProductAndDependencies(product.uuid, markForSync: markForSync, handler: handler)
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductAndDependenciesSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        if let productResult = realm.objects(Product.self).filter(Product.createFilter(productUuid)).first {
            return deleteProductAndDependenciesSync(realm, dbProduct: productResult, markForSync: markForSync)
        } else {
            return false
        }
    }
    
    func deleteProductAndDependenciesSync(_ realm: Realm, dbProduct: Product, markForSync: Bool) -> Bool {
        if deleteProductDependenciesSync(realm, productUuid: dbProduct.uuid, markForSync: markForSync) {
            if markForSync {
                let toRemove = ProductToRemove(dbProduct)
                realm.add(toRemove, update: true)
            }
            realm.delete(dbProduct)
            return true
        } else {
            return false
        }
    }
    
    // Note: This is expected to be called from inside a transaction and in a background operation
    func deleteProductDependenciesSync(_ realm: Realm, productUuid: String, markForSync: Bool) -> Bool {
        
        _ = DBProv.storeProductProvider.deleteStoreProductsAndDependenciesForProductSync(realm, productUuid: productUuid, markForSync: markForSync)
        
        _ = DBProv.groupItemProvider.removeGroupItemsForProductSync(realm, productUuid: productUuid, markForSync: markForSync)
        
        let inventoryResult = realm.objects(InventoryItem.self).filter(InventoryItem.createFilterWithProduct(productUuid))
        if markForSync {
            let toRemoteInventoryItems = Array(inventoryResult.map{DBRemoveInventoryItem($0)})
            saveObjsSyncInt(realm, objs: toRemoteInventoryItems, update: true)
        }
        realm.delete(inventoryResult)
        
        let historyResult = realm.objects(DBHistoryItem.self).filter(DBHistoryItem.createFilterWithProduct(productUuid))
        if markForSync {
            let toRemoteHistoryItems =  Array(historyResult.map{DBRemoveHistoryItem($0)})
            saveObjsSyncInt(realm, objs: toRemoteHistoryItems, update: true)
        }
        realm.delete(historyResult)
        
        let planResult = realm.objects(DBPlanItem.self).filter(DBPlanItem.createFilterWithProduct(productUuid))
        if markForSync {
            // TODO plan items either complete or remove this table entirely
        }
        realm.delete(planResult)
        
        return true
    }
    
    // Expected to be executed in do/catch and write block
    func removeProductsForCategorySync(_ realm: Realm, categoryUuid: String, markForSync: Bool) -> Bool {
        let dbProducts = realm.objects(Product.self).filter(Product.createFilterCategory(categoryUuid))
        for dbProduct in dbProducts {
            _ = deleteProductAndDependenciesSync(realm, dbProduct: dbProduct, markForSync: markForSync)
        }
        return true
    }
    
    func saveProduct(_ productInput: ProductInput, updateSuggestions: Bool = true, update: Bool = true, handler: @escaping (Product?) -> ()) {
        
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
                    return UUID().uuidString
                }
            }()
            
            Prov.productCategoryProvider.categoryWithName(productInput.category) {result in
                
                if result.status == .success || result.status == .notFound  {
                    
                    // Create a new category or update existing one
                    let category: ProductCategory? = {
                        if let existingCategory = result.sucessResult {
                            return existingCategory.copy(name: productInput.category, color: productInput.categoryColor)
                        } else if result.status == .notFound {
                            return ProductCategory(uuid: UUID().uuidString, name: productInput.category, color: productInput.categoryColor)
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
    
    func saveProducts(_ products: [Product], update: Bool = true, handler: @escaping (Bool) -> ()) {
        
        let productsCopy = products.map{$0.copy()} // fixes Realm acces in incorrect thread exceptions
        
        for product in productsCopy {
            
            doInWriteTransaction({realm in
                realm.add(product, update: update)
                return true
                
                }, finishHandler: {success in
                    handler(success ?? false)
            })
        }
    }
    
    // TODO: -
    
    func categoriesContaining(_ text: String, handler: @escaping ([String]) -> Void) {
        let mapper: (Product) -> String = {$0.category.name}
        self.load(mapper, filter: Product.createFilterCategoryNameContains(text)) {categories in
            let distinctCategories = NSOrderedSet(array: categories).array as! [String] // TODO re-check: Realm can't distinct yet https://github.com/realm/realm-cocoa/issues/1103
            handler(distinctCategories)
        }
    }

    func productWithUniqueSync(_ realm: Realm, name: String, brand: String) -> Product? {
        return realm.objects(Product.self).filter(Product.createFilterNameBrand(name, brand: brand)).first
    }
    
    func categoryWithName(_ name: String, handler: @escaping (ProductCategory?) -> ()) {
        background({() -> String? in
            do {
                let realm = try Realm()
                let obj: ProductCategory? = self.loadSync(realm, filter: ProductCategory.createFilterName(name)).first
                return obj?.uuid
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                return nil
            }
            
        }, onFinish: {uuidMaybe in
            do {
                if let uuid = uuidMaybe {
                    let realm = try Realm()
                    // TODO review if it's necessary to pass the sort descriptor here again
                    let objMaybe: ProductCategory? = self.loadSync(realm, filter: ProductCategory.createFilter(uuid)).first
                    if objMaybe == nil {
                        QL4("Unexpected: obj with just fetched uuid is not there")
                    }
                    handler(objMaybe)
                    
                } else {
                    QL1("No category found for name: \(name)")
                    handler(nil)
                }
                
            } catch let e {
                QL4("Error: creating Realm, returning empty results, error: \(e)")
                handler(nil)
            }
        })
    }
    
    func loadCategorySuggestions(_ handler: @escaping ([Suggestion]) -> ()) {
        // TODO review why section and product suggestion have their own database objects, was it performance, prefill etc? Do we also need this here?
        self.load {(categories: Results<ProductCategory>?) in
            if let categories = categories {
                let suggestions = Array(categories.map{Suggestion(name: $0.name)})
                handler(suggestions)
            } else {
                QL4("No categories")
                handler([])
            }
        }
    }
    
    func incrementFav(_ productUuid: String, _ handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            if let existingProduct = realm.objects(Product.self).filter(Product.createFilter(productUuid)).first {
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
    
    func save(_ dbCategories: [ProductCategory], dbProducts: [Product], _ handler: @escaping (Bool) -> Void) {
        
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
    
    func removeAllCategories(_ handler: @escaping (Bool) -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllCategories: couldn't remove categories")
            }
            handler(success)
        }, objType: ProductCategory.self)
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    // WARN: This is only used for generating prefill database so no tombstones
    ///////////////////////////////////////////////////////////////////////////////////////
    
    func removeAllProducts(_ handler: @escaping (Bool) -> Void) {
        self.remove(nil, handler: {success in
            if !success {
                print("Error: RealmProductProvider.removeAllProducts: couldn't remove products")
            }
            handler(success)
        }, objType: Product.self)
    }
    
    // Removes all products and categories
    func removeAllProductsAndCategories(_ handler: @escaping (Bool) -> Void) {
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
    
    func overwriteProducts(_ dbProducts: [Product], clearTombstones: Bool, handler: @escaping (Bool) -> Void) {
        let additionalActions: ((Realm) -> Void)? = clearTombstones ? {realm in realm.deleteAll(ProductToRemove.self)} : nil
        self.overwrite(dbProducts, resetLastUpdateToServer: true, idExtractor: {$0.uuid}, additionalActions: additionalActions, handler: handler)
    }
    
    /**
     * Performs an upsert using a product prototype.
     * This will insert a new product if there's no product with the prototype's unique (name+brand+store). Otherwise it updates the existing one.
     * Analogously for the category, inserts a new one if no one exists with the prototype's category name, or updates the existing one.
     * Ensures that the product points to the correct category which can be 1. The same which already was referenced by the product, if the product exists and the category name is unchanged, 2. An existing category which was not referenced by the product (input category name is different than the name of the category referenced by the existing product), 3. A new category, if no category with prototype's category name exists yet.
     */
    func upsertProductSync(_ realm: Realm, prototype: ProductPrototype) -> Product {
        
        func findOrCreateCategory(_ realm: Realm, prototype: ProductPrototype) -> ProductCategory {
            return realm.objects(ProductCategory.self).filter(ProductCategory.createFilterName(prototype.category)).first ?? ProductCategory(uuid: NSUUID().uuidString, name: prototype.name, color: prototype.categoryColor)
        }
        
        func categoryForExistingProduct(_ existingProduct: Product, prototype: ProductPrototype) -> ProductCategory {
            // Make the updated product point to correct category - if category name hasn't changed, no pointer update. If input category name is different, see if a category with this name already exists, and update pointer. Otherwise create a new category and udpate pointer.
            if existingProduct.category.name != prototype.category {
                return findOrCreateCategory(realm, prototype:  prototype)
            } else {
                return existingProduct.category
            }
        }
        
        func updateExistingProduct(_ realm: Realm, existingProduct: Product, prototype: ProductPrototype) -> Product {
            
            let category = categoryForExistingProduct(existingProduct, prototype: prototype)
            let updatedCategory = category.copy(color: prototype.categoryColor)
            
            // Udpate product fields
            let updatedProduct = existingProduct.update(prototype)
            updatedProduct.category = updatedCategory
            
            realm.add(updatedProduct, update: true)
            
            return updatedProduct
        }
        
        func insertNewProduct(_ realm: Realm, prototype: ProductPrototype) -> Product {
            let category = findOrCreateCategory(realm, prototype: prototype)
            let newProduct = Product(prototype: prototype, category: category)
            realm.add(newProduct, update: false)
            return newProduct
        }
        
        if let existingProduct = realm.objects(Product.self).filter(Product.createFilterUnique(prototype)).first {
            return updateExistingProduct(realm, existingProduct: existingProduct, prototype: prototype)
        } else {
            return insertNewProduct(realm, prototype: prototype)
        }
    }
    
    // MARK: - Sync
    
    func clearProductTombstone(_ uuid: String, handler: @escaping (Bool) -> Void) {
        doInWriteTransaction({realm in
            realm.deleteForFilter(ProductToRemove.self, ProductToRemove.createFilter(uuid))
            return true
            }, finishHandler: {success in
                handler(success ?? false)
        })
    }
    
    
    func updateLastSyncTimeStampSync(_ realm: Realm, product: RemoteProduct) {
        realm.create(Product.self, value: product.timestampUpdateDict, update: true)
    }
    
    // MARK: - Store
    
    func storesContainingText(_ text: String, handler: @escaping ([String]) -> Void) {
        // this is for now an "infinite" range. This method is ussed for autosuggestions, we assume use will not have more than 10000 brands. If yes it's not critical for autosuggestions.
        storesContainingText(text, range: NSRange(location: 0, length: 10000), handler)
    }
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping ([String]) -> Void) {
        background({
            do {
                let realm = try Realm()
                // TODO sort in the database? Right now this doesn't work because we pass the results through a Set to filter duplicates
                // .sorted("store", ascending: true)
                let stores = Array(Set(realm.objects(DBStoreProduct.self).filter(DBStoreProduct.createFilterStoreContains(text)).map{$0.store}))[range].filter{!$0.isEmpty}.sorted()
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
    func restorePrefillProducts(_ handler: @escaping (Bool?) -> Void) {
        
        doInWriteTransaction({realm in
            
            let prefillProducts = SuggestionsPrefiller().prefillProducts(LangManager().appLang).products
            
            var restoredSomething: Bool = false
            
            for prefillProduct in prefillProducts {
                if realm.objects(Product.self).filter(Product.createFilterNameBrand(prefillProduct.name, brand: prefillProduct.brand)).isEmpty {
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
