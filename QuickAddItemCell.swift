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
    @IBOutlet weak var storeLabel: UILabel!
    
    @IBOutlet weak var nameLabelVerticalCenterContraint: NSLayoutConstraint!
    
    var item: QuickAddItem? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.labelText.makeAttributed(boldRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
                } else {
                    nameLabel.text = item.labelText
                }

                let nameCenterConstant: CGFloat = {
                    if item.label2Text.isEmpty && item.label3Text.isEmpty { // no brand and store - show name in the middle
                        return 0
                    } else if !item.label2Text.isEmpty && !item.label3Text.isEmpty { // brand and store - show name at the top
                        return -12
                    } else { // brand or store (only one of them) - show name a bit up
                        return -6
                    }
                }()
                
                contentView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
                contentView.backgroundColor = item.color
                
                let color = UIColor(contrastingBlackOrWhiteColorOn: item.color, isFlat: true)
//                let color = UIColor.whiteColor()
                
                nameLabel.textColor = color
                brandLabel.textColor = color
                storeLabel.textColor = color
                
                brandLabel.text = item.label2Text
                storeLabel.text = item.label3Text
                
                nameLabelVerticalCenterContraint.constant = nameCenterConstant
//                    item.label2Text.isEmpty ? 0 : -6
            }
        }
    }
}
