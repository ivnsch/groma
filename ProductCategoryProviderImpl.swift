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
    
    func categoryWithName(name: String, _ handler: ProviderResult<ProductCategory> -> Void) {
        dbProductProvider.categoryWithName(name) {categoryMaybe in
            if let category = categoryMaybe {
                handler(ProviderResult(status: .Success, sucessResult: category))
            } else {
                handler(ProviderResult(status: .NotFound))
            }
        }
    }
    
    func categorySuggestions(handler: ProviderResult<[Suggestion]> -> ()) {
        dbProductProvider.loadCategorySuggestions {dbSuggestions in
            handler(ProviderResult(status: ProviderStatusCode.Success, sucessResult: dbSuggestions))
        }
    }
}