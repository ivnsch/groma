//
//  EditListItemController.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class EditListItemController: NSWindowController {

    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var quantityTextField: NSTextField!
    @IBOutlet weak var priceTextField: NSTextField!
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override var windowNibName: String? {
        return "EditListItem"
    }
    
    func show() {
        if let window = self.window {
            NSApp.beginSheetModalForWindow(window, completionHandler: nil)
           
            NSApp.runModalForWindow(window)
            
            window.endSheet(window)
            window.orderOut(self)
        }
    }
}
