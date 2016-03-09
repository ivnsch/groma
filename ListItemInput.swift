//
//  ListItemInput.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct ListItemInput {
    
    let name: String
    let quantity: Int
    let price: Float
    let category: String
    let categoryColor: UIColor
    let section: String
    let note: String?
    let baseQuantity: Float
    let unit: ProductUnit
    let brand: String
    let store: String
    
    init(name: String, quantity: Int, price: Float, category: String, categoryColor: UIColor, section: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.section = section
        self.note = note
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
}