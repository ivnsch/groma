//
//  ManageProductsCell.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageProductsCell: UITableViewCell {

    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productBrandLabel: UILabel!

    @IBOutlet weak var productNameCenterConstraint: NSLayoutConstraint!

    @IBOutlet weak var categoryColorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func setProduct(product: QuantifiableProduct, bold: String?) {
        
        let productNameTranslation = NSLocalizedString(product.product.name, comment: "")
        
        if let boldRange = bold.flatMap({product.product.name.range($0, caseInsensitive: true)}) {
            productNameLabel.attributedText = productNameTranslation.makeAttributedBoldRegular(boldRange)
        } else {
            productNameLabel.text = productNameTranslation
        }
        
        productBrandLabel.text = product.product.brand
        
        categoryColorView.backgroundColor = product.product.category.color
        
        productNameCenterConstraint.constant = product.product.brand.isEmpty ? 0 : -10
        
        // TODO!!!!!!!!!!!!!!!!!!! show unit/base quantity
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        func animate(_ alpha: CGFloat) {
            UIView.animate(withDuration: 0.2, animations: {[weak self] in
                self?.categoryColorView.alpha = alpha
            }) 
        }
        
        if editing {
            animate(0)
        } else {
            animate(1)
        }
    }
}
