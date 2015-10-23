//
//  GroupItemInput.swift
//  shoppin
//
//  Created by ischuetz on 15/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

struct GroupItemInput: Equatable, Hashable {
    
    let name: String
    let quantity: Int
    let price: Float
    let section: String
    
    init(name: String, quantity: Int, price: Float, section: String) {
        self.name = name
        self.quantity = quantity
        self.price = price
        self.section = section
    }
    
    var hashValue: Int {
        return name.hashValue
    }
    
    func copy(name name: String? = nil, quantity: Int? = nil, price: Float? = nil, section: String? = nil) -> GroupItemInput {
        return GroupItemInput(
            name: name ?? self.name,
            quantity: quantity ?? self.quantity,
            price: price ?? self.price,
            section: section ?? self.section
        )
    }
}

func ==(lhs: GroupItemInput, rhs: GroupItemInput) -> Bool {
    return lhs.name == rhs.name && lhs.quantity == rhs.quantity && lhs.price == rhs.price && lhs.section == rhs.section
}
