//
//  ManageProductCategoryCell.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ManageProductCategoryCell: UITableViewCell {
    
    @IBOutlet weak var categoryNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    var item: ItemWithCellAttributes<ProductCategory>? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    categoryNameLabel.attributedText = item.item.name.makeAttributed(boldRange, normalFont: Fonts.regularLight, font: Fonts.regularBold)
                } else {
                    categoryNameLabel.text = item.item.name
                }
                backgroundColor = item.item.color.withAlphaComponent(0.5)
            }
        }
    }
}
