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
    
    var product: Product? {
        didSet {
            if let product = product {
                productNameLabel.text = product.name
                productCategoryLabel.text = product.category
                productPriceLabel.text = product.price.toLocalCurrencyString()
            }
        }
    }
}