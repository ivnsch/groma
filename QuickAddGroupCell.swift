//
//  QuickAddGroupCell.swift
//  shoppin
//
//  Created by ischuetz on 13/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddGroupCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var item: QuickAddGroup? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.labelText.makeAttributed(boldRange, normalFont: Fonts.verySmallLight, font: Fonts.verySmallBold)
                } else {
                    nameLabel.text = item.labelText
                }
                nameLabel.textColor = UIColor.darkTextColor()
                
                contentView.backgroundColor = item.group.bgColor.colorWithAlphaComponent(0.5)
            }
        }
    }
}