//
//  ManageBrandsCell.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class ManageBrandsCell: UITableViewCell {
    
    @IBOutlet weak var brandNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    var item: ItemWithCellAttributes<String>? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    brandNameLabel.attributedText = item.item.makeAttributed(boldRange, normalFont: Fonts.regularLight, font: Fonts.regularBold)
                } else {
                    brandNameLabel.text = item.item
                }
            }
        }
    }
}
