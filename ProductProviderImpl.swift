//
//  ProductProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

// TODO move product-only method from list item provider here
class ProductProviderImpl: ProductProvider {

    private let dbProvider = RealmListItemProvider()
    private let dbBrandProvider = RealmBrandProvider()
    private let remoteProvider = RemoteProductProvider()
    
    func products(range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<[Product]> -> Void) {
        DBProviders.productProvider.loadProducts(range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
            // For products no background sync, this is a very long list and not justified as this screen is not used frequently. Also when there are new products mostly this is because new list/inventory/group items were added, and we get these new products already as a dependency in the respective background updates of these items.
        }
    }
    
    func products(text: String, range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<(substring: String?, products: [Product])> -> Void) {
        DBProviders.productProvider.products(text, range: range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
    
    func productsWithPosibleSections(text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<(substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)])> -> Void) {
        
        DBProviders.productProvider.productsWithPosibleSections(text, list: list, range: range, sortBy: sortBy) {result in
            if let productsWithMaybeSections = result.productsWithMaybeSections {
                handler(ProviderResult(status: .Success, sucessResult: (substring: result.substring, productsWithMaybeSections: productsWithMaybeSections)))
            } else {
                handler(ProviderResult(status: .Unknown))
            }
        }
    }
    
    func product(name: String, brand: String, handler: ProviderResult<Product> -> ()) {
        DBProviders.productProvider.loadProductWithName(name, brand: brand) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func add(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.productProvider.saveProducts([product], update: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
            
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

    func add(productInput: ProductInput, _ handler: ProviderResult<Product> -> ()) {
        DBProviders.productProvider.saveProduct(productInput, update: true) {[weak self] productMaybe in
            if let product = productMaybe {
                handler(ProviderResult(status: .Success, sucessResult: product))
                
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
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func update(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
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
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func delete(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        delete(product.uuid, remote: remote, handler)
    }
    
    func delete(productUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.productProvider.deleteProductAndDependencies(productUuid, markForSync: true) {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
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
    
    func incrementFav(productUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        DBProviders.productProvider.incrementFav(productUuid, {[weak self] saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
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
    
    func loadProduct(name: String, brand: String, handler: ProviderResult<Product> -> ()) {
        DBProviders.productProvider.loadProductWithName(name, brand: brand) {dbProductMaybe in
            if let dbProduct = dbProductMaybe {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .NotFound))
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
    
    func categoriesContaining(name: String, _ handler: ProviderResult<[String]> -> Void) {
        DBProviders.productProvider.categoriesContaining(name) {dbCategories in
            handler(ProviderResult(status: .Success, sucessResult: dbCategories))
        }
    }

    func mergeOrCreateProduct(productName: String, category: String, categoryColor: UIColor, baseQuantity: Float, unit: StoreProductUnit, brand: String, updateCategory: Bool, _ handler: ProviderResult<Product> -> Void) {

        // load product and update or create one
        // if we find a product with the name/brand we update it - this is for the case the user changes the price etc for an existing product while adding an item
        loadProduct(productName, brand: brand) {result in
            if let existingProduct = result.sucessResult {
                let updatedCateogry = existingProduct.category.copy(name: category, color: categoryColor)
                let updatedProduct = existingProduct.copy(category: updatedCateogry)
                handler(ProviderResult(status: .Success, sucessResult: updatedProduct))
                
            } else { // product doesn't exist
                
                // check if a category with given name already exist
                Providers.productCategoryProvider.categoryWithName(category) {result in
                    
                    func onHasCategory(category: ProductCategory) {
                        let newProduct = Product(uuid: NSUUID().UUIDString, name: productName, category: category, brand: brand)
                        handler(ProviderResult(status: .Success, sucessResult: newProduct))
                    }
                    
                    if let existingCategory = result.sucessResult {
                        if updateCategory {
                            let udpatedCategory = existingCategory.copy(color: categoryColor)
                            onHasCategory(udpatedCategory)
                        } else {
                            onHasCategory(existingCategory)
                        }
                        
                    } else if result.status == .NotFound {
                        let newCategory = ProductCategory(uuid: NSUUID().UUIDString, name: category, color: categoryColor)
                        onHasCategory(newCategory)
                        
                    } else {
                        print("Error: ProductProviderImpl.mergeOrCreateProduct: Couldn't fetch category: \(result)")
                        handler(ProviderResult(status: .DatabaseUnknown))
                    }

                }
            }
        }
    }
    
    
    func countProducts(handler: ProviderResult<Int> -> Void) {
        DBProviders.productProvider.countProducts {countMaybe in
            if let count = countMaybe {
                handler(ProviderResult(status: .Success, sucessResult: count))
            } else {
                QL4("No count")
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func storesContainingText(text: String, _ handler: ProviderResult<[String]> -> Void) {
        DBProviders.productProvider.storesContainingText(text) {stores in
            handler(ProviderResult(status: .Success, sucessResult: stores))
        }
    }
    
    func storesContainingText(text: String, range: NSRange, _ handler: ProviderResult<[String]> -> Void) {
        DBProviders.productProvider.storesContainingText(text, range: range) {stores in
            handler(ProviderResult(status: .Success, sucessResult: stores))
        }
    }
    
    func removeStore(name: String, remote: Bool, _ handler: ProviderResult<Any> -> Void) {
        dbProvider.removeStore(name) {success in
            if success {
                // Trigger to reload items from database to see updated brands
                Providers.listItemsProvider.invalidateMemCache()
                Providers.inventoryItemsProvider.invalidateMemCache()
                
                //TODO!!!! server
            }
            handler(ProviderResult(status: success ? .Success : .Unknown))
        }
    }
}
