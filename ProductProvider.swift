//
//  ProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum ProductSortBy {
    case Alphabetic, Fav
}

// TODO move product-only method from list item provider here
protocol ProductProvider {

    func products(range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<[Product]> -> Void)
    
    func product(name: String, brand: String, store: String, handler: ProviderResult<Product> -> ())

    func products(text: String, range: NSRange, sortBy: ProductSortBy, _ handler: ProviderResult<(substring: String?, products: [Product])> -> Void)
    
    func countProducts(handler: ProviderResult<Int> -> Void)

    // Note: this does not check name uniqueness! If need to add a new product use add(productInput), this checks name uniqueness
    // TODO remove this method? Does add(productInput) covers all add use cases?
    func add(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ())

    // Upsert based on name
    func add(productInput: ProductInput, _ handler: ProviderResult<Product> -> ())
    
    // Update product. Note: This invalidates the list item memory cache, in order to make listitems update stale product references.
    func update(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ())

    // Updates product without invalidating list item memory cache (opposed to the normal update method). Since fav doesn't affect listitems. 
    // WARN: This still does a full update of the product, there doesn't seem to be a way with Realm to update only the fav field (which is all we want to do in this method) and server currently also does a full update. So use only when you are sure that only the fav field changed!
    func updateFav(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func incrementFav(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func delete(product: Product, remote: Bool, _ handler: ProviderResult<Any> -> ())

    func delete(productUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func incrementFav(product: Product, _ handler: ProviderResult<Any> -> Void)

    func productSuggestions(handler: ProviderResult<[Suggestion]> -> ())
    
    func loadProduct(name: String, brand: String, store: String, handler: ProviderResult<Product> -> ())
    
    func categoriesContaining(name: String, _ handler: ProviderResult<[String]> -> ())
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    param updateCategory if we want to overwrite the category data if a category with passed name exists already (currently this means updating the color). If the category exists and this value is false, the categoryColor parameter is ignored.
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    */
    func mergeOrCreateProduct(productName: String, productPrice: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String, updateCategory: Bool, _ handler: ProviderResult<Product> -> Void)
}