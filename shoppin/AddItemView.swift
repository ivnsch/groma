//
//  AddItemView.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol AddItemViewDelegate {
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    
    func onAddTap(name:String, price:String, quantity:String, sectionName:String)
    func onUpdateTap(name:String, price:String, quantity:String, sectionName:String)
    func onSectionInputChanged(text: String)
    func onProductNameInputChanged(text: String)
}

enum AddModus {
    case Add, Update
}

// TODO wrap this in controller, which also handles validating, creating listitem, maybe also storing in provider
class AddItemView: UIView, UITextFieldDelegate {
    
    @IBOutlet weak var productDetailsContainer: UIView!
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var addSectionContainer: UIView!
    
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var sectionInput: UITextField!
    
    @IBOutlet weak var heightConstraint:NSLayoutConstraint!
    @IBOutlet weak var topConstraint:NSLayoutConstraint!

    @IBOutlet weak var addButton: UIButton!

    var expanded:Bool = true

    
    private var validator: Validator?
    
    private var addModus:AddModus = .Add {
        didSet {
            switch addModus {
            case .Add:
                self.addButton.setTitle("Add", forState: UIControlState.Normal)
            case .Update:
                self.addButton.setTitle("Update", forState: UIControlState.Normal)
            }
        }
    }
    
    private var inputs:[UITextField] {
        return [self.inputField, self.priceInput, self.quantityInput, self.sectionInput]
    }

    private var originalHeight:CGFloat!

    
    var sectionText: String {
        set {
            self.sectionInput.text = newValue
        }
        get {
            return self.sectionInput.text ?? ""
        }
    }

    var productNameText: String {
        set {
            self.inputField.text = newValue
        }
        get {
            return self.inputField.text ?? ""
        }
    }
    
    var delegate: AddItemViewDelegate!
    
    private func formattedPrice(price:Float) -> String {
        return NSNumber(float: price).stringValue + " €"
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(self.inputField, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty")])
        validator.registerField(self.sectionInput, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        validator.registerField(self.priceInput, rules: [MinLengthRule(length: 1, message: "validation_price_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(self.quantityInput, rules: [MinLengthRule(length: 1, message: "validation_quantity_not_empty"), FloatRule(message: "validation_quantity_number")])
        self.validator = validator
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.initValidator()
        
        self.setInputsDefaultValues()
        
        self.priceInput.keyboardType = UIKeyboardType.DecimalPad
        self.quantityInput.keyboardType = UIKeyboardType.DecimalPad
        
        self.inputField.placeholder = "Item name"
        self.sectionInput.placeholder = "Section (optional)"
        inputField.autocapitalizationType = .Sentences
        
        FrozenEffect.apply(self)
        
        sectionInput.delegate = self
        sectionInput.addTarget(self, action: "sectionInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        sectionInput.autocapitalizationType = .Sentences

        inputField.delegate = self
        inputField.addTarget(self, action: "productNameInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        inputField.autocapitalizationType = .Sentences
        
        self.originalHeight = self.heightConstraint.constant
    }

    
    func sectionInputFieldChanged(textField: UITextField) {
        self.delegate.onSectionInputChanged(textField.text ?? "")
    }

    
    func productNameInputFieldChanged(textField: UITextField) {
        self.delegate.onProductNameInputChanged(textField.text ?? "")
    }
    
    @IBAction func onAddTap(sender: AnyObject) {
        
        guard validator != nil else {return}
   
        if let errors = self.validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
                self.delegate.onValidationErrors(errors)
            }
            
        } else {
            if let lastErrors = self.validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let text = self.inputField.text, priceText = self.priceInput.text, quantityText = self.quantityInput.text, sectionText = self.sectionInput.text {
                switch self.addModus {
                case .Add:
                    delegate.onAddTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
                case .Update:
                    delegate.onUpdateTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
                }
    
                self.addModus = .Add // after adding item, either if we come from add or update, we go back to add modus
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }

    func clearInputs() {
        for input in self.inputs {
            if input != self.sectionInput { // section name stays
                input.text = ""
            }
        }
        self.setInputsDefaultValues()
    }
    
    private func setInputsDefaultValues() {
        self.quantityInput.text = "1"
    }
    
    func sectionAutosuggestionsFrame(autosuggestionsViewParentView: UIView) -> CGRect {
        let sectionFrame = self.sectionInput.frame
        let originAbsolute = self.sectionInput.superview!.convertPoint(sectionFrame.origin, toView: autosuggestionsViewParentView)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + sectionFrame.size.height, sectionFrame.size.width, 0)
        return frame
    }

    func productAutosuggestionsFrame(autosuggestionsViewParentView: UIView) -> CGRect {
        let productNameFrame = self.inputField.frame
        let originAbsolute = self.inputField.superview!.convertPoint(productNameFrame.origin, toView: autosuggestionsViewParentView)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + productNameFrame.size.height, productNameFrame.size.width, 0)
        return frame
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.inputs.forEach { (element) -> Void in
            if element.isFirstResponder() && touches.first?.view != element {
                element.resignFirstResponder()
            }
        }
        super.touchesBegan(touches, withEvent: event)
    }

    override func resignFirstResponder() -> Bool {
        self.inputs.forEach{$0.resignFirstResponder()}
        return true
    }
    
    func setUpdateItem(listItem:ListItem) {
        self.addModus = .Update
        
        self.prefill(listItem)
    }
    
    private func prefill(listItem:ListItem) {
        self.inputField.text = listItem.product.name
        self.sectionInput.text = listItem.section.name
        self.quantityInput.text = String(listItem.quantity)
        self.priceInput.text = listItem.product.price.toString(2)
    }
}
