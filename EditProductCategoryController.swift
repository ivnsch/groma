//
//  EditProductCategoryController.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import Providers

protocol EditProductCategoryControllerDelegate: class {
    func onCategoryUpdated(_ brand: AddEditCategoryControllerEditingData)
}

class EditProductCategoryController: UIViewController, FlatColorPickerControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var categoryColorButton: UIButton!
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    fileprivate var showingColorPicker: FlatColorPickerController?

    var category: AddEditCategoryControllerEditingData? {
        didSet {
            nameTextField.text = category?.category.name
            categoryColorButton.imageView?.tintColor = category?.category.color ?? UIColor.black
        }
    }
    
    weak var delegate: EditProductCategoryControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        nameTextField.becomeFirstResponder()
    }
    
    fileprivate func initValidator() {
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
            for (_, error) in errors {
                (error.field as? ValidatableTextField)?.showValidationError()
                // Outdated implementation TODO remove?
//                present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            for (_, error) in validator.errors {
                (error.field as? ValidatableTextField)?.showValidationError()
            }
            
            if let updatedName = nameTextField.text, let color = categoryColorButton.imageView?.tintColor {
                
                let updatedCategory = category.category.copy(name: updatedName, color: color)
                let updated = AddEditCategoryControllerEditingData(category: updatedCategory, indexPath: category.indexPath)

                Prov.productCategoryProvider.update(updated.category, remote: true, successHandler {[weak self] in
                    self?.delegate?.onCategoryUpdated(updated)
                })
                
            } else {
                print("Error: EditProductCategoryController.submit: validation was not implemented correctly, or imageView is nil: \(String(describing: categoryColorButton.imageView))")
            }
        }
    }
    
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parent {
            
            let topBarHeight: CGFloat = Theme.navBarHeight
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convert(CGPoint(x: categoryColorButton.center.x, y: categoryColorButton.center.y - topBarHeight), from: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 0.3, animations: {
                picker.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) 
            
            view.endEditing(true)
            
        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
        
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(_ color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
//        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    fileprivate func dismissColorPicker(_ selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animate(withDuration: 0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        if let selectedColor = selectedColor {
                            self?.categoryColorButton.tintColor = selectedColor
                            self?.categoryColorButton.imageView?.tintColor = selectedColor
                        }
                    }) 
                    UIView.animate(withDuration: 0.15, animations: {
                        self?.categoryColorButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                        UIView.animate(withDuration: 0.15, animations: {
                            self?.categoryColorButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                        }) 
                    }) 

                    self?.nameTextField.becomeFirstResponder()
                }
            )
        }
    }
}
