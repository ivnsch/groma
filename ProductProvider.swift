//
//  ProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum ProductSortBy {
    case alphabetic, fav
}

// TODO move product-only method from list item provider here
protocol ProductProvider {

    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<[Product]>) -> Void)
    
    func product(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ())

    func products(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [Product])>) -> Void)

    func products(_ nameBrands: [(name: String, brand: String)], _ handler: @escaping (ProviderResult<[Product]>) -> Void)
    
    func productsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)])>) -> Void)
    
    func countProducts(_ handler: @escaping (ProviderResult<Int>) -> Void)

    // Note: this does not check name uniqueness! If need to add a new product use add(productInput), this checks name uniqueness
    // TODO remove this method? Does add(productInput) covers all add use cases?
    func add(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    // Upsert based on name
    func add(_ productInput: ProductInput, _ handler: @escaping (ProviderResult<Product>) -> ())
    
    // Update product. Note: This invalidates the list item memory cache, in order to make listitems update stale product references.
    func update(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func delete(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func delete(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func incrementFav(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func loadProduct(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ())
    
    func categoriesContaining(_ name: String, _ handler: @escaping (ProviderResult<[String]>) -> ())
    
    func storesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func removeStore(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ListItemGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    param updateCategory if we want to overwrite the category data if a category with passed name exists already (currently this means updating the color). If the category exists and this value is false, the categoryColor parameter is ignored.
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    */
    func mergeOrCreateProduct(_ productName: String, category: String, categoryColor: UIColor, brand: String, updateCategory: Bool, _ handler: @escaping (ProviderResult<Product>) -> Void)
    
    // Returns if restored at least one product
    func restorePrefillProductsLocal(_ handler: @escaping (ProviderResult<Bool>) -> Void)
}
