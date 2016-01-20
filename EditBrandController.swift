//
//  EditBrandController.swift
//  
//
//  Created by ischuetz on 19/01/16.
//
//

import UIKit
import SwiftValidator

protocol EditBrandControllerDelegate {
    func onBrandUpdated(brand: AddEditBrandControllerEditingData)
}

class EditBrandController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    var open: Bool = false
    
    private var validator: Validator?
    
    var brand: AddEditBrandControllerEditingData? {
        didSet {
            nameTextField.text = brand?.brand
        }
    }
    
    var delegate: EditBrandControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: "validation_brand_name_not_empty")])
        self.validator = validator
    }
    
    func submit() {
        guard let validator = validator else {return}
        guard let brand = brand else {
            print("Error: EditSectionViewController.submit: no section")
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
            
            if let updatedName = nameTextField.text {
                if updatedName != brand.brand {
                    let updated = AddEditBrandControllerEditingData(brand: updatedName, indexPath: brand.indexPath)
                    Providers.brandProvider.updateBrand(brand.brand, newName: updated.brand, successHandler {[weak self] in
                        self?.delegate?.onBrandUpdated(updated)
                    })
                } else {
                    delegate?.onBrandUpdated(brand)
                }
                
            } else {
                print("Error: EditBrandController.submit: validation was not implemented correctly")
            }
        }
    }
}