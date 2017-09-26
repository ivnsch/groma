//
//  EditNameButtonController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 09/03/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers



struct EditNameButtonViewInputs {
    let name: String
    let buttonSelected: Bool
}

struct EditNameButtonResult {
    let inputs: EditNameButtonViewInputs
    let editingObj: Any
}

struct EditNameButtonViewSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
    let buttonTitle: String
}

protocol EditNameButtonDelegate: class {
    func onSubmitNameButtonInput(result: EditNameButtonResult, editingObj: Any?)
}


class EditNameButtonController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var button: UIButton!
    
    var settings: EditNameButtonViewSettings?
    
    fileprivate var validator: Validator?
    
    var editingObj: Any?
    
    fileprivate var buttonSelected: Bool = false {
        didSet {
            button.setTitleColor(buttonSelected ? Theme.black : Theme.lightGray, for: .normal)
        }
    }
    
    fileprivate var addButtonHelper: AddButtonHelper? // Only set in standalone mode
    
    fileprivate var mode: TopControllerMode = .standalone
    
    weak var delegate: EditNameButtonDelegate?

    init() {
        super.init(nibName: "EditNameButtonController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: "EditNameButtonController", bundle: nil)
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
        guard let parentView = parent?.view else {if mode == .standalone {logger.e("No parentController")}; return nil}
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {logger.e("No tabBarController"); return nil}

        let overrideCenterY: CGFloat = parentView.height + tabBarHeight
        
        let addButtonHelper = AddButtonHelper(parentView: parentView, overrideCenterY: overrideCenterY) {[weak self] in
            _ = self?.submit()
        }
        
        return addButtonHelper
    }
    
    
    func config(mode: TopControllerMode, prefillData: EditNameButtonViewInputs, settings: EditNameButtonViewSettings, editingObj: Any?) {
        guard nameTextField != nil else {logger.e("Outlets not initialized"); return}
        
        self.mode = mode
        
        nameTextField.text = prefillData.name
        button.setTitle(settings.buttonTitle, for: .normal)
        buttonSelected = prefillData.buttonSelected
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: settings.namePlaceholder, attributes: [NSForegroundColorAttributeName: UIColor.gray])
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
    
    // TODO navigate between text fields - note has to work with .embedded mode (use delegate)
    //    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
    //        if sender == nameTextField {
    //            submit()
    //            sender.resignFirstResponder()
    //        }
    //
    //        return false
    //    }
    
    func submit() -> InputsResult<EditNameButtonResult>? {
        
        guard let validator = validator else {logger.e("No validator"); return nil}
        guard let editingObj = editingObj else {logger.e("No editing object"); return nil}
        
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
                
                let inputs = EditNameButtonViewInputs(name: name, buttonSelected: buttonSelected)
                let result = EditNameButtonResult(inputs: inputs, editingObj: editingObj)
                
                // We return (for embedded mode) as well as pass to delegate (standalone)
                delegate?.onSubmitNameButtonInput(result: result, editingObj: editingObj)
                return .ok(result)
                
            } else {
                logger.e("Validation was not implemented correctly")
                return nil
            }
        }
    }
    
    // MARK: -
    
    @IBAction func onButtonTap(_ sender: UIButton) {
        self.buttonSelected = !buttonSelected
    }
}
