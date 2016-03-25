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
    
    override var label2Text: String {
        return product.brand
    }
    
    override var color: UIColor {
        return product.category.color
    }
    
    override func clearBoldRangeCopy() -> QuickAddProduct {
        return QuickAddProduct(product)
    }
    
    override func same(item: QuickAddItem) -> Bool {
        if let productItem = item as? QuickAddProduct {
            return product.same(productItem.product)
        } else {
            return false
        }
    }
}