//
//  QuickAddProduct.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class QuickAddProduct: QuickAddItem {

    let product: Product
    
    init(_ product: Product, boldRange: NSRange? = nil) {
        self.product = product
        super.init(boldRange: boldRange)
    }
    
    override var labelText: String {
        return product.name
    }
    
    override func clearBoldRangeCopy() -> QuickAddProduct {
        return QuickAddProduct(product)
    }
}