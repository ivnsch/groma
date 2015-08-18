//
//  HistoryItemCell.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class HistoryItemCell: UITableViewCell {

    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemQuantityLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    @IBOutlet weak var itemDateLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
