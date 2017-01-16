//
//  QuickAddProduct.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class QuickAddProduct: QuickAddItem {

    public let product: QuantifiableProduct
    
    // TODO better implementation than passing this additionally to product, which is used only when quick add is used for list items
    public let storeProduct: StoreProduct?
    
    // used in list items, where we shows section color if available, instead of category color. A better solution for this may be implementing a new QuickAddItem subclass but for now like this.
    public let colorOverride: UIColor?
    
    public init(_ product: QuantifiableProduct, colorOverride: UIColor? = nil, storeProduct: StoreProduct? = nil, boldRange: NSRange? = nil) {
        self.product = product
        self.storeProduct = storeProduct
        self.colorOverride = colorOverride
        super.init(boldRange: boldRange)
    }
    
    public override var labelText: String {
        return product.product.name
    }
    
    public override var label2Text: String {
        return product.product.brand
    }
    
    // TODO!!!!!!!!!!!!!!!!! (not related with quantifiable prods refactoring but important) review this - is the store always showing? the store should not show when we are in a store-specific list! (if items have a store assigned iirc we should see the items in other stores, but without displayign the store? (i.e. stripped from store-related information)
    public override var label3Text: String {
        return storeProduct?.store ?? ""
    }

    public override var label4Text: String {
        return product.unitText
    }
    
    public override var color: UIColor {
        return colorOverride ?? product.product.category.color
    }
    
    public override func clearBoldRangeCopy() -> QuickAddProduct {
        return QuickAddProduct(product)
    }
    
    public override func same(_ item: QuickAddItem) -> Bool {
        if let productItem = item as? QuickAddProduct {
            return product.same(productItem.product)
        } else {
            return false
        }
    }
}
