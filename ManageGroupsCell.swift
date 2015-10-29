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
    
    var group: ListItemGroup? {
        didSet {
            if let group = group {
                groupNameLabel.text = group.name
                groupItemCountLabel.text = "\(group.totalQuantity) items"
                groupPriceLabel.text = group.totalPrice.toLocalCurrencyString()
            }
        }
    }
}