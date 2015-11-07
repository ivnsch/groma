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

    // TODO delete - use only range
    func products(handler: ProviderResult<[Product]> -> Void) {
        dbProvider.loadProducts {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
    
    func products(range: NSRange, _ handler: ProviderResult<[Product]> -> Void) {
        dbProvider.loadProducts(range) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
    
    func productsContainingText(text: String,  _ handler: ProviderResult<[Product]> -> Void) {
        dbProvider.productsContainingText(text) {products in
            handler(ProviderResult(status: .Success, sucessResult: products))
        }
    }
    
    func product(name: String, handler: ProviderResult<Product> -> ()) {
        dbProvider.loadProductWithName(name) {dbProduct in
            if let dbProduct = dbProduct {
                handler(ProviderResult(status: .Success, sucessResult: dbProduct))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func add(product: Product, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product], update: true) {saved in
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
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
    
    func update(product: Product, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.saveProducts([product], update: true) {saved in
            if saved {
                Providers.listItemsProvider.invalidateMemCache() // reflect product updates in possible referencing list items
            }
            handler(ProviderResult(status: saved ? ProviderStatusCode.Success : ProviderStatusCode.DatabaseUnknown))
        }
    }
    
    func delete(product: Product, _ handler: ProviderResult<Any> -> ()) {
        dbProvider.deleteProductAndDependencies(product) {saved in
            handler(ProviderResult(status: saved ? .Success : .DatabaseUnknown))
        }
    }
    
    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProvider.loadProductSuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }
    
    
    func loadProduct(name: String, handler: ProviderResult<Product> -> ()) {
        dbProvider.loadProductWithName(name) {dbProductMaybe in
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
    
    func mergeOrCreateProduct(productName: String, productPrice: Float, category: String, _ handler: ProviderResult<Product> -> Void) {
        
        // get product and section uuid if they're already in the local db (remember that we assign uuid in the client so this logic has to be in the client)
        loadProduct(productName) {result in
            
            // load product and update or create one
            // if we find a product with the name we update it - this is for the case the user changes the price for an existing product while adding an item
            let productUuidMaybe: String? = {
                if let existingProduct = result.sucessResult {
                    return existingProduct.uuid
                } else {
                    if result.status == .NotFound { // new product
                        return NSUUID().UUIDString
                    } else {
                        print("Error: loading product: \(result.status)")
                        return nil
                    }
                }
            }()
            
            if let productUuid = productUuidMaybe {
                let product = Product(uuid: productUuid, name: productName, price: productPrice, category: category)
                handler(ProviderResult(status: .Success, sucessResult: product))
            } else {
                handler(ProviderResult(status: .DatabaseUnknown))
            }
        }
    }
}
