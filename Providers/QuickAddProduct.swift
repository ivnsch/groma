//
//  QuickAddProduct.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public class QuickAddProduct: QuickAddItem {

    public let product: Product
    
    // TODO better implementation than passing this additionally to product, which is used only when quick add is used for list items
    public let quantifiableProduct: QuantifiableProduct?
    
    // used in list items, where we shows section color if available, instead of category color. A better solution for this may be implementing a new QuickAddItem subclass but for now like this.
    public let colorOverride: UIColor?
    
    public init(_ product: Product, colorOverride: UIColor? = nil, quantifiableProduct: QuantifiableProduct? = nil, boldRange: NSRange? = nil) {
        self.product = product
        self.quantifiableProduct = quantifiableProduct
        self.colorOverride = colorOverride
        super.init(boldRange: boldRange)
    }
    
    public override var labelText: String {
        return product.item.name
    }
    
    public override var label2Text: String {
        return product.brand
    }
    
    // TODO!!!!!!!!!!!!!!!!! (not related with quantifiable prods refactoring but important) review this - is the store always showing? the store should not show when we are in a store-specific list! (if items have a store assigned iirc we should see the items in other stores, but without displayign the store? (i.e. stripped from store-related information)
    public override var label3Text: String {
//        return storeProduct?.store ?? ""
        return "" // no 3d label anymore. Remove?
    }

    public override var color: UIColor {
        return colorOverride ?? product.item.category.color
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

// TODO put in own file
public class QuickAddDBItem: QuickAddItem {
    
    public let item: Item
    
    // used in list items, where we shows section color if available, instead of category color. A better solution for this may be implementing a new QuickAddItem subclass but for now like this.
    public let colorOverride: UIColor?
    
    public init(_ item: Item, colorOverride: UIColor? = nil, boldRange: NSRange? = nil) {
        self.item = item
        self.colorOverride = colorOverride
        super.init(boldRange: boldRange)
    }
    
    public override var labelText: String {
        return item.name
    }
    
    public override var label2Text: String {
        return ""
    }
    
    // TODO!!!!!!!!!!!!!!!!! (not related with quantifiable prods refactoring but important) review this - is the store always showing? the store should not show when we are in a store-specific list! (if items have a store assigned iirc we should see the items in other stores, but without displayign the store? (i.e. stripped from store-related information)
    public override var label3Text: String {
        return ""
    }
    
    public override var color: UIColor {
        return colorOverride ?? item.category.color
    }
    
    public override func clearBoldRangeCopy() -> QuickAddDBItem {
        return QuickAddDBItem(item)
    }
    
    public override func same(_ item: QuickAddItem) -> Bool {
        if let dbItemItem = item as? QuickAddDBItem {
            return self.item.same(dbItemItem.item)
        } else {
            return false
        }
    }
}
