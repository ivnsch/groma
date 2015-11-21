//
//  AddEditInventoryItemController.swift
//  shoppin
//
//  Created by ischuetz on 11/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol AddEditInventoryItemControllerDelegate {
    func onValidationErrors(errors: [UITextField: ValidationError])
    func onSubmit(name: String, category: String, price: Float, quantity: Int, editingInventoryItem: InventoryItem?)
    func onCancelTap()
}

class AddEditInventoryItemController: UIViewController, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate {
    
    @IBOutlet weak var nameInput: MLPAutoCompleteTextField!
    @IBOutlet weak var categoryInput: MLPAutoCompleteTextField!
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    var delegate: AddEditInventoryItemControllerDelegate?
    
    private var validator: Validator?
    
    var open: Bool = false
    
    var editingInventoryItem: InventoryItem? {
        didSet {
            if let editingInventoryItem = editingInventoryItem {
                nameInput.text = editingInventoryItem.product.name
                categoryInput.text = editingInventoryItem.product.category.name
                priceInput.text = editingInventoryItem.product.price.toString(2)
                quantityInput.text = "\(editingInventoryItem.quantity)"
            } else {
                clearInputFields()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initValidator()
        nameInput.defaultAutocompleteStyle()
        categoryInput.defaultAutocompleteStyle()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(categoryInput, rules: [MinLengthRule(length: 1, message: "validation_item_category_not_empty")])

        // TODO float validation rule not correct accepts string like $2 (in all the app). Needs library fix.
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_item_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
        
        self.validator = validator
    }
    
    func submit() {
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
            
            // TODO! new field for category
            if let name = nameInput.text, category = categoryInput.text, price = priceInput.text?.floatValue, quantityText = quantityInput.text, quantity = Int(quantityText) {
                delegate?.onSubmit(name, category: category, price: price, quantity: quantity, editingInventoryItem: editingInventoryItem)
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    private func clearInputFields() {
        nameInput.clear()
        categoryInput.clear()
        priceInput.clear()
        quantityInput.clear()
    }
    
    func clear() {
        editingInventoryItem = nil
        clearInputFields()
    }
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        switch textField {
        case nameInput:
            Providers.productProvider.productsContainingText(string, successHandler{suggestions in
                handler(suggestions.map{$0.name})
            })
        case categoryInput:
            Providers.productProvider.categoriesContaining(string, successHandler{categories in
                handler(categories)
            })
        case _:
            print("Error: Not handled text field in autoCompleteTextField")
            break
        }
    }
}