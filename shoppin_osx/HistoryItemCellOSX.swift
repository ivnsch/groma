//
//  HistoryItemCell.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol HistoryItemCellDelegate: class {
    // possible actions later to edit, remove, etc
}

// Needed OSX ending because it was showing outlets of ios HistoryItemCell in storyboard (despite having set module to osx)
class HistoryItemCellOSX: NSTableCellView {
    
    var historyItem: HistoryItem? {
        didSet {
            if let historyItem = self.historyItem {
                self.fill(historyItem)
            }
        }
    }
    
    weak var delegate: HistoryItemCellDelegate? // not sure if it makes sense here to declare as weak. The manager does not retain a reference to the cells
    
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var quantityLabel: NSTextField!
    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var userLabel: NSTextField!
    
    @IBOutlet weak var columnsContainerView: NSView!
    
    private func fill(historyItem: HistoryItem) {
        self.nameLabel.stringValue = historyItem.product.name
        self.quantityLabel.integerValue = historyItem.quantity
        self.priceLabel.stringValue = "\(historyItem.product.price)"
        self.dateLabel.stringValue = "\(historyItem.addedDate)"
        self.userLabel.stringValue = historyItem.user.email
    }
}