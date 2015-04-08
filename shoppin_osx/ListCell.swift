//
//  ListCell.swift
//  shoppin
//
//  Created by ischuetz on 08/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol ListCellDelegate {
    func removeListTapped(cell: ListCell)
}

class ListCell: NSTableCellView {
   
    var list: List? {
        didSet {
            if let list = self.list {
                self.fill(list)
            }
        }
    }
    
    @IBOutlet weak var nameLabel: NSTextField!
    
    var delegate: ListCellDelegate?

    private func fill(list: List) {
        self.nameLabel.stringValue = list.name
    }
    
    @IBAction func removeTapped(sender: NSButton) {
        self.delegate?.removeListTapped(self)
    }
}
