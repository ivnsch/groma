//
//  EditBrandController.swift
//  
//
//  Created by ischuetz on 19/01/16.
//
//

import UIKit
import SwiftValidator
import Providers

protocol EditBrandControllerDelegate: class {
    func onBrandUpdated(_ brand: AddEditBrandControllerEditingData)
}

class EditBrandController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    var brand: AddEditBrandControllerEditingData? {
        didSet {
            nameTextField.text = brand?.brand
        }
    }
    
    weak var delegate: EditBrandControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
    }
    
    fileprivate func initValidator() {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: "validation_brand_name_not_empty")])
        self.validator = validator
    }
    
    func submit() {
        guard let validator = validator else {return}
        guard let brand = brand else {
            print("Error: EditBrandController.submit: no section")
            return
        }
        
        if let errors = validator.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
                present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            for (_, error) in validator.errors {
                error.field.clearValidationError()
            }
            
            if let updatedName = nameTextField.text {
                if updatedName != brand.brand {
                    let updated = AddEditBrandControllerEditingData(brand: updatedName, indexPath: brand.indexPath)
                    Prov.brandProvider.updateBrand(brand.brand, newName: updated.brand, successHandler {[weak self] in
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
