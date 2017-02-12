//
//  PlanItemInput.swift
//  shoppin
//
//  Created by ischuetz on 08/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class PlanItemInput {
    
    public let name: String
    public let quantity: Float
    public let price: Float
    public let category: String
    public let categoryColor: UIColor
    public let baseQuantity: Float
    public let unit: String
    public let brand: String
    public let store: String
    
    public init(name: String, quantity: Float, price: Float, category: String, categoryColor: UIColor, baseQuantity: Float, unit: String, brand: String, store: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.category = category
        self.categoryColor = categoryColor
        self.baseQuantity = baseQuantity
        self.unit = unit
        self.brand = brand
        self.store = store
    }
}
