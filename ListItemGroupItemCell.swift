//
//  ListItemGroupItemCell.swift
//  shoppin
//
//  Created by ischuetz on 16/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemGroupItemCellDelegate {
    func onIncrementItemTap(cell: ListItemGroupItemCell, indexPath: NSIndexPath)
    func onDecrementItemTap(cell: ListItemGroupItemCell, indexPath: NSIndexPath)
}

class ListItemGroupItemCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var groupItem: GroupItem? {
        didSet {
            if let groupItem = groupItem {
                nameLabel.text = groupItem.product.name
                quantityLabel.text = String(groupItem.quantity)
            }
        }
    }
    
    var delegate: ListItemGroupItemCellDelegate?
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