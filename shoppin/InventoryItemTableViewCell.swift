//
//  InventoryItemTableViewCell.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol InventoryItemTableViewCellDelegate {
    func onIncrementItemTap(cell: InventoryItemTableViewCell)
    func onDecrementItemTap(cell: InventoryItemTableViewCell)
}

class InventoryItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var inventoryItem: InventoryItem?
    
    var delegate: InventoryItemTableViewCellDelegate?
    var row: Int?
    
    @IBAction func onIncrementTap(sender: UIButton) {
        delegate?.onIncrementItemTap(self)
    }
    
    @IBAction func onDecrementTap(sender: UIButton) {
        delegate?.onDecrementItemTap(self)
    }
}
