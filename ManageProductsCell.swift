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
//    @IBOutlet weak var productCategoryLabel: UILabel!
//    @IBOutlet weak var productPriceLabel: UILabel!

    @IBOutlet weak var productNameCenterConstraint: NSLayoutConstraint!

    @IBOutlet weak var categoryColorView: UIView!
    
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
                
//                productCategoryLabel.text = NSLocalizedString(product.item.category.name, comment: "")
                productBrandLabel.text = product.item.brand
                
//                productCategoryLabelTopConstraint.constant = product.item.brand.isEmpty ? 0 : 2
                
                categoryColorView.backgroundColor = product.item.category.color
                
                productNameCenterConstraint.constant = product.item.brand.isEmpty ? 0 : -10
            }
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        func animate(alpha: CGFloat) {
            UIView.animateWithDuration(0.2) {[weak self] in
                self?.categoryColorView.alpha = alpha
            }
        }
        
        if editing {
            animate(0)
        } else {
            animate(1)
        }
    }
}