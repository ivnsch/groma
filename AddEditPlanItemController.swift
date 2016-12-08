////
////  AddEditPlanItemController.swift
////  shoppin
////
////  Created by ischuetz on 07/11/15.
////  Copyright © 2015 ivanschuetz. All rights reserved.
////
//
//import UIKit
//import SwiftValidator
//
//protocol AddEditPlanItemContentViewDelegate: class {
//    func onValidationErrors(errors: [UITextField: ValidationError])
//
//    func onPlanItemAdded(planItem: PlanItem)
//    func onPlanItemUpdated(planItem: PlanItem)
//}
//
//enum AddEditPlanItemControllerAction {
//    case OkAndAddAnother, Ok
//}
//
//class AddEditPlanItemController: UIViewController, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate {
//    
//    @IBOutlet weak var nameInput: MLPAutoCompleteTextField!
//    @IBOutlet weak var categoryInput: MLPAutoCompleteTextField!
//    @IBOutlet weak var priceInput: UITextField!
//    @IBOutlet weak var quantityInput: UITextField!
//    @IBOutlet weak var submitButton: UIButton!
//
//    private var validator: Validator?
//    
//    weak var delegate: AddEditPlanItemContentViewDelegate?
//    
//    var inventories: [Inventory] = []
//    
//    var currentInventory: DBInventory?
//
//    var open: Bool = false
//    
//    var editingPlanItem: PlanItem?
//    
//    private func initAutocompletionTextFields() {
//        for textField in [nameInput, categoryInput] {
//            textField.defaultAutocompleteStyle()
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        initValidator()
//        setInputsDefaultValues()
//        initAutocompletionTextFields()
//
//    }
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        if let editingPlanItem = editingPlanItem {
//            prefill(editingPlanItem)
//        }
//    }
//    
//    // MARK: - MLPAutoCompleteTextFieldDataSource
//    
//    func autoCompleteTextField(textField: MLPAutoCompleteTextField!, possibleCompletionsForString string: String!, completionHandler handler: (([AnyObject]!) -> Void)!) {
//        switch textField {
//        case nameInput:
//            Providers.productProvider.productSuggestions(successHandler{suggestions in
//                // TODO move this filtering to the provider
//                let names = suggestions.filterMap({$0.name.contains(string, caseInsensitive: true)}){$0.name}
//                handler(names)
//            })
//        case categoryInput:
//            Providers.productProvider.categoriesContaining(string, successHandler {categories in
//                handler(categories)
//            })
//        case _:
//            print("Error: Not handled text field in autoCompleteTextField")
//            break
//        }
//    }
//    
//    private func prefill(planItem: PlanItem) {
//        nameInput.text = planItem.product.name
//        categoryInput.text = String(planItem.product.category)
//        quantityInput.text = String(planItem.quantity)
//        priceInput.text = planItem.product.price.toString(2)
//    }
//    
//    private func setInputsDefaultValues() {
//        quantityInput.text = "1"
//    }
//    
//    
//    private func initValidator() {
//        let validator = Validator()
//        validator.registerField(nameInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
//        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
//        validator.registerField(quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
//        self.validator = validator
//    }
//    
//    // Parameter action is only relevant for add case - in edit it's expected to be always "Ok" (since edit has only ok button) and ignored.
//    func submit(action: AddEditPlanItemControllerAction) {
//        guard validator != nil else {return}
//        
//        if let errors = validator?.validate() {
//            for (field, _) in errors {
//                field.showValidationError()
//                delegate?.onValidationErrors(errors)
//            }
//            
//        } else {
//            if let lastErrors = validator?.lastErrors {
//                for (field, _) in lastErrors {
//                    field.clearValidationError()
//                }
//            }
//            
//            // TODO!! base quantity
//            // TODO!! unit
//            let baseQuantityFoo: String? = ""
//            let unitFoo: String? = ""
//            
//            if let name = nameInput.text, category = categoryInput.text, priceText = priceInput.text, quantityText = quantityInput.text, baseQuantity = baseQuantityFoo?.floatValue, unitText = unitFoo, unitInt = Int(unitText), unit = ProductUnit(rawValue: unitInt) {
//                
//                if let editingPlanItem = editingPlanItem {
//                    updatePlanItem(editingPlanItem, name: name, price: priceText, quantity: quantityText, category: category, baseQuantity: baseQuantity, unit: unit)
//
//                } else {
//                    addPlanItem(name, price: priceText, quantity: quantityText, category: category, baseQuantity: baseQuantity, unit: unit)
//                }
//                
//            } else {
//                print("Error: validation was not implemented correctly or (TODO validate this?) no selected unit") // TODO use quick add here and use the units
//            }
//        }
//    }
//
//    private func updatePlanItem(planItem: PlanItem, name: String, price priceText: String, quantity quantityText: String, category: String, baseQuantity: Float, unit: ProductUnit) {
//        if let price = priceText.floatValue, quantity = Int(quantityText), inventory = currentInventory {
//            
//            let updatedProduct = planItem.product.copy(name: name, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
//            let quantityDelta = quantity - planItem.quantity // TODO! this is not most likely not correct, needs to include also planItem.quantityDelta?
//            let updatedPlanItem = planItem.copy(product: updatedProduct, quantity: quantity, quantityDelta: quantityDelta)
//            
//            Providers.planProvider.updatePlanItem(updatedPlanItem, inventory: inventory, successHandler{[weak self] planItem in
//                self?.delegate?.onPlanItemUpdated(planItem)
//            })
//        } else {
//            print("Error: AddEditPlanItemController.updatePlanItem: validation not implemented correctly or currentInventory not set")
//        }
//    }
//
//    private func addPlanItem(name: String, price priceText: String, quantity quantityText: String, category: String, baseQuantity: Float, unit: ProductUnit) {
//        if let planItemInput = toPlanItemInput(name, priceText: priceText, quantityText: quantityText, category: category, baseQuantity: baseQuantity, unit: unit), inventory = currentInventory {
//            Providers.planProvider.addPlanItem(planItemInput, inventory: inventory, successHandler{[weak self] planItem in
//                self?.delegate?.onPlanItemAdded(planItem)
//            })
//        }
//    }
//    
//    private func toPlanItemInput(name: String, priceText: String, quantityText: String, category: String, baseQuantity: Float, unit: ProductUnit) -> PlanItemInput? {
//        if let price = priceText.floatValue, quantity = Int(quantityText) {
//            return PlanItemInput(name: name, quantity: quantity, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
//        } else {
//            print("TODO validation in toPlanItemInput")
//            return nil
//        }
//    }
//    
//    
//    // Focus next input field when user presses "Next" on keypad
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        view.endEditing(true)
//        switch textField {
//        case nameInput:
//            priceInput.becomeFirstResponder()
//        case priceInput:
//            quantityInput.becomeFirstResponder()
//        case _: break
//        }
//        
//        return true
//    }
//    
//    func clearInputs() {
//        for field in [nameInput, categoryInput, quantityInput, priceInput] {
//            field.text = ""
//        }
//    }
//
//    func clearEditingItem() {
//        editingPlanItem = nil
//    }
//    
//    func dismissKeyboard(sender: AnyObject?) {
//        for field in [nameInput, quantityInput, priceInput] {
//            field.resignFirstResponder()
//        }
//    }
//
//    @IBAction func onSubmitTap(button: UIButton) {
//        submit(.Ok)
//    }
//    
//    @IBAction func onQuantityPlusTap(button: UIButton) {
//        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
//            quantityInput.text = "\(quantity + 1)"
//        } else {
//            quantityInput.text = "1"
//        }
//    }
//    
//    @IBAction func onQuantityMinusTap(button: UIButton) {
//        if let quantityText = quantityInput.text, quantity = Int(quantityText) {
//            quantityInput.text = "\(quantity - 1)"
//        }
//    }
//}
