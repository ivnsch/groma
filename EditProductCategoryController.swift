//
//  EditProductCategoryController.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol EditProductCategoryControllerDelegate: class {
    func onCategoryUpdated(brand: AddEditCategoryControllerEditingData)
}

class EditProductCategoryController: UIViewController, FlatColorPickerControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryColorButton: UIButton!
    
    var open: Bool = false
    
    private var validator: Validator?
    
    private var showingColorPicker: FlatColorPickerController?

    var category: AddEditCategoryControllerEditingData? {
        didSet {
            nameTextField.text = category?.category.name
            categoryColorButton.imageView?.tintColor = category?.category.color ?? UIColor.blackColor()
        }
    }
    
    weak var delegate: EditProductCategoryControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        nameTextField.becomeFirstResponder()
    }
    
    private func initValidator() {
        let validator = Validator()
        // TODO!!!! crash here (also had this issue with the top edit section controller why??) maybe the fact we add first the view and then child controller, in expandable controller (no idea!)
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: "validation_product_category_name_not_empty")])
        self.validator = validator
    }
    
    func submit() {
        guard let validator = validator else {return}
        guard let category = category else {
            print("Error: EditProductCategoryController.submit: no section")
            return
        }
        
        if let errors = validator.validate() {
            for (field, _) in errors {
                field.showValidationError()
                presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            if let lastErrors = validator.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let updatedName = nameTextField.text, color = categoryColorButton.imageView?.tintColor {
                
                let updatedCategory = category.category.copy(name: updatedName, color: color)
                let updated = AddEditCategoryControllerEditingData(category: updatedCategory, indexPath: category.indexPath)

                Providers.productCategoryProvider.update(updated.category, remote: true, successHandler {[weak self] in
                    self?.delegate?.onCategoryUpdated(updated)
                })
                
            } else {
                print("Error: EditProductCategoryController.submit: validation was not implemented correctly, or imageView is nil: \(categoryColorButton.imageView)")
            }
        }
    }
    
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parentViewController {
            
            let topBarHeight: CGFloat = 64
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convertPoint(CGPointMake(categoryColorButton.center.x, categoryColorButton.center.y - topBarHeight), fromView: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(0.3) {
                picker.view.transform = CGAffineTransformMakeScale(1, 1)
            }
            
            view.endEditing(true)
            
        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
        
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
//        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    private func dismissColorPicker(selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animateWithDuration(0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self?.categoryColorButton.tintColor = selectedColor
                            self?.categoryColorButton.imageView?.tintColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self?.categoryColorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self?.categoryColorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }

                    self?.nameTextField.becomeFirstResponder()
                }
            )
        }
    }
}