//
//  ProductWithQuantity.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public protocol ProductWithQuantity2 {
    
    var product: QuantifiableProduct {get}
    
    var quantity: Float {get}
    
    
    // TODO maybe remove these (also from implementations) now that we use Realm everywhere the immutable approach isn't useful
    func incrementQuantityCopy(_ delta: Float) -> Self
    func updateQuantityCopy(_ quantity: Float) -> Self
}
