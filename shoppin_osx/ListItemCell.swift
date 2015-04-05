//
//  ListItemCell.swift
//  shoppin
//
//  Created by ischuetz on 03/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol ListItemCellDelegate: class {
    func rowAddTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowDeleteTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowUpTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowDownTapped(cell: NSTableCellView, listItemRow: ListItemRow)
    func rowEditTapped(cell: NSTableCellView, listItemRow: ListItemRow)
}

class ListItemCell: NSTableCellView {
   
    var listItemRow: ListItemRow? {
        didSet {
            if let listItemRow = self.listItemRow {
                self.fill(listItemRow.listItem)
            }
        }
    }
    
    weak var delegate: ListItemCellDelegate? // not sure if it makes sense here to declare as weak. The manager does not retain a reference to the cells
    
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var quantityLabel: NSTextField!
    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var columnsContainerView: NSView!
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    private func fill(listItem: ListItem) {
        self.nameLabel.stringValue = listItem.product.name
        self.quantityLabel.integerValue = listItem.quantity
        self.priceLabel.floatValue = listItem.product.price
    }
    
    @IBAction func rowAddTapped(sender: NSButton) {
        self.unwrapHelper({self.delegate?.rowAddTapped($0, listItemRow: $1)})
    }
    
    @IBAction func rowDeleteTapped(sender: NSButton) {
        self.unwrapHelper({self.delegate?.rowDeleteTapped($0, listItemRow: $1)})
    }
    
    @IBAction func upTapped(sender: NSButton) {
        self.unwrapHelper({self.delegate?.rowUpTapped($0, listItemRow: $1)})
    }
    
    @IBAction func downTapped(sender: NSButton) {
        self.unwrapHelper({self.delegate?.rowDownTapped($0, listItemRow: $1)})
    }
    
    @IBAction func editTapped(sender: NSButton) {
        self.unwrapHelper({self.delegate?.rowEditTapped($0, listItemRow: $1)})
    }
    
    // helper avoid repeated code to unwrap optionals
    private func unwrapHelper(function:(NSTableCellView, ListItemRow)->()) {
        if let listItemRow = self.listItemRow {
            function(self, listItemRow)
        }
    }
}
