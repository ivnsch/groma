//
//  EditListItemController.swift
//  shoppin
//
//  Created by ischuetz on 28/03/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

enum EditListItemControllerModus {
    case Add, Edit
    
    var okButtonTitle: String {
        switch self {
            case .Add:
                return "Add"
            case .Edit:
                return "Update"
        }
    }
}

class EditListItemController: NSWindowController {

    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var quantityTextField: NSTextField!
    @IBOutlet weak var priceTextField: NSTextField!
    @IBOutlet weak var sectionTextField: NSTextField!
    
    @IBOutlet weak var okButton: NSButton!
    
    private let listItemsProvider = ProviderFactory().listItemProvider
   
    var addTappedFunc: ((ListItemInput) -> ())?
 
    var windowDidLoadFunc: VoidFunction?
    
    var modus: EditListItemControllerModus = .Add {
        didSet {
            self.okButton.title = self.modus.okButtonTitle
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.windowDidLoadFunc?()
    }
    
    override var windowNibName: String? {
        return "EditListItem"
    }
    
    func show(list:List) {
        if let window = self.window {
            NSApp.runModalForWindow(window)
        }
    }
   
    func prefill(listItemInput: ListItemInput) {
        self.nameTextField.stringValue = listItemInput.name
        self.quantityTextField.integerValue = listItemInput.quantity
        self.priceTextField.floatValue = listItemInput.price
        self.sectionTextField.stringValue = listItemInput.section
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
