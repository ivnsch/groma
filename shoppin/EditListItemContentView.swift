//
//  EditListItemContentView.swift
//  shoppin
//
//  Created by ischuetz on 03/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator


enum AddModus {
    case Add, Update // TODO do we need this? (legacy from AddItemView)
}

protocol EditListItemContentViewDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onOkTap(name: String, price: String, quantity: String, sectionName: String)
    func onOkAndAddAnotherTap(name: String, price: String, quantity: String, sectionName: String)
    func onUpdateTap(name: String, price: String, quantity: String, sectionName: String)
    func onSectionInputChanged(text: String)
    func onProductNameInputChanged(text: String)
}

private enum Action {
    case OkAndAddAnother, Ok
}

class EditListItemContentView: UIView, UITextFieldDelegate {

    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var sectionInput: UITextField!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    private var validator: Validator?

    private var addModus: AddModus = .Add {
        didSet {
            if addModus == .Add {
                okButtonEditModus.hidden = true
                buttonsContainerAddModus.hidden = false
            } else {
                okButtonEditModus.hidden = false
                buttonsContainerAddModus.hidden = true
            }
        }
    }
    
    @IBOutlet weak var okButtonEditModus: UIButton!
    @IBOutlet weak var buttonsContainerAddModus: UIView!
    
    var delegate: EditListItemContentViewDelegate?

    lazy var sectionAutosuggestionsViewController: AutosuggestionsTableViewController = {[weak self] in
        
        let frame = self!.sectionAutosuggestionsFrame(self!)
        
        let viewController = AutosuggestionsTableViewController(frame: frame)
        viewController.onSuggestionSelected = {[weak self] in
            self!.onSectionSuggestionSelected($0)
        }
        
        self!.addSubview(viewController.view)

        return viewController
    }()
    
    lazy var productAutosuggestionsViewController: AutosuggestionsTableViewController = {[weak self] in
        
        let frame = self!.productAutosuggestionsFrame(self!)
        
        let viewController = AutosuggestionsTableViewController(frame: frame)
        viewController.onSuggestionSelected = {
            self!.onProductSuggestionSelected($0)
        }
        
        self!.addSubview(viewController.view)
        
        return viewController
    }()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initValidator()
        
        setInputsDefaultValues()
//        
        nameInput.placeholder = "Item name"
        sectionInput.placeholder = "Section (optional)"
        
        sectionInput.delegate = self
        sectionInput.addTarget(self, action: "sectionInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        
        nameInput.delegate = self
        nameInput.addTarget(self, action: "productNameInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        
        addDismissKeyboardTapRecognizer()
    }
    
    private func addDismissKeyboardTapRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        tapRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(tapRecognizer)
    }
    
    func setUpdateItem(listItem:ListItem) {
        addModus = .Update
        prefill(listItem)
    }
    
    private func prefill(listItem: ListItem) {
        nameInput.text = listItem.product.name
        sectionInput.text = listItem.section.name
        quantityInput.text = String(listItem.quantity)
        priceInput.text = listItem.product.price.toString(2)
    }
    
    private func setInputsDefaultValues() {
        quantityInput.text = "1"
    }
    
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(sectionInput, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
        self.validator = validator
    }
    

    // Press on "ok" in add modus as well as edit
    @IBAction func onOkTap(sender: UIButton) {
        submit(.Ok)
    }
    
    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
    private func submit(action: Action) {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
                delegate?.onValidationErrors(errors)
            }
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let text = nameInput.text, priceText = priceInput.text, quantityText = quantityInput.text, sectionText = sectionInput.text {
                switch addModus {
                case .Add:
                    switch action {
                    case .Ok:
                        delegate?.onOkTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
                    case .OkAndAddAnother:
                        delegate?.onOkAndAddAnotherTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
                    }
                case .Update:
                    delegate?.onUpdateTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
                }
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    @IBAction func onOkAndAddAnotherTap(sender: UIButton) {
        submit(.OkAndAddAnother)
    }

    // FIXME passing around the text like this, weird
    func showProductSuggestions(text: String, suggestions: [Suggestion]) {
        productAutosuggestionsViewController.options = suggestions.map{$0.name ?? ""} //TODO make this async or add a memory cache
        productAutosuggestionsViewController.searchText(text)
        productAutosuggestionsViewController.view.hidden = text.isEmpty
    }
    
    // FIXME passing around the text like this, weird
    func showSectionSuggestions(text: String, suggestions: [Suggestion]) {
        sectionAutosuggestionsViewController.options = suggestions.map{$0.name ?? ""} //TODO make this async or add a memory cache
        sectionAutosuggestionsViewController.searchText(text)
        sectionAutosuggestionsViewController.view.hidden = text.isEmpty
    }
    
    
    private func onSectionSuggestionSelected(sectionSuggestion: String) {
        sectionInput.text = sectionSuggestion
        sectionAutosuggestionsViewController.view.hidden = true
    }
    
    private func onProductSuggestionSelected(productNameSuggestion: String) {
        nameInput.text = productNameSuggestion
        productAutosuggestionsViewController.view.hidden = true
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func sectionInputFieldChanged(textField: UITextField) {
        delegate?.onSectionInputChanged(textField.text ?? "")
    }
    
    func productNameInputFieldChanged(textField: UITextField) {
        delegate?.onProductNameInputChanged(textField.text ?? "")
    }
    
    // MARK: - Autosuggestion

    
    func sectionAutosuggestionsFrame(autosuggestionsViewParentView: UIView) -> CGRect {
        let sectionFrame = sectionInput.frame
        let originAbsolute = sectionInput.superview!.convertPoint(sectionFrame.origin, toView: autosuggestionsViewParentView)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + sectionFrame.size.height, sectionFrame.size.width, 0)
        return frame
    }
    
    func productAutosuggestionsFrame(autosuggestionsViewParentView: UIView) -> CGRect {
        let productNameFrame = nameInput.frame
        let originAbsolute = nameInput.superview!.convertPoint(productNameFrame.origin, toView: autosuggestionsViewParentView)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + productNameFrame.size.height, productNameFrame.size.width, 0)
        return frame
    }
    
    // Focus next input field when user presses "Next" on keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        endEditing(true)
        switch textField {
        case nameInput:
            sectionInput.becomeFirstResponder()
        case sectionInput:
            priceInput.becomeFirstResponder()
        case priceInput:
            quantityInput.becomeFirstResponder()
        case _: break
        }

        return true
    }
    
    func clearInputs() {
        for field in [nameInput, sectionInput, quantityInput, priceInput] {
            field.text = ""
        }
    }
    
    func dismissKeyboard(sender: AnyObject?) {
        for field in [nameInput, sectionInput, quantityInput, priceInput] {
            field.resignFirstResponder()
        }
    }
}
