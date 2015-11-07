//
//  AddEditListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator


protocol AddEditListItemViewControllerDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onOkTap(name: String, price: String, quantity: String, category: String, sectionName: String, note: String?)
    func onOkAndAddAnotherTap(name: String, price: String, quantity: String, category: String, sectionName: String, note: String?)
    func onUpdateTap(name: String, price: String, quantity: String, category: String, sectionName: String, note: String?)
    func onCancelTap()
    
    func productNameAutocompletions(text: String, handler: [String] -> ())
    func sectionNameAutocompletions(text: String, handler: [String] -> ())
    
    func planItem(productName: String, handler: PlanItem? -> ())
}

enum AddEditListItemViewControllerAction {
    case AddAndAddAnother, Add, Update
}

class AddEditListItemViewController: UIViewController, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate {

    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var sectionInput: MLPAutoCompleteTextField!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var noteInput: UITextField!
    
    @IBOutlet weak var planInfoButton: UIButton!
    
    var delegate: AddEditListItemViewControllerDelegate?
    
    var planItem: PlanItem? {
        didSet {
            onQuantityChanged()
        }
    }
    
    var updatingListItem: ListItem? {    
        didSet {
            if let updatingListItem = updatingListItem {
                prefill(updatingListItem)
            }
        }
    }
    
    var modus: AddEditListItemControllerModus = .ListItem {
        didSet {
            if let noteInput = noteInput {
                noteInput.hidden = modus == .GroupItem
            } else {
                print("Error: Trying to set modus before outlet is initialised")
            }
        }
    }
    
    var open: Bool = false
    
    private var validator: Validator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        setInputsDefaultValues()
    }
    
    private func prefill(listItem: ListItem) {
        nameInput.text = listItem.product.name
        sectionInput.text = listItem.section.name
        quantityInput.text = String(listItem.quantity)
        priceInput.text = listItem.product.price.toString(2)
        noteInput.text = listItem.note
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
    
    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
    func submit(action: AddEditListItemViewControllerAction) {
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
            
            // TODO new input field for section,
            if let text = nameInput.text, priceText = priceInput.text, quantityText = quantityInput.text, category = sectionInput.text {
                switch action {
                case .Add:
                    delegate?.onOkTap(text, price: priceText, quantity: quantityText, category: category, sectionName: category, note: noteInput.text)
                case .AddAndAddAnother:
                    delegate?.onOkAndAddAnotherTap(text, price: priceText, quantity: quantityText, category: category, sectionName: category, note: noteInput.text)
                case .Update:
                    delegate?.onUpdateTap(text, price: priceText, quantity: quantityText, category: category, sectionName: category, note: noteInput.text)
                }
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    // Focus next input field when user presses "Next" on keypad
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
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
    
    @IBAction func productNameEditingDidEnd(sender: AnyObject) {
        if let text = nameInput.text {
            onNameInputChange(text)
        } else {
            print("Error: unexpected, text field with no text")
        }
    }
    
    private func onNameInputChange(text: String) {
        delegate?.planItem(text) {[weak self] planItemMaybe in
            self?.planItem = planItemMaybe
        }
    }
    
    @IBAction func quantityEditingDidChange(sender: AnyObject) {
        onQuantityChanged()
    }
    
    func onQuantityChanged() {
        if let text = quantityInput.text, quantity = Int(text) {
            updatePlanLeftQuantity(quantity)
        } else {
            print("Error: Invalid quantity input")
        }
    }
    
    private func updatePlanLeftQuantity(inputQuantity: Int) {
        if let planItem = planItem {
            let planItemLeftQuantity = planItem.quantity - planItem.usedQuantity
            let updatedLeftQuantity = planItemLeftQuantity - inputQuantity
            planInfoButton.setTitle("\(updatedLeftQuantity) left", forState: .Normal)
            
        } else { // item is not planned -  don't show anything (no limits)
            planInfoButton.setTitle("", forState: .Normal)
        }
    }
    
    func showPlanItem(planItem: PlanItem) {
        planInfoButton.setTitle("\(planItem.quantity - planItem.usedQuantity) left", forState: .Normal)
    }
    
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case nameInput:
            delegate?.productNameAutocompletions(string) {completions in
                // don't use autocompletions for product - now that there's quick add, the only reason the user is here is because we don't have the product, so autocompletion doesn't make sense
//                handler(completions)
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
    
    // MARK: - MLPAutoCompleteTextFieldDelegate
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, didSelectAutoCompleteString selectedString: String!, withAutoCompleteObject selectedObject: MLPAutoCompletionObject!, forRowAtIndexPath indexPath: NSIndexPath!) {
        onNameInputChange(selectedString)
    }
}