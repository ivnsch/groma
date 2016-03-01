//
//  ProductCategoryProviderImpl.swift
//  shoppin
//
//  Created by ischuetz on 20/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ProductCategoryProviderImpl: ProductCategoryProvider {

    private let dbProductProvider = RealmProductProvider()
    private let dbCategoryProvider = RealmProductCategoryProvider()

    func categoryWithName(name: String, _ handler: ProviderResult<ProductCategory> -> Void) {
        dbProductProvider.categoryWithName(name) {categoryMaybe in
            if let category = categoryMaybe {
                handler(ProviderResult(status: .Success, sucessResult: category))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func categoriesContainingText(text: String,  _ handler: ProviderResult<[ProductCategory]> -> Void) {
        dbCategoryProvider.categoriesContainingText(text) {categories in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: categories))
        }
    }
    
    func categoriesContainingText(text: String, range: NSRange, _ handler: ProviderResult<(text: String?, categories: [ProductCategory])> -> Void) {
        dbCategoryProvider.categoriesContainingText(text, range: range) {categories in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: categories))
        }
    }

    func categorySuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProductProvider.loadCategorySuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }
    
    func categories(range: NSRange, _ handler: ProviderResult<[ProductCategory]> -> Void) {
        dbCategoryProvider.categories(range) {categories in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: categories))
        }
    }
    
    func update(category: ProductCategory, _ handler: ProviderResult<Any> -> Void) {
        dbCategoryProvider.updateCategory(category) {success in
           handler(ProviderResult(status: success ? .Success : .Unknown))
        }
    }
    
    func remove(category: ProductCategory, _ handler: ProviderResult<Any> -> Void) {
        dbCategoryProvider.removeCategory(category, markForSync: true) {success in
            handler(ProviderResult(status: success ? .Success : .Unknown))
        }
    }
}