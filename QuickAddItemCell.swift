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
    
    var item: QuickAddItem? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.labelText.makeAttributed(boldRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
                } else {
                    nameLabel.text = item.labelText
                }

                contentView.layer.cornerRadius = 18
                contentView.backgroundColor = item.color
                
//                let color = UIColor(contrastingBlackOrWhiteColorOn: contentView.backgroundColor, isFlat: true)
                let color = UIColor.whiteColor()
                
                nameLabel.textColor = color
                brandLabel.textColor = color
                brandLabel.text = item.label2Text
                
                nameLabelVerticalCenterContraint.constant = item.label2Text.isEmpty ? 0 : -6
            }
        }
    }
}