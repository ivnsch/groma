//
//  ManageGroupsCell.swift
//  shoppin
//
//  Created by ischuetz on 29/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ManageGroupsCell: UITableViewCell {

    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var groupItemCountLabel: UILabel!
    @IBOutlet weak var groupPriceLabel: UILabel!
    
    var group: ItemWithCellAttributes<ListItemGroup>? {
        didSet {
            if let group = group {
                if let boldRange = group.boldRange {
                    groupNameLabel.attributedText = group.item.name.makeAttributedBoldRegular(boldRange)
                } else {
                    groupNameLabel.text = group.item.name
                }
                groupItemCountLabel.text = "\(group.item.totalQuantity) items"
                groupPriceLabel.text = group.item.totalPrice.toLocalCurrencyString()
            }
        }
    }
}