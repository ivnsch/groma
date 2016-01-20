//
//  RealmProductCategoryProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation
import RealmSwift

class RealmProductCategoryProvider: RealmProvider {
    
    func categories(range: NSRange, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, range: range, handler: handler)
    }
    
    func categoriesContainingText(text: String, _ handler: [ProductCategory] -> Void) {
        let mapper = {ProductCategoryMapper.categoryWithDB($0)}
        load(mapper, filter: "name CONTAINS[c] '\(text)'", handler: handler)
    }
    
    func updateCategory(category: ProductCategory, _ handler: Bool -> Void) {
        let dbCategory = ProductCategoryMapper.dbWithCategory(category)
        saveObj(dbCategory, update: true, handler: handler)
    }
    
    func removeCategory(category: ProductCategory, _ handler: Bool -> Void) {
        remove("uuid = '\(category.uuid)'", handler: handler, objType: DBProductCategory.self)
    }
}
