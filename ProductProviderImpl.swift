//
//  ProductProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO move product-only method from list item provider here
class ProductProviderImpl: ProductProvider {

    let dbProvider = RealmListItemProvider()
    let dbBrandProvider = RealmBrandProvider()
    let productDbProvider = RealmProductProvider()

    func products(range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<[Product]> -> Void) {
        dbProvider.loadProducts(range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
    
    func products(text: String, range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<(substring: String?, products: [Product])> -> Void) {
        dbProvider.products(text, range: range, sortBy: sortBy) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }

    func product(name: String, brand: String, handler: ProviderResult<Product> -> ()) {
        dbProvider.loadProductWithName(name, brand: brand) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func add(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product], update: true) {saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
            
            if saved {
                if remote {
                    // TODO server
                }
            }
        }
    }

    func add(productInput: ProductInput, _ handler: ProviderResult<Product> -> ()) {
        dbProvider.saveProduct(productInput, update: true) {productMaybe in
            if let product = productMaybe {
                handler(ProviderResult(status: .Success, sucessResult: product))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
    
    func update(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product], update: true) {saved in
            if saved {
                Providers.listItemsProvider.invalidateMemCache() // reflect product updates in possible referencing list items
                
                if remote {
                    // TODO server
                }
            }
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func delete(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.deleteProductAndDependencies(product) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if remote {
                // TODO server
            }
        }
    }
    
    func incrementFav(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        productDbProvider.incrementFav(product, {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
            
            if remote {
                // TODO server
            }
        })
    }
    
    func updateFav(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product], update: true) {saved in
            if saved {
                if remote {
                    // TODO server
                }
            }
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func incrementFav(product: Product, _ handler: ProviderResult<Any> -> Void) {
        let incrementedProduct = product.copy(fav: product.fav + 1)
        dbProvider.saveProducts([incrementedProduct], updateSuggestions: false) {saved in // we are only incrementing a(n existing) product, so update suggestions doesn't make sense
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
        }
    }
    
    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProvider.loadProductSuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }
    
    
    func loadProduct(name: String, brand: String, handler: ProviderResult<Product> -> ()) {
        dbProvider.loadProductWithName(name, brand: brand) {dbProductMaybe in
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
        dbProvider.categoriesContaining(name) {dbCategories in
            handler(ProviderResult(status: .Success, sucessResult: dbCategories))
        }
    }

    func mergeOrCreateProduct(productName: String, productPrice: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, _ handler: ProviderResult<Product> -> Void) {

        // load product and update or create one
        // if we find a product with the name we update it - this is for the case the user changes the price etc for an existing product while adding an item
        loadProduct(productName, brand: brand ?? "") {result in
            if let existingProduct = result.sucessResult {
                let updatedCateogry = existingProduct.category.copy(name: category, color: categoryColor)
                let updatedProduct = existingProduct.copy(name: productName, price: productPrice, category: updatedCateogry, baseQuantity: baseQuantity, unit: unit)
                handler(ProviderResult(status: .Success, sucessResult: updatedProduct))
                
            } else { // product doesn't exist
                
                // check if a category with given name already exist
                Providers.productCategoryProvider.categoryWithName(category) {result in
                    
                    func onHasCategory(category: ProductCategory) {
                        let newProduct = Product(uuid: NSUUID().UUIDString, name: productName, price: productPrice, category: category, baseQuantity: baseQuantity, unit: unit, brand: brand)
                        handler(ProviderResult(status: .Success, sucessResult: newProduct))
                    }
                    
                    if let existingCategory = result.sucessResult {
                        let udpatedCategory = existingCategory.copy(name: category, color: categoryColor)
                        onHasCategory(udpatedCategory)
                        
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
}
