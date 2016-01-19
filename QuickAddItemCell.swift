//
//  QuickAddItemCell.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework

class QuickAddItemCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var brandLabel: UILabel!
    
    @IBOutlet weak var nameLabelVerticalCenterContraint: NSLayoutConstraint!
    
    var item: QuickAddProduct? {
        didSet {
            if let item = item {
                nameLabel.text = NSLocalizedString(item.labelText, comment: "")
                contentView.backgroundColor = item.product.category.color.colorWithAlphaComponent(0.5)
                let color = UIColor.darkTextColor()
                nameLabel.textColor = color
                brandLabel.textColor = color
                brandLabel.text = item.product.brand
                
                nameLabelVerticalCenterContraint.constant = item.product.brand.isEmpty ? 0 : -6
            }
        }
    }
}