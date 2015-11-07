//
//  EditSectionViewController.swift
//  shoppin
//
//  Created by ischuetz on 07/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol EditSectionViewControllerDelegate {
    func onSectionUpdated(section: Section)
}

class EditSectionViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    var open: Bool = false
    
    private var validator: Validator?

    var section: Section?
    
    var delegate: EditSectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: "validation_section_name_not_empty")])
        self.validator = validator
    }
    
    func submit() {
        guard let validator = validator else {return}
        guard let section = section else {
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
            
            if let name = nameTextField.text {
                let updatedSection = section.copy(name: name)
                Providers.sectionProvider.update([updatedSection], successHandler {
                    delegate?.onSectionUpdated(updatedSection)
                })

            } else {
                print("Error: EditSectionViewController.submit: validation was not implemented correctly")
            }
        }
    }
}
