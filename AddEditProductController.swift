//
//  AddEditProductController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol AddEditProductControllerDelegate {
    func onValidationErrors(errors: [UITextField: ValidationError])
    func onSubmit(name: String, category: String, price: Float, editingData: AddEditProductControllerEditingData?)
    func onCancelTap()
}

struct AddEditProductControllerEditingData {
    let product: Product
    let indexPath: NSIndexPath
    init(product: Product, indexPath: NSIndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}

class AddEditProductController: UIViewController, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate {

    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var categoryInput: MLPAutoCompleteTextField!
    @IBOutlet weak var priceInput: UITextField!
    
    var delegate: AddEditProductControllerDelegate?
    
    private var validator: Validator?

    var open: Bool = false
    
    var editingData: AddEditProductControllerEditingData? {
        didSet {
            if let editingData = editingData {
                nameInput.text = editingData.product.name
                categoryInput.text = editingData.product.category
                priceInput.text = editingData.product.price.toString(2)
            } else {
                clearInputFields()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initValidator()
        categoryInput.defaultAutocompleteStyle()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(categoryInput, rules: [MinLengthRule(length: 1, message: "validation_item_category_not_empty")])
        
        // TODO float validation rule not correct accepts string like $2 (in all the app). Needs library fix.
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        
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
            if let name = nameInput.text, category = categoryInput.text, price = priceInput.text?.floatValue {
                delegate?.onSubmit(name, category: category, price: price, editingData: editingData)
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    private func clearInputFields() {
        nameInput.text = ""
        categoryInput.text = ""
        priceInput.text = ""
    }
    
    func clear() {
        editingData = nil
        clearInputFields()
    }
    
    // MARK: - MLPAutoCompleteTextFieldDataSource
    
    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
        Providers.productProvider.categoriesContaining(string, successHandler{categories in
            handler(categories)
        })
    }
}