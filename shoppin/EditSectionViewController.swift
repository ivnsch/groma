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

    var section: Section? {
        didSet {
            nameTextField.text = section?.name
        }
    }
    
    var delegate: EditSectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        // TODO!!!! crash here "fatal error: unexpectedly found nil while unwrapping an Optional value", once while testing on device was just expand/collapse list (in edit mode) multiple times
        // stack strace:  ViewController.onSectionSelectedShared -- topEditSectionControllerManager?.expand(true) -> ExpandableTopViewController.expand -- let view = controller.view -> (system) -> EditSectionViewController.viewDidLoad
        // This means that I mistakenly tapped on a section header one while tapping on the expand/collapse button. But normally tapping on section header isn't crashing in expanded as well as collapsed mode, so no idea what it is. After viewDidLoad outlet should be set!! Maybe expand/collapse invalidating somehow an opening edit section controller when tap quickly? No idea!
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
                Providers.sectionProvider.update([updatedSection], remote: true, successHandler {
                    delegate?.onSectionUpdated(updatedSection)
                })

            } else {
                print("Error: EditSectionViewController.submit: validation was not implemented correctly")
            }
        }
    }
}
