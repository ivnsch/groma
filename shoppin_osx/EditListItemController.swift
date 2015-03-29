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
    @IBOutlet weak var sectionTextField: NSTextField!
    
    private let listItemsProvider = ProviderFactory().listItemProvider
   
    var addTappedFunc:((ListItemInput) -> ())?
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    override var windowNibName: String? {
        return "EditListItem"
    }
    
    func show(list:List) {
        if let window = self.window {
            NSApp.runModalForWindow(window)
        }
    }
   
    @IBAction func addTapped(sender: NSButton) {

        let name = self.nameTextField.stringValue
        let quantity = self.quantityTextField.integerValue
        let price = self.priceTextField.floatValue
        let sectionName = self.sectionTextField.stringValue
        
        let listItemInput = ListItemInput(name: name, quantity: quantity, price: price, section: sectionName)
        
        self.addTappedFunc?(listItemInput)
    }
    
    override func close() {
        NSApp.stopModal()
        super.close()
    }
}
