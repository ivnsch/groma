//
//  InventoryTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

//protocol InventoryTableViewCellDelegate {
//    func onPlusTap()
//    func onMinusTap()
//}

class InventoryTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    //TODO isn't there a clean way to pass the index through, e.g. using the delegate instead of using these closures? (same problem as in ListItemsViewSection)
    //the problem with closures is that maybe we need a lot and it looks kinda messy
    var onPlusTap:(() -> ())!
    var onMinusTap:(() -> ())!
    
    @IBAction func onPlusTap(sender: UIButton) {
        self.onPlusTap()
    }
    
    @IBAction func onMinusTap(sender: UIButton) {
        self.onMinusTap()
    }
}
