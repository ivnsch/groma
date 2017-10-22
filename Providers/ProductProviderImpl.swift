//
//  ProductProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

import RealmSwift

// TODO move product-only method from list item provider here
class ProductProviderImpl: ProductProvider {

    fileprivate let dbProvider = RealmListItemProvider()
    fileprivate let dbBrandProvider = RealmBrandProvider()
    fileprivate let remoteProvider = RemoteProductProvider()
    
    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<Product>>) -> Void) {
        DBProv.productProvider.loadProducts(range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .success, sucessResult: products))
            // For products no background sync, this is a very long list and not justified as this screen is not used frequently. Also when there are new products mostly this is because new list/inventory/group items were added, and we get these new products already as a dependency in the respective background updates of these items.
        }
    }
    
    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<QuantifiableProduct>>) -> Void) {
        DBProv.productProvider.loadQuantifiableProducts(range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .success, sucessResult: products))
            // For products no background sync, this is a very long list and not justified as this screen is not used frequently. Also when there are new products mostly this is because new list/inventory/group items were added, and we get these new products already as a dependency in the respective background updates of these items.
        }
    }
    
    func products(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [Product])>) -> Void) {
        DBProv.productProvider.products(text, range: range, sortBy: sortBy) {(substring: String?, products: [Product]?) in
            if let products = products {
                handler(ProviderResult(status: .success, sucessResult: (substring, products)))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func products(itemUuid: String, _ handler: @escaping (ProviderResult<Results<Product>>) -> Void) {
        DBProv.productProvider.products(itemUuid: itemUuid) {productsMaybe in
            if let products = productsMaybe {
                handler(ProviderResult(status: .success, sucessResult: products))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func quantifiableProducts(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [QuantifiableProduct])>) -> Void) {
        DBProv.productProvider.quantifiableProducts(text, range: range, sortBy: sortBy) {(substring: String?, products: [QuantifiableProduct]?) in
            if let products = products {
                handler(ProviderResult(status: .success, sucessResult: (substring, products)))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func quantifiableProducts(product: Product, _ handler: @escaping (ProviderResult<[QuantifiableProduct]>) -> Void) {
        DBProv.productProvider.quantifiableProducts(product: product) {quantifiableProducts in
            if let quantifiableProducts = quantifiableProducts {
                handler(ProviderResult(status: .success, sucessResult: quantifiableProducts))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func storeProducts(quantifiableProduct: QuantifiableProduct, _ handler: @escaping (ProviderResult<[StoreProduct]>) -> Void) {
        if let storeProducts = DBProv.productProvider.storeProductsSync(quantifiableProduct: quantifiableProduct) {
            handler(ProviderResult(status: .success, sucessResult: storeProducts))
        } else {
            handler(ProviderResult(status: .databaseUnknown))
        }
    }
    
    func productsRes(_ text: String, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: Results<Product>)>) -> Void) {
        DBProv.productProvider.products(text, sortBy: sortBy) {(substring: String?, products: Results<Product>?) in
            if let products = products {
                handler(ProviderResult(status: .success, sucessResult: (substring, products)))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func productsRes(_ text: String, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: Results<QuantifiableProduct>)>) -> Void) {
        
    }

    
    func quantifiableProductsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: QuantifiableProduct, section: Section?)])>) -> Void) {
        
        DBProv.productProvider.quantifiableProductsWithPosibleSections(text, list: list, range: range, sortBy: sortBy)
        { substring, productsWithMaybeSections in
            if let productsWithMaybeSections = productsWithMaybeSections {
                handler(ProviderResult(status: .success, sucessResult: (substring: substring,
                                                                        productsWithMaybeSections:
                    productsWithMaybeSections)))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    
    func productsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)])>) -> Void) {
        
        DBProv.productProvider.productsWithPosibleSections(text, list: list, range: range, sortBy: sortBy) { substring,
            productsWithMaybeSections in
            if let productsWithMaybeSections = productsWithMaybeSections {
                handler(ProviderResult(status: .success, sucessResult: (substring: substring,
                                                                        productsWithMaybeSections:
                    productsWithMaybeSections)))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func product(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProv.productProvider.loadProductWithName(name, brand: brand) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }
    
    func quantifiableProduct(_ unique: QuantifiableProductUnique, handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void) {
        DBProv.productProvider.loadQuantifiableProductWithUnique(unique) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    func products(_ nameBrands: [(name: String, brand: String)], _ handler: @escaping (ProviderResult<[Product]>) -> Void) {
        DBProv.productProvider.loadProductsWithNameBrands(nameBrands) {products in
            handler(ProviderResult(status: .success, sucessResult: products))            
        }
    }
    
    func add(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.productProvider.saveProducts([product], update: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.success : ProviderStatusCode.databaseUnknown))
            
            if saved {
                if remote {
                    self?.remoteProvider.addProduct(product) {remoteResult in
                        if let remoteProduct = remoteResult.successResult {
                            self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                                logger.e("Remote call no success: \(remoteResult)")
                            })
                        }
                    }
                }
            }
        }
    }

    func add(_ productInput: ProductInput, _ handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProv.productProvider.saveProduct(productInput, update: true) {[weak self] productMaybe in
            if let product = productMaybe {
                handler(ProviderResult(status: .success, sucessResult: product))
                
                self?.remoteProvider.addProduct(product) {remoteResult in
                    if let remoteProduct = remoteResult.successResult {
                        self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                            logger.e("Remote call no success: \(remoteResult)")
                        })
                    }
                }
                
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func add(_ product: QuantifiableProduct, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.saveQuantifiableProducts([product], update: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func update(_ product: QuantifiableProduct, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.saveQuantifiableProducts([product], update: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func update(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.productProvider.saveProducts([product], update: true) {[weak self] saved in
            if saved {
                Prov.listItemsProvider.invalidateMemCache() // reflect product updates in possible referencing list items
                
                if remote {
                    self?.remoteProvider.updateProduct(product) {remoteResult in
                        if let remoteProduct = remoteResult.successResult {
                            self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                                logger.e("Remote call no success: \(remoteResult)")
                            })
                        }
                    }
                }
            }
            handler(ProviderResult(status: saved ? ProviderStatusCode.success : ProviderStatusCode.databaseUnknown))
        }
    }
    
    func delete(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        delete(product.uuid, remote: remote, handler)
    }
    
    func delete(_ product: QuantifiableProduct, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.productProvider.deleteQuantifiableProductAndDependencies(product.uuid, markForSync: true) {success in
            handler(ProviderResult(status: success ? .success : .databaseUnknown))
        }
    }

    func delete(_ storeProduct: StoreProduct, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        let success = DBProv.storeProductProvider.deleteStoreProductSync(uuid: storeProduct.uuid)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }
    
    func delete(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.productProvider.deleteProductAndDependencies(productUuid, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))

            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteProvider.deleteProduct(productUuid) {remoteResult in
//                    if remoteResult.success {
//                        DBProv.productProvider.clearProductTombstone(productUuid) {removeTombstoneSuccess in
//                            if !removeTombstoneSuccess {
//                                logger.e("Couldn't delete tombstone for product: \(productUuid)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                            print("Error: removing product in remote: \(productUuid), result: \(remoteResult)")
//                        }
//                    }
//                }
//            }
        }
    }
    
    func delete(productName: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.deleteProductsAndDependencies(name: productName, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func deleteProductsWith(base: Float, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.deleteProductsAndDependencies(base: base, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func deleteProductsWith(unit: Unit, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.deleteQuantifiableProductsAndDependencies(unit: unit, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func deleteProductsWith(unitName: String, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.deleteQuantifiableProductsAndDependencies(unitName: unitName, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
        }
    }
    
    func deleteQuantifiableProduct(uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        DBProv.productProvider.deleteQuantifiableProductAndDependencies(uuid, markForSync: true) {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
            
            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteProvider.deleteProduct(productUuid) {remoteResult in
//                    if remoteResult.success {
//                        DBProv.productProvider.clearProductTombstone(productUuid) {removeTombstoneSuccess in
//                            if !removeTombstoneSuccess {
//                                logger.e("Couldn't delete tombstone for product: \(productUuid)")
//                            }
//                        }
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
//                            print("Error: removing product in remote: \(productUuid), result: \(remoteResult)")
//                        }
//                    }
//                }
//            }
        }
    }
    
    func updateBaseQuantity(oldBase: Float, newBase: Float, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        let success = DBProv.productProvider.updateBaseSync(oldBase: oldBase, newBase: newBase)
        handler(ProviderResult(status: success ? .success : .databaseUnknown))
    }
    
    func incrementFav(quantifiableProductUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProv.productProvider.incrementFav(quantifiableProductUuid: quantifiableProductUuid, {saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
     
            // Disabled while impl. realm sync
//            if remote {
//                self?.remoteProvider.incrementFav(productUuid) {remoteResult in
//                    if remoteResult.success {
//                        // no timestamp - for increment fav this looks like an overkill. If there's a conflict some favs may get lost - ok
//                    } else {
//                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
//                            logger.e("Remote call no success: \(remoteResult)")
//                        })
//                    }
//                }
//            }
        })
    }
    
    
    func loadQuantifiableProduct(unique: QuantifiableProductUnique, _ handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void) {
        DBProv.productProvider.loadQuantifiableProductWithUnique(unique) {quantifiableProductMaybe in
            if let quantifiableProduct = quantifiableProductMaybe {
                handler(ProviderResult(status: .success, sucessResult: quantifiableProduct))
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func updateOrCreateQuantifiableProduct(prototype: ProductPrototype, _ handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void) {

        DBProv.productProvider.updateOrCreateQuantifiableProduct(prototype) {quantifiableProductMaybe in
            if let quantifiableProduct = quantifiableProductMaybe {
                handler(ProviderResult(status: .success, sucessResult: quantifiableProduct))
            } else {
                logger.e("Couldn't update/create quantifiable product for prototype: \(prototype)")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func loadProduct(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProv.productProvider.loadProductWithName(name, brand: brand) {dbProductMaybe in
            if let dbProduct = dbProductMaybe {
                handler(ProviderResult(status: .success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .notFound))
            }

            //            // TODO is this necessary here?
            //            self.remoteProvider.product(name, list: list) {remoteResult in
            //
            //                if let remoteProduct = remoteResult.successResult {
            //                    let product = ProductMapper.ProductWithRemote(remoteProduct)
            //                    handler(ProviderResult(status: .Success, sucessResult: product))
            //                } else {
            //                    print("Error getting remote product, status: \(remoteResult.status)")
            //                    handler(ProviderResult(status: .DatabaseUnknown))
            //                }
            //            }
        }
    }
    
    func categoriesContaining(_ name: String, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProv.productProvider.categoriesContaining(name) {dbCategories in
            handler(ProviderResult(status: .success, sucessResult: dbCategories))
        }
    }

    func mergeOrCreateProduct(prototype: ProductPrototype, updateCategory: Bool, updateItem: Bool, _ handler: @escaping (ProviderResult<Product>) -> Void) {
        
        // load product and update or create one
        // if we find a product with the name/brand we update it - this is for the case the user changes the price etc for an existing product while adding an item
        self.loadProduct(prototype.name, brand: prototype.brand) {result in
            if let existingProduct = result.sucessResult {
                let updatedProduct = existingProduct.updateNonUniqueProperties(prototype: prototype)
                handler(ProviderResult(status: .success, sucessResult: updatedProduct))
                
            } else { // product doesn't exist
                
                // check if a category with given name already exist
                Prov.productCategoryProvider.categoryWithName(prototype.category) {result in
                    
                    func onHasCategory(_ category: ProductCategory) {
                        
                        func onHasItem(_ item: Item) {
                            // fav: 1 If we create a product we are "using" it so we start with fav: 1. This way, for example, when user creates new products in the quick add, these products will show in the quick add list above of prefilled products that have never been used.
                            let newProduct = Product(uuid: UUID().uuidString, item: item, brand: prototype.brand)
                            handler(ProviderResult(status: .success, sucessResult: newProduct))
                        }
                        
                        // 2nd dependency - item
                        Prov.itemsProvider.item(name: prototype.name) {itemResult in
                            if let successResult = itemResult.sucessResult {
                                
                                if let existingItem = successResult {
                                    if updateItem {
                                        // Nothing to update yet (name is the unique)
                                        //                                    let updatedItem = existingItem.copy()
                                        onHasItem(existingItem)
                                    } else {
                                        onHasItem(existingItem)
                                    }
                                    
                                } else {
                                    let newItem = Item(uuid: UUID().uuidString, name: prototype.name, category: category, fav: 1)
                                    onHasItem(newItem)
                                }

                            } else {
                                logger.e("Couldn't fetch item: \(itemResult)")
                                handler(ProviderResult(status: .databaseUnknown))
                            }
                        }
                    }
                    
                    // 1st dependency - category
                    if let existingCategory = result.sucessResult {
                        if updateCategory {
                            let udpatedCategory = existingCategory.copy(color: prototype.categoryColor)
                            onHasCategory(udpatedCategory)
                        } else {
                            onHasCategory(existingCategory)
                        }
                        
                    } else if result.status == .notFound {
                        let newCategory = ProductCategory(uuid: UUID().uuidString, name: prototype.category, color: prototype.categoryColor)
                        onHasCategory(newCategory)
                        
                    } else {
                        print("Error: ProductProviderImpl.mergeOrCreateProduct: Couldn't fetch category: \(result)")
                        handler(ProviderResult(status: .databaseUnknown))
                    }
                    
                }
            }
        }
    }
    
    func mergeOrCreateProduct(prototype: ProductPrototype, updateCategory: Bool, updateItem: Bool, _ handler: @escaping (ProviderResult<(QuantifiableProduct, Bool)>) -> Void) {
        switch DBProv.productProvider.mergeOrCreateQuantifiableProductSync(prototype: prototype, updateCategory: updateCategory, save: true) {
        case .ok(let result):
            handler(ProviderResult(status: .success, sucessResult: result))
        case .err(let error):
            logger.e("Couldn't merge/crate product: \(error)")
        }
    }

    
    
    func countProducts(_ handler: @escaping (ProviderResult<Int>) -> Void) {
        DBProv.productProvider.countProducts {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .success, sucessResult: count))
            } else {
                logger.e("No count")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func storesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProv.productProvider.storesContainingText(text) {stores in
            handler(ProviderResult(status: .success, sucessResult: stores))
        }
    }
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProv.productProvider.storesContainingText(text, range: range) {stores in
            handler(ProviderResult(status: .success, sucessResult: stores))
        }
    }
    
    func removeStore(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.removeStore(name) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Prov.listItemsProvider.invalidateMemCache()
                Prov.inventoryItemsProvider.invalidateMemCache()
                
                //TODO!!!! server
            }
            handler(ProviderResult(status: success ? .success : .unknown))
        }
    }
    
    func restorePrefillProductsLocal(_ handler: @escaping (ProviderResult<Bool>) -> Void) {
        DBProv.productProvider.restorePrefillProducts() {restoredSomethingMaybe in
            if let restoredSomething = restoredSomethingMaybe {
                handler(ProviderResult(status: .success, sucessResult: restoredSomething))
            } else {
                logger.e("Local error restoring products")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func allBaseQuantities(_ handler: @escaping (ProviderResult<[Float]>) -> Void) {
        DBProv.productProvider.allBaseQuantities {baseQuantitiesMaybe in
            if let baseQuantities = baseQuantitiesMaybe {
                handler(ProviderResult(status: .success, sucessResult: baseQuantities))
            } else {
                logger.e("Couldn't retrieve base quantities")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }

    func baseQuantitiesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[Float]>) -> Void) {
        DBProv.productProvider.baseQuantitiesContainingText(text) {stores in
            handler(ProviderResult(status: .success, sucessResult: stores))
        }
    }
    
    func unitsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProv.productProvider.unitsContainingText(text) {units in
            handler(ProviderResult(status: .success, sucessResult: units))
        }
    }
}
