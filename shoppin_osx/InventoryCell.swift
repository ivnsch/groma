//
//  InventoryCell.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol InventoryCellDelegate: class {
    func removeInventoryTapped(cell: InventoryCell)
}

class InventoryCell: NSTableCellView {
    
    var inventory: Inventory? {
        didSet {
            if let inventory = self.inventory {
                self.fill(inventory)
            }
        }
    }
    
    @IBOutlet weak var nameLabel: NSTextField!
    
    weak var delegate: InventoryCellDelegate?
    
    private func fill(inventory: Inventory) {
        self.nameLabel.stringValue = inventory.name
    }
    
    @IBAction func removeTapped(sender: NSButton) {
        self.delegate?.removeInventoryTapped(self)
    }
}
