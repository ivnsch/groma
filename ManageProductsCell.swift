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
    @IBOutlet weak var productBrandLabel: UILabel!
    @IBOutlet weak var productCategoryLabel: UILabel!
    @IBOutlet weak var productPriceLabel: UILabel!

    @IBOutlet weak var productCategoryLabelTopConstraint: NSLayoutConstraint!
    
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
                productBrandLabel.text = product.item.brand
                productPriceLabel.text = product.item.price.toLocalCurrencyString()
                
                productCategoryLabelTopConstraint.constant = product.item.brand.isEmpty ? 0 : 2
            }
        }
    }
}