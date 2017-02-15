//
//  ProductProvider.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

public enum ProductSortBy {
    case alphabetic, fav
}

// TODO move product-only method from list item provider here
public protocol ProductProvider {

    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<Product>>) -> Void)
    
    func products(_ range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<Results<QuantifiableProduct>>) -> Void)

    func product(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ())

    func quantifiableProduct(_ unique: QuantifiableProductUnique, handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void)

    func products(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [Product])>) -> Void)

    func quantifiableProducts(_ text: String, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: [QuantifiableProduct])>) -> Void)
    
    func quantifiableProducts(product: Product, _ handler: @escaping (ProviderResult<[QuantifiableProduct]>) -> Void)

    func products(_ nameBrands: [(name: String, brand: String)], _ handler: @escaping (ProviderResult<[Product]>) -> Void)
    
    func productsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: Product, section: Section?)])>) -> Void)
    
    func quantifiableProductsWithPosibleSections(_ text: String, list: List, range: NSRange, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, productsWithMaybeSections: [(product: QuantifiableProduct, section: Section?)])>) -> Void)
    
    func productsRes(_ text: String, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: Results<Product>)>) -> Void)

    func productsRes(_ text: String, sortBy: ProductSortBy, _ handler: @escaping (ProviderResult<(substring: String?, products: Results<QuantifiableProduct>)>) -> Void)

    func products(itemUuid: String, _ handler: @escaping (ProviderResult<Results<Product>>) -> Void)

    func countProducts(_ handler: @escaping (ProviderResult<Int>) -> Void)

    // Note: this does not check name uniqueness! If need to add a new product use add(productInput), this checks name uniqueness
    // TODO remove this method? Does add(productInput) covers all add use cases?
    func add(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    // Upsert based on name
    func add(_ productInput: ProductInput, _ handler: @escaping (ProviderResult<Product>) -> ())
    
    // Update product. Note: This invalidates the list item memory cache, in order to make listitems update stale product references.
    func update(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func add(_ product: QuantifiableProduct, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func update(_ product: QuantifiableProduct, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(_ product: Product, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> ())

    func deleteQuantifiableProduct(uuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(_ productUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func delete(productName: String, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func deleteProductsWith(base: String, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func deleteProductsWith(unit: Unit, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func deleteProductsWith(unitName: String, _ handler: @escaping (ProviderResult<Any>) -> Void)

    
    func incrementFav(quantifiableProductUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)

    func loadProduct(_ name: String, brand: String, handler: @escaping (ProviderResult<Product>) -> ())
    
    func categoriesContaining(_ name: String, _ handler: @escaping (ProviderResult<[String]>) -> ())
    
    func storesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func storesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func removeStore(_ name: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    /**
    Utility method to refactor common code in ListItemsProviderImpl and ProductGroupProviderImpl when adding new list or group items
    Tries to load using unique (name), if existent overrides fields with corresponding input, if not existent creates a new one
    param updateCategory if we want to overwrite the category data if a category with passed name exists already (currently this means updating the color). If the category exists and this value is false, the categoryColor parameter is ignored.
    TODO use results like everywhere else, maybe put in a different specific utility class this is rather provider-internal
    NOTE: doesn't save the new/merged product
    */
//    func mergeOrCreateProduct(_ productName: String, category: String, categoryColor: UIColor, brand: String, updateCategory: Bool, _ handler: @escaping (ProviderResult<Product>) -> Void)
    
    // NOTE: doesn't save the new/merged product
    func mergeOrCreateProduct(prototype: ProductPrototype, updateCategory: Bool, updateItem: Bool, _ handler: @escaping (ProviderResult<Product>) -> Void)
    
    // NOTE: doesn't save the new/merged product
    func mergeOrCreateProduct(prototype: ProductPrototype, updateCategory: Bool, updateItem: Bool, _ handler: @escaping (ProviderResult<QuantifiableProduct>) -> Void)
   
    // Returns if restored at least one product
    func restorePrefillProductsLocal(_ handler: @escaping (ProviderResult<Bool>) -> Void)

    
    func allBaseQuantities(_ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func baseQuantitiesContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void)
    
    func unitsContainingText(_ text: String, _ handler: @escaping (ProviderResult<[String]>) -> Void)
}
