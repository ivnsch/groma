//
//  AddEditPlanItemContentView.swift
//  shoppin
//
//  Created by ischuetz on 08/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol AddEditPlanItemContentViewDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onOkTap(name: String, price: String, quantity: String)
    func onOkAndAddAnotherTap(name: String, price: String, quantity: String)
    func onUpdateTap(name: String, price: String, quantity: String)
    
    func productNameAutocompletions(text: String, handler: [String] -> ())
}

private enum Action {
    case OkAndAddAnother, Ok
}

class AddEditPlanItemContentView: UIView, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, OkNextButtonsViewDelegate {
    
    @IBOutlet weak var nameInput: MLPAutoCompleteTextField!
    @IBOutlet weak var inventoryButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var okNextButtonsView: OkNextButtonsView!
    
    private var validator: Validator?
    
    var delegate: AddEditPlanItemContentViewDelegate?
    
    var inventories: [Inventory] = []
    
    private let pickerLabelFont = UIFont(name: "HelveticaNeue-Light", size: 17) ?? UIFont.systemFontOfSize(17) // TODO font in 1 place

    override func awakeFromNib() {
        super.awakeFromNib()
        
        initValidator()
        
        setInputsDefaultValues()
        
        nameInput.placeholder = "Item name"
        
        addDismissKeyboardTapRecognizer()
        
        initAutocompletionTextFields()
        
        okNextButtonsView.delegate = self
    }
    
    private func initAutocompletionTextFields() {
        for textField in [nameInput] {
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
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case nameInput:
            delegate?.productNameAutocompletions(string) {completions in
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
    
    func setUpdateItem(planItem: PlanItem) {
        okNextButtonsView.addModus = .Update
        prefill(planItem)
    }
    
    func prefill(planItem: PlanItem) {
        nameInput.text = planItem.product.name
        quantityInput.text = String(planItem.quantity)
        priceInput.text = planItem.product.price.toString(2)
        
        okNextButtonsView.addModus = .Update
    }
    
    private func setInputsDefaultValues() {
        quantityInput.text = "1"
    }
    
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
        self.validator = validator
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

            // TODO
            if let text = nameInput.text, priceText = priceInput.text, quantityText = quantityInput.text {
                switch okNextButtonsView.addModus {
                case .Add:
                    switch action {
                    case .Ok:
                        delegate?.onOkTap(text, price: priceText, quantity: quantityText)
                    case .OkAndAddAnother:
                        delegate?.onOkAndAddAnotherTap(text, price: priceText, quantity: quantityText)
                    }
                case .Update:
                    delegate?.onUpdateTap(text, price: priceText, quantity: quantityText)
                }
                
            } else {
                print("Error: validation was not implemented correctly or (TODO validate this?) no selected inventory")
            }
        }
    }
    
    // Focus next input field when user presses "Next" on keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        endEditing(true)
        switch textField {
        case nameInput:
            priceInput.becomeFirstResponder()
        case priceInput:
            quantityInput.becomeFirstResponder()
        case _: break
        }
        
        return true
    }
    
    func clearInputs() {
        for field in [nameInput, quantityInput, priceInput] {
            field.text = ""
        }
    }
    
    func dismissKeyboard(sender: AnyObject?) {
        for field in [nameInput, quantityInput, priceInput] {
            field.resignFirstResponder()
        }
    }
    
    // MARK: - OkNextButtonsViewDelegate

    func onOkAddModusTap() {
        submit(.Ok)
    }
    
    func onOkEditModusTap() {
        submit(.Ok)
    }
    
    func onOkNextAddModusTap() {
        submit(.OkAndAddAnother)
    }
}
