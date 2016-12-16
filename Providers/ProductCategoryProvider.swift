//
//  ProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import RealmSwift

public protocol ProductCategoryProvider {

    func categoryWithName(_ name: String, _ handler: @escaping (ProviderResult<ProductCategory>) -> Void)
    
    // TODO maybe remove category with name and let only this, optional is better than .NotFound status, at least in this case
    func categoryWithNameOpt(_ name: String, _ handler: @escaping (ProviderResult<ProductCategory?>) -> Void)

    func categoriesContainingText(_ text: String,  _ handler: @escaping (ProviderResult<Results<ProductCategory>>) -> Void)
    
    func categories(_ range: NSRange, _ handler: @escaping (ProviderResult<Results<ProductCategory>>) -> Void)

    func categoriesContainingText(_ text: String, range: NSRange, _ handler: @escaping (ProviderResult<(text: String?, categories: Results<ProductCategory>)>) -> Void)
    
    func categorySuggestions(_ handler: @escaping (ProviderResult<[Suggestion]>) -> ())

    func update(_ category: ProductCategory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func remove(_ category: ProductCategory, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func remove(_ categoryUuid: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
    
    func removeAllCategoriesWithName(_ categoryName: String, remote: Bool, _ handler: @escaping (ProviderResult<Any>) -> Void)
}
