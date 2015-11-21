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

    var item: QuickAddProduct? {
        didSet {
            if let item = item {
                nameLabel.text = item.labelText
                contentView.backgroundColor = item.product.category.color.colorWithAlphaComponent(0.5)
                nameLabel.textColor = UIColor.darkTextColor()
            }
        }
    }
}