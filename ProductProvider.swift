//
//  ProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO move product-only method from list item provider here
protocol ProductProvider {

    // TODO remove only ranged
    func products(handler: ProviderResult<[Product]> -> Void)

    func products(range: NSRange, _ handler: ProviderResult<[Product]> -> Void)
    
    func product(name: String, handler: ProviderResult<Product> -> ())
    
    // filter by name, containing text
    func productsContainingText(text: String,  _ handler: ProviderResult<[Product]> -> Void)

    // Note: this does not check name uniqueness! If need to add a new product use add(productInput), this checks name uniqueness
    // TODO remove this method? Does add(productInput) covers all add use cases?
    func add(product: Product, _ handler: ProviderResult<Any> -> ())

    // Upsert based on name
    func add(productInput: ProductInput, _ handler: ProviderResult<Product> -> ())
    
    func update(product: Product, _ handler: ProviderResult<Any> -> ())

    func delete(product: Product, _ handler: ProviderResult<Any> -> ())

    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ())
    
    func loadProduct(name: String, handler: ProviderResult<Product> -> ())
    
    func categoriesContaining(name: String, _ handler: ProviderResult<[String]> -> ())

    /**
    Utility method to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    */
    func mergeOrCreateProduct(productName: String, productPrice: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, _ handler: ProviderResult<Product> -> Void)
}