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
    
    var product: ProductWithCellAttributes? {
        didSet {
            if let product = product {
                if let boldRange = product.boldRange {
                    productNameLabel.attributedText = product.product.name.makeAttributedBoldRegular(boldRange)
                } else {
                    productNameLabel.text = product.product.name
                }
                
                productCategoryLabel.text = product.product.category
                productPriceLabel.text = product.product.price.toLocalCurrencyString()
            }
        }
    }
}