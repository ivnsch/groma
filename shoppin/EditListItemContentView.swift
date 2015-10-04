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
    
    func productNameAutocompletions(text: String, handler: [String] -> ())
    func sectionNameAutocompletions(text: String, handler: [String] -> ())
}

private enum Action {
    case OkAndAddAnother, Ok
}

class EditListItemContentView: UIView, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate {

    @IBOutlet weak var nameInput: MLPAutoCompleteTextField!
    @IBOutlet weak var sectionInput: MLPAutoCompleteTextField!
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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        initValidator()
        
        setInputsDefaultValues()
        
        nameInput.placeholder = "Item name"
        sectionInput.placeholder = "Section (optional)"
        
        addDismissKeyboardTapRecognizer()
        
        initAutocompletionTextFields()
    }
    
    private func initAutocompletionTextFields() {
        for textField in [nameInput, sectionInput] {
            textField.autoCompleteDataSource = self
            textField.autoCompleteTableBorderColor = UIColor.lightGrayColor()
            textField.autoCompleteTableBorderWidth = 0.4
            textField.autoCompleteTableBackgroundColor = UIColor.whiteColor()
            textField.autoCompleteTableCornerRadius = 14
            textField.autoCompleteBoldFontName = "HelveticaNeue-Bold"
            textField.autoCompleteRegularFontName = "HelveticaNeue"
            textField.showTextFieldDropShadowWhenAutoCompleteTableIsOpen = false
            textField.maximumNumberOfAutoCompleteRows = 4
        }
    }
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case nameInput:
            delegate?.productNameAutocompletions(string) {completions in
                handler(completions)
            }
        case sectionInput:
            delegate?.sectionNameAutocompletions(string) {completions in
                handler(completions)
            }
        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
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
