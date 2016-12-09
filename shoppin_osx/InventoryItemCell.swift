//
//  InventoryItemCell.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol InventoryItemCellDelegate: class {
    // later we will have + / - etc. here
}

class InventoryItemCell: NSTableCellView {
    
    var inventoryItem: InventoryItem? {
        didSet {
            if let inventoryItem = self.inventoryItem {
                self.fill(inventoryItem)
            }
        }
    }
    
    weak var delegate: InventoryItemCellDelegate? // not sure if it makes sense here to declare as weak. The manager does not retain a reference to the cells
    
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var quantityLabel: NSTextField!
    @IBOutlet weak var columnsContainerView: NSView!
    
    private func fill(inventoryItem: InventoryItem) {
        self.nameLabel.stringValue = inventoryItem.product.name
        self.quantityLabel.integerValue = inventoryItem.quantity
    }
}
