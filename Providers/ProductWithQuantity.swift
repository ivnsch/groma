//
//  ProductWithQuantity.swift
//  shoppin
//
//  Created by ischuetz on 05/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import Foundation

public protocol ProductWithQuantity2 {
    
    var product: Product {get}
    
    var quantity: Int {get}
    
    func incrementQuantityCopy(_ delta: Int) -> Self
    
    func updateQuantityCopy(_ quantity: Int) -> Self
}
