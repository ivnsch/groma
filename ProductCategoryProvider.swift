//
//  ProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ProductCategoryProvider {

    func categoryWithName(name: String, _ handler: ProviderResult<ProductCategory> -> Void)
    
    func categoriesContainingText(text: String,  _ handler: ProviderResult<[ProductCategory]> -> Void)
    
    func categories(range: NSRange, _ handler: ProviderResult<[ProductCategory]> -> Void)

    func categoriesContainingText(text: String, range: NSRange, _ handler: ProviderResult<(text: String?, categories: [ProductCategory])> -> Void)
    
    func categorySuggestions(handler: ProviderResult<[Suggestion]> -> ())

    func update(category: ProductCategory, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func remove(category: ProductCategory, remote: Bool, _ handler: ProviderResult<Any> -> Void)
    
    func remove(categoryUuid: String, remote: Bool, _ handler: ProviderResult<Any> -> Void)
}
