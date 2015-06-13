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

class EditListItemController: NSWindowController, NSTextFieldDelegate {

    @IBOutlet weak var nameTextField: AutocompleteTextField!
    @IBOutlet weak var quantityTextField: NSTextField!
    @IBOutlet weak var priceTextField: NSTextField!
    
    @IBOutlet var sectionTextField: AutocompleteTextField!

    @IBOutlet weak var okButton: NSButton!
    
    private let listItemsProvider = ProviderFactory().listItemProvider
   
    var addTappedFunc: ((ListItemInput) -> ())?
 
    var windowDidLoadFunc: VoidFunction?
    
    private var list: List?
    
    var modus: EditListItemControllerModus = .Add {
        didSet {
            self.okButton.title = self.modus.okButtonTitle
        }
    }
    
    
    class ProductsSuggestionsLoader: SuggestionsLoader {
        
        private let listItemsProvider: ListItemProvider
        
        init(listItemsProvider: ListItemProvider) {
            self.listItemsProvider = listItemsProvider
        }
        
        func loadSuggestions(callback: ([String]) -> ()) {
            
            self.listItemsProvider.products {result in
                if let products = result.success {
                    let suggestions = products.map{$0.name}
                    callback(suggestions)
                }
            }
        }
    }
    
    
    class SectionSuggestionsLoader: SuggestionsLoader {
        
        private let listItemsProvider: ListItemProvider
        
        init(listItemsProvider: ListItemProvider) {
            self.listItemsProvider = listItemsProvider
        }
        
        func loadSuggestions(callback: ([String]) -> ()) {
            
            self.listItemsProvider.sections {result in
                if let sections = result.success {
                    let suggestions = sections.map{$0.name}
                    callback(suggestions)
                }
            }
        }
    }
    
    
    override func windowDidLoad() {
        let sectionFrame = self.sectionTextField.frame

        sectionFrame.size.height
        
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.windowDidLoadFunc?()

        self.nameTextField.suggestionsLoader = ProductsSuggestionsLoader(listItemsProvider: self.listItemsProvider)
        self.sectionTextField.suggestionsLoader = SectionSuggestionsLoader(listItemsProvider: self.listItemsProvider)

        self.nameTextField.delegate = self
        self.sectionTextField.delegate = self
    }
    
    func control(control: NSControl, textView: NSTextView, completions words: [AnyObject], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [AnyObject] {
        return [] // disable system's autocomplete
    }
    
    override var windowNibName: String? {
        return "EditListItem"
    }
    
    func show(list: List) {
        self.list = list
        
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
