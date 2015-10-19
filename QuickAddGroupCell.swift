//
//  QuickAddGroupCell.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class QuickAddGroupCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    var item: QuickAddGroup? {
        didSet {
            if let item = item {
                nameLabel.text = item.labelText
            }
        }
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
