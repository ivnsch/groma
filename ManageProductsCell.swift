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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    var product: ItemWithCellAttributes<Product>? {
        didSet {
            if let product = product {
                let productNameTranslation = NSLocalizedString(product.item.name, comment: "")
                if let boldRange = product.boldRange {
                    productNameLabel.attributedText = productNameTranslation.makeAttributedBoldRegular(boldRange)
                } else {
                    productNameLabel.text = productNameTranslation
                }
                
                productCategoryLabel.text = NSLocalizedString(product.item.category.name, comment: "")
                productPriceLabel.text = product.item.price.toLocalCurrencyString()
            }
        }
    }
}