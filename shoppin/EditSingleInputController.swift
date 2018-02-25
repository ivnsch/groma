//
//  EditSingleInputController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 14/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers


struct EditSingleInputControllerSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
}

protocol EditSingleInputControllerDelegate: class {
    func onSubmitSingleInput(name: String, editingObj: Any?)
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
        nameTextField.attributedPlaceholder = NSAttributedString(string: nameTextField.placeholder ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {if mode == .standalone {logger.e("No parentController")}; return nil}
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {logger.e("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = parentView.height + tabBarHeight
        
        let addButtonHelper = AddButtonHelper(parentView: parentView, overrideCenterY: overrideCenterY) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }

    func config(mode: TopControllerMode, prefillName: String, settings: EditSingleInputControllerSettings, editingObj: Any?, keyboardType: UIKeyboardType) {
        guard nameTextField != nil else {logger.e("Outlets not initialized"); return}
        
        self.mode = mode

        nameTextField.keyboardType = keyboardType
        
        nameTextField.text = prefillName
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: settings.namePlaceholder, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        initValidator(emptyNameMessage: settings.nameEmptyValidationMessage)
        
        self.editingObj = editingObj
        
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
        
        guard let validator = validator else {logger.e("No validator"); return nil}

        if let errors = validator.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            if mode == .standalone {
                let currentFirstResponder = nameTextField.isFirstResponder ? nameTextField : nil
                view.endEditing(true)
                ValidationAlertCreator.present(errors, parent: root, firstResponder: currentFirstResponder)
            }
            return .err(errors)
            
        } else {
            for (_, error) in validator.errors {
                error.field.clearValidationError()
            }
            
            if let name = nameTextField.text {
                
                // We return (for embedded mode) as well as pass to delegate (standalone)
                delegate?.onSubmitSingleInput(name: name, editingObj: editingObj)
                return .ok(name)
                
            } else {
                logger.e("Validation was not implemented correctly")
                return nil
            }
        }
    }
}
