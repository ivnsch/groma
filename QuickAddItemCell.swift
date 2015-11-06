//
//  QuickAddItemCell.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddItemCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    var item: QuickAddProduct? {
        didSet {
            if let item = item {
                if let boldRange = item.boldRange {
                    nameLabel.attributedText = item.product.name.makeAttributedBoldRegular(boldRange)
                } else {
                    nameLabel.text = item.product.name
                }
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
