//
//  EditSingleInputController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 14/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs
import Providers


struct EditSingleInputControllerSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
}

protocol EditSingleInputControllerDelegate: class {
    func onSubmitSingleInput(name: String)
}

class EditSingleInputController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    var settings: EditSingleInputControllerSettings?
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    fileprivate var keyboardHeight: CGFloat?
    
    var editingObj: Any?
    
    weak var delegate: EditSingleInputControllerDelegate?
    
    
    fileprivate var addButtonHelper: AddButtonHelper? // Only set in standalone mode
    
    fileprivate var mode: TopControllerMode = .standalone
    
    init() {
        super.init(nibName: "EditSingleInputController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: "EditSingleInputController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTextFieldPlaceholders()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    fileprivate func initTextFieldPlaceholders() {
        nameTextField.attributedPlaceholder = NSAttributedString(string: nameTextField.placeholder ?? "", attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {if mode == .standalone {QL4("No parentController")}; return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }

    func config(mode: TopControllerMode, prefillName: String, settings: EditSingleInputControllerSettings) {
        guard nameTextField != nil else {QL4("Outlets not initialized"); return}
        
        self.mode = mode

        nameTextField.text = prefillName
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: settings.namePlaceholder, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        initValidator(emptyNameMessage: settings.nameEmptyValidationMessage)
        
        nameTextField.becomeFirstResponder()
        
        if mode == .standalone {
            addButtonHelper = initAddButtonHelper() // parent controller not set yet in earlier lifecycle methods
            addButtonHelper?.addObserver()
            
            focus()
        }
    }
    
    func focus() {
        nameTextField.becomeFirstResponder()
    }
    
    fileprivate func initValidator(emptyNameMessage: String) {
        let validator = Validator()
        validator.registerField(nameTextField, rules: [MinLengthRule(length: 1, message: emptyNameMessage)])
        self.validator = validator
    }
    
    func submit() -> InputsResult<String>? {
        
        guard let validator = validator else {QL4("No validator"); return nil}
        
        if let errors = validator.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            if mode == .standalone {
                present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            return .err(errors)
            
        } else {
            for (_, error) in validator.errors {
                error.field.clearValidationError()
            }
            
            if let name = nameTextField.text {
                
                // We return (for embedded mode) as well as pass to delegate (standalone)
                delegate?.onSubmitSingleInput(name: name)
                return .ok(name)
                
            } else {
                QL4("Validation was not implemented correctly")
                return nil
            }
        }
    }
}
