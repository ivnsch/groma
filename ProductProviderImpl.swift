//
//  ProductProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs
import RealmSwift

// TODO move product-only method from list item provider here
class ProductProviderImpl: ProductProvider {

    fileprivate let dbProvider = RealmListItemProvider()
    fileprivate let dbBrandProvider = RealmBrandProvider()
    fileprivate let remoteProvider = RemoteProductProvider()
    
    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<Product>>) -> Void) {
        DBProviders.productProvider.loadProducts(range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .success, sucessResult: products))
            // For products no background sync, this is a very long list and not justified as this screen is not used frequently. Also when there are new products mostly this is because new list/inventory/group items were added, and we get these new products already as a dependency in the respective background updates of these items.
        }
    }
    
    func products(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [Product])>) -> Void) {
        DBProviders.productProvider.products(text, range: range, sortBy: sortBy) {(substring: String?, products: [Product]?) in
            if let products = products {
                handler(ProviderResult(status: .success, sucessResult: (substring, products)))
            }
        }
    }
    
    func productsRes(_ text: String, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: Results<Product>)>) -> Void) {
        DBProviders.productProvider.products(text, sortBy: sortBy) {(substring: String?, products: Results<Product>?) in
            if let products = products {
                handler(ProviderResult(status: .success, sucessResult: (substring, products)))
            }
        }
    }
    
    func productsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)])>) -> Void) {
        
        DBProviders.productProvider.productsWithPosibleSections(text, list: list, range: range, sortBy: sortBy) {result in
            if let productsWithMaybeSections = result.1 {
                handler(ProviderResult(status: .success, sucessResult: (substring: result.0, productsWithMaybeSections: productsWithMaybeSections)))
            } else {
                handler(ProviderResult(status: .unknown))
            }
        }
    }
    
    func product(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProviders.productProvider.loadProductWithName(name, brand: brand) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .notFound))
            }
        }
    }

    func products(_ nameBrands: [(name: String, brand: String)], _ handler: @escaping (ProviderResult<[Product]>) -> Void) {
        DBProviders.productProvider.loadProductsWithNameBrands(nameBrands) {products in
            handler(ProviderResult(status: .success, sucessResult: products))            
        }
    }
    
    func add(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProviders.productProvider.saveProducts([product], update: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.success : ProviderStatusCode.databaseUnknown))
            
            if saved {
                if remote {
                    self?.remoteProvider.addProduct(product) {remoteResult in
                        if let remoteProduct = remoteResult.successResult {
                            self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                                QL4("Remote call no success: \(remoteResult)")
                            })
                        }
                    }
                }
            }
        }
    }

    func add(_ productInput: ProductInput, _ handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProviders.productProvider.saveProduct(productInput, update: true) {[weak self] productMaybe in
            if let product = productMaybe {
                handler(ProviderResult(status: .success, sucessResult: product))
                
                self?.remoteProvider.addProduct(product) {remoteResult in
                    if let remoteProduct = remoteResult.successResult {
                        self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                            QL4("Remote call no success: \(remoteResult)")
                        })
                    }
                }
                
            } else {
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func update(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProviders.productProvider.saveProducts([product], update: true) {[weak self] saved in
            if saved {
                Providers.listItemsProvider.invalidateMemCache() // reflect product updates in possible referencing list items
                
                if remote {
                    self?.remoteProvider.updateProduct(product) {remoteResult in
                        if let remoteProduct = remoteResult.successResult {
                            self?.dbProvider.updateLastSyncTimeStamp(remoteProduct) {success in
                            }
                        } else {
                            DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Product>) in
                                QL4("Remote call no success: \(remoteResult)")
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
    
    func delete(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProviders.productProvider.deleteProductAndDependencies(productUuid, markForSync: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
            
            if remote {
                self?.remoteProvider.deleteProduct(productUuid) {remoteResult in
                    if remoteResult.success {
                        DBProviders.productProvider.clearProductTombstone(productUuid) {removeTombstoneSuccess in
                            if !removeTombstoneSuccess {
                                QL4("Couldn't delete tombstone for product: \(productUuid)")
                            }
                        }
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult)  {(remoteResult: ProviderResult<Any>) in
                            print("Error: removing product in remote: \(productUuid), result: \(remoteResult)")
                        }
                    }
                }
            }
        }
    }
    
    func incrementFav(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ()) {
        DBProviders.productProvider.incrementFav(productUuid, {[weak self] saved in
            handler(ProviderResult(status: saved ? .success : .databaseUnknown))
            
            if remote {
                self?.remoteProvider.incrementFav(productUuid) {remoteResult in
                    if remoteResult.success {
                        // no timestamp - for increment fav this looks like an overkill. If there's a conflict some favs may get lost - ok
                    } else {
                        DefaultRemoteErrorHandler.handle(remoteResult, handler: {(result: ProviderResult<Any>) in
                            QL4("Remote call no success: \(remoteResult)")
                        })
                    }
                }
            }
        })
    }
    
    func loadProduct(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ()) {
        DBProviders.productProvider.loadProductWithName(name, brand: brand) {dbProductMaybe in
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
        DBProviders.productProvider.categoriesContaining(name) {dbCategories in
            handler(ProviderResult(status: .success, sucessResult: dbCategories))
        }
    }

    func mergeOrCreateProduct(_ productName: String, category: String, categoryColor: UIColor, brand: String, updateCategory: Bool, _ handler: @escaping (ProviderResult<Product>) -> Void) {

        // load product and update or create one
        // if we find a product with the name/brand we update it - this is for the case the user changes the price etc for an existing product while adding an item
        loadProduct(productName, brand: brand) {result in
            if let existingProduct = result.sucessResult {
                let updatedCateogry = existingProduct.category.copy(name: category, color: categoryColor)
                let updatedProduct = existingProduct.copy(category: updatedCateogry)
                handler(ProviderResult(status: .success, sucessResult: updatedProduct))
                
            } else { // product doesn't exist
                
                // check if a category with given name already exist
                Providers.productCategoryProvider.categoryWithName(category) {result in
                    
                    func onHasCategory(_ category: ProductCategory) {
                        // fav: 1 If we create a product we are "using" it so we start with fav: 1. This way, for example, when user creates new products in the quick add, these products will show in the quick add list above of prefilled products that have never been used.
                        let newProduct = Product(uuid: UUID().uuidString, name: productName, category: category, fav: 1, brand: brand)
                        handler(ProviderResult(status: .success, sucessResult: newProduct))
                    }
                    
                    if let existingCategory = result.sucessResult {
                        if updateCategory {
                            let udpatedCategory = existingCategory.copy(color: categoryColor)
                            onHasCategory(udpatedCategory)
                        } else {
                            onHasCategory(existingCategory)
                        }
                        
                    } else if result.status == .notFound {
                        let newCategory = ProductCategory(uuid: UUID().uuidString, name: category, color: categoryColor)
                        onHasCategory(newCategory)
                        
                    } else {
                        print("Error: ProductProviderImpl.mergeOrCreateProduct: Couldn't fetch category: \(result)")
                        handler(ProviderResult(status: .databaseUnknown))
                    }

                }
            }
        }
    }
    
    
    func countProducts(_ handler: @escaping (ProviderResult<Int>) -> Void) {
        DBProviders.productProvider.countProducts {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .success, sucessResult: count))
            } else {
                QL4("No count")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
    
    func storesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProviders.productProvider.storesContainingText(text) {stores in
            handler(ProviderResult(status: .success, sucessResult: stores))
        }
    }
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void) {
        DBProviders.productProvider.storesContainingText(text, range: range) {stores in
            handler(ProviderResult(status: .success, sucessResult: stores))
        }
    }
    
    func removeStore(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void) {
        dbProvider.removeStore(name) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Providers.listItemsProvider.invalidateMemCache()
                Providers.inventoryItemsProvider.invalidateMemCache()
                
                //TODO!!!! server
            }
            handler(ProviderResult(status: success ? .success : .unknown))
        }
    }
    
    func restorePrefillProductsLocal(_ handler: @escaping (ProviderResult<Bool>) -> Void) {
        DBProviders.productProvider.restorePrefillProducts() {restoredSomethingMaybe in
            if let restoredSomething = restoredSomethingMaybe {
                handler(ProviderResult(status: .success, sucessResult: restoredSomething))
            } else {
                QL4("Local error restoring products")
                handler(ProviderResult(status: .databaseUnknown))
            }
        }
    }
}
