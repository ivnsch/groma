//
//  AddListController.swift
//  shoppin
//
//  Created by ischuetz on 07/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class ListInput {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

class AddListController: NSWindowController {
    
    @IBOutlet weak var listNameTextField: NSTextField!
    
    var addTappedFunc: ((ListInput) -> ())?
    
    var windowDidLoadFunc: VoidFunction?
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.windowDidLoadFunc?()
    }
    
    override var windowNibName: String? {
        return "AddListController"
    }
    
    func show() {
        if let window = self.window {
            NSApp.runModalForWindow(window)
        }
    }
    
    @IBAction func addTapped(sender: NSButton) {
        let listName = listNameTextField.stringValue
        let listInput = ListInput(name: listName)
        self.addTappedFunc?(listInput)
    }
    
    @IBAction func cancelTapped(sender: NSButton) {
        self.close()
    }
    
    override func close() {
        NSApp.stopModal()
        super.close()
    }
}

