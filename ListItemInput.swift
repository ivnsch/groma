//
//  ListItemInput.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Foundation

// TODO rename this is a generic input container from quick add that is used now not only in listitems but groups, inventory and products screen.
struct ListItemInput {
    
    let name: String
    let quantity: Int
    let section: String
    let sectionColor: UIColor
    let note: String?
    let brand: String
    let storeProductInput: StoreProductInput
    
    init(name: String, quantity: Int, price: Float, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: StoreProductUnit, brand: String) {
        self.name = name
        self.quantity = quantity
        self.section = section
        self.sectionColor = sectionColor
        self.note = note
        self.brand = brand
        self.storeProductInput = StoreProductInput(price: price, baseQuantity: baseQuantity, unit: unit)
    }
}