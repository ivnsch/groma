//
//  ListItemGroupCell.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemGroupCellDelegate {
    func onIncrementItemTap(cell: ListItemGroupCell, indexPath: NSIndexPath)
    func onDecrementItemTap(cell: ListItemGroupCell, indexPath: NSIndexPath)
}

// Convenience holder for group plus a quantity which is only relevant for this controller / temporary. If user presses ok, items corresponding to group quantity are added to list, if cancel, the groups quantities are resetted.
struct ListItemGroupWithQuantity {
    let group: ListItemGroup
    var quantity: Int
    
    init(group: ListItemGroup, quantity: Int) {
        self.group = group
        self.quantity = quantity
    }
}

class ListItemGroupCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var group: ListItemGroupWithQuantity? {
        didSet {
            if let group = group {
                nameLabel.text = group.group.name
                quantityLabel.text = String(group.quantity)
            }
        }
    }

    var delegate: ListItemGroupCellDelegate?
    var indexPath: NSIndexPath?
    
    @IBAction func onPlusTap(sender: UIButton) {
        if let indexPath = indexPath {
            delegate?.onIncrementItemTap(self, indexPath: indexPath)
        } else {
            print("No indexPath in onPlusTap!")
        }
    }
    
    @IBAction func onMinusTap(sender: UIButton) {
        if let indexPath = indexPath {
            delegate?.onDecrementItemTap(self, indexPath: indexPath)
        } else {
            print("No indexPath in onMinusTap!")
        }
    }
}