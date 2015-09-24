//
//  ProductSuggestionMapper.swift
//  shoppin
//
//  Created by ischuetz on 24/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class ProductSuggestionMapper {

    class func dbWithProduct(product: Product) -> DBProductSuggestion {
        let dbSuggestion = DBProductSuggestion()
        dbSuggestion.name = product.name
        return dbSuggestion
    }

    class func dbWithSuggestion(suggestion: Suggestion) -> DBProductSuggestion {
        let dbSuggestion = DBProductSuggestion()
        dbSuggestion.name = suggestion.name
        return dbSuggestion
    }
    
    class func suggestionWithDB(dbSuggestion: DBProductSuggestion) -> Suggestion {
        return Suggestion(name: dbSuggestion.name)
    }
}
