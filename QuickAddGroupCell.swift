//
//  QuickAddGroupCell.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class QuickAddGroupCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var item: QuickAddItem? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.labelText.makeAttributed(boldRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
                } else {
                    nameLabel.text = item.labelText
                }
                contentView.layer.cornerRadius = DimensionsManager.quickAddCollectionViewCellCornerRadius
                contentView.backgroundColor = item.color
                
                let color = UIColor.white
//                let color = UIColor.whiteColor()
                
                nameLabel.textColor = color
            }
        }
    }
}
