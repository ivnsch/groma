//
//  ProductInput.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

final class ProductInput: CustomDebugStringConvertible {

    let name: String
    let price: Float
    let category: String
    let categoryColor: UIColor
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    let store: String
    
    init(name: String, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.name = name
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
    
    var debugDescription: String {
        return "{\(self.dynamicType) name: \(name), price: \(price), category: \(category), categoryColor: \(categoryColor), baseQuantity: \(baseQuantity), unit: \(unit), brand: \(brand), store: \(store)}"
    }
}