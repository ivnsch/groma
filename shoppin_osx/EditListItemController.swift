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

    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var quantityTextField: NSTextField!
    @IBOutlet weak var priceTextField: NSTextField!
    
    @IBOutlet var sectionTextField: HandlingTextField!
    private var currentSectionSearch: String?

    @IBOutlet weak var okButton: NSButton!
    
    private let listItemsProvider = ProviderFactory().listItemProvider
   
    var addTappedFunc: ((ListItemInput) -> ())?
 
    var windowDidLoadFunc: VoidFunction?
    
    lazy var sectionAutosuggestionsViewController: AutosuggestionsTableViewController = {[weak self] in
        
        let viewController = AutosuggestionsTableViewController(suggestionConfirmed: {(suggestion: String) -> () in
            self!.sectionSuggestionSelected(suggestion)
        })!
        
        let resetToOriginalSearch: () -> () = {
            self!.sectionTextField.window?.makeFirstResponder(self!.sectionTextField)
            self!.sectionTextField.stringValue = self!.currentSectionSearch ?? ""
        }
        
        viewController.upAtTopPressed = {
            resetToOriginalSearch()
        }
        
        viewController.exitPressed = {
            self!.sectionAutosuggestionsViewController.view.hidden = true
            resetToOriginalSearch()
        }
        
        viewController.suggestionSelected = {suggestion in
            self!.sectionTextField.stringValue = suggestion
        }
        
        let sectionFrame = self!.sectionTextField.frame
        let h: CGFloat = 100
        viewController.view.frame = CGRectMake(sectionFrame.origin.x, sectionFrame.origin.y - h, sectionFrame.size.width + 50, h)
        self!.window?.contentView.addSubview(viewController.view)
        return viewController
    }()
    
    var modus: EditListItemControllerModus = .Add {
        didSet {
            self.okButton.title = self.modus.okButtonTitle
        }
    }
    
    override func windowDidLoad() {
        let sectionFrame = self.sectionTextField.frame

        sectionFrame.size.height
        
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.windowDidLoadFunc?()
        
        self.initKeyHandler()
        
        self.sectionTextField.delegate = self
    }
    
    private func initKeyHandler() {
        self.sectionTextField.keyUpHandler = {theEvent in
            
            let keyCode = Int(theEvent.keyCode)
            switch keyCode {
            case 126:
                break
            case 125:
                self.sectionAutosuggestionsViewController.goDown()
                return false
            case 53: // esc
                fallthrough
            case 36: // return
                self.sectionAutosuggestionsViewController.view.hidden = true
            default:
                let suggestions = self.listItemsProvider.sections().map{$0.name ?? ""}
                self.sectionAutosuggestionsViewController.suggestions = suggestions //TODO make this async or add a memory cache
                
                let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self.sectionTextField)
                let search: String = {
                    let textFieldStr = self.sectionTextField.stringValue
                    if let completionRange = editor?.selectedRange { // Note: we asume selectedRange is caused by autocompletion
                        return textFieldStr.substringWithRange(Range<String.Index>(start: textFieldStr.startIndex, end: advance(textFieldStr.startIndex, completionRange.location)))
                    } else {
                        return textFieldStr
                    }
                }()
                
                self.currentSectionSearch = search
                self.sectionAutosuggestionsViewController.searchText(search)
                self.sectionAutosuggestionsViewController.view.hidden = false
                
                if keyCode != 51 { // don't autocomplete on backspace
                    
                    if let first = self.sectionAutosuggestionsViewController.filteredSuggestions.first {
                        let firstNSString: NSString = first
                        let range: NSRange = firstNSString.rangeOfString(search, options: .CaseInsensitiveSearch)
                        if range.location == 0 {
                            
                            let highlightRange = NSMakeRange(range.length, count(first) - range.length)
                            
                            self.sectionTextField.stringValue = first
                            let editor = NSApplication.sharedApplication().mainWindow?.fieldEditor(true, forObject: self.sectionTextField)
                            editor!.selectedRange = highlightRange
                        }
                    }
                }
            }
            
            return true
        }
    }

    func control(control: NSControl, textView: NSTextView, completions words: [AnyObject], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [AnyObject] {
        return [] // disable system's autocomplete
    }
    
    override var windowNibName: String? {
        return "EditListItem"
    }
    
    func show(list: List) {
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
    
    private func sectionSuggestionSelected(suggestion: String) {
        self.sectionTextField.stringValue = suggestion
        self.sectionAutosuggestionsViewController.view.hidden = true
        self.sectionTextField.window?.makeFirstResponder(self.sectionTextField)
    }

}
