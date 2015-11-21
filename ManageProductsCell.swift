//
//  ManageProductsCell.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ManageProductsCell: UITableViewCell {

    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productCategoryLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!
    
    var product: ItemWithCellAttributes<Product>? {
        didSet {
            if let product = product {
                if let boldRange = product.boldRange {
                    productNameLabel.attributedText = product.item.name.makeAttributedBoldRegular(boldRange)
                } else {
                    productNameLabel.text = product.item.name
                }
                
                productCategoryLabel.text = product.item.category.name
                productPriceLabel.text = product.item.price.toLocalCurrencyString()
            }
        }
    }
}