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
    func onSubmit(name: String, category: String, categoryColor: UIColor, price: Float, baseQuantity: Float, unit: ProductUnit, editingData: AddEditProductControllerEditingData?)
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

class AddEditProductController: UIViewController, MLPAutoCompleteTextFieldDataSource, MLPAutoCompleteTextFieldDelegate, FlatColorPickerControllerDelegate {

    @IBOutlet weak var nameInput: UITextField!
    @IBOutlet weak var categoryInput: MLPAutoCompleteTextField!
    @IBOutlet weak var sectionColorButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    
    var delegate: AddEditProductControllerDelegate?
    
    private var validator: Validator?

    var open: Bool = false
    
    var editingData: AddEditProductControllerEditingData? {
        didSet {
            if let editingData = editingData {
                nameInput.text = editingData.product.name
                categoryInput.text = editingData.product.category.name
                priceInput.text = editingData.product.price.toString(2)
                sectionColorButton.tintColor = editingData.product.category.color
                sectionColorButton.imageView?.tintColor = editingData.product.category.color
            } else {
                clearInputFields()
            }
        }
    }
    
    private var showingColorPicker: FlatColorPickerController?
    
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
            
            // TODO!! base quantity
            // TODO!! unit
            let baseQuantityFoo: String? = "1"
            let unitFoo: String? = "0"

            if let name = nameInput.text, category = categoryInput.text, price = priceInput.text?.floatValue, baseQuantity = baseQuantityFoo?.floatValue, unitText = unitFoo, unitInt = Int(unitText), unit = ProductUnit(rawValue: unitInt)  {
                delegate?.onSubmit(name, category: category, categoryColor: sectionColorButton.tintColor, price: price, baseQuantity: baseQuantity, unit: unit, editingData: editingData)
                
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
    
    @IBAction func onSectionColorButtonTap(sender: UIButton) {
        
        if let windowView = UIApplication.sharedApplication().keyWindow { // add popup and overlay on top of everything
            
            let picker = UIStoryboard.listColorPicker()
            
            // TODO dynamic
            let topBarHeight: CGFloat = 64
            let tabBarHeight: CGFloat = 49
            
            picker.view.frame = CGRectMake(0, topBarHeight, windowView.frame.width, windowView.frame.height - topBarHeight - tabBarHeight)
            
            windowView.addSubview(picker.view)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = windowView.convertPoint(CGPointMake(sectionColorButton.center.x, sectionColorButton.center.y - topBarHeight), fromView: view)
            let fractionX = buttonPointInParent.x / windowView.frame.width
            let fractionY = buttonPointInParent.y / (windowView.frame.height - topBarHeight - tabBarHeight)
            
            picker.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            picker.view.frame = CGRectMake(0, topBarHeight, windowView.frame.width, windowView.frame.height - topBarHeight - tabBarHeight)
            
            picker.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(0.3) {
                picker.view.transform = CGAffineTransformMakeScale(1, 1)
            }
            
        } else {
            print("Warn: AddEditListItemViewController.onSectionColorButtonTap: unexpected: no window")
        }
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    private func dismissColorPicker(selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animateWithDuration(0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                
                }, completion: {finished in
                    self.showingColorPicker = nil
                    self.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self.sectionColorButton.tintColor = selectedColor
                            self.sectionColorButton.imageView?.tintColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self.sectionColorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self.sectionColorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                }
            )
        }
    }
}