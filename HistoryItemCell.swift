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
    @IBOutlet weak var itemUnitLabel: UILabel!
    @IBOutlet weak var itemPriceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}
