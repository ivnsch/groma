//
//  EditCategoryView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs
import Providers


////////////////
// Generic - TODO move to own files

enum InputsResult<T> {
    case ok(T)
    case err(ValidatorDictionary<ValidationError>)
}

enum TopControllerMode {
    case embedded, standalone
}

////////////////


struct EditNameColorViewInputs {
    let name: String
    let color: UIColor
}

struct EditNameColorResult {
    let inputs: EditNameColorViewInputs
    let editingObj: Any
}

struct EditNameColorViewSettings {
    let namePlaceholder: String
    let nameEmptyValidationMessage: String
}

protocol EditNameColorViewDelegate: class {
    var popupsParent: UIViewController? {get}
    func onSubmitNameColor(result: EditNameColorResult)
}


class EditNameColorController: UIViewController, FlatColorPickerControllerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var colorView: UITextField!

    var settings: EditNameColorViewSettings?
    
    fileprivate var showingColorPicker: FlatColorPickerController?
    
    var open: Bool = false
    
    fileprivate var validator: Validator?
    
    fileprivate var keyboardHeight: CGFloat?
    
    var editingObj: Any?
    
    weak var delegate: EditNameColorViewDelegate? {
        didSet {
            initColorControllerAnimator()
        }
    }
    
    fileprivate var colorControllerAnimator: GromFromViewControlerAnimator?

    fileprivate var addButtonHelper: AddButtonHelper? // Only set in standalone mode

    fileprivate var mode: TopControllerMode = .standalone
    
    init() {
        super.init(nibName: "EditNameColorController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: "EditNameColorController", bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorView.textColor = UIColor.gray
        colorView.text = trans("generic_color") // string from storyboard localization doesn't work, seems to be xcode bug
        
        initTextFieldPlaceholders()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    fileprivate func initTextFieldPlaceholders() {
        colorView.attributedPlaceholder = NSAttributedString(string: colorView.placeholder ?? "", attributes: [NSForegroundColorAttributeName: UIColor.gray])
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {if mode == .standalone {QL4("No parentController")}; return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }
    
    fileprivate func initColorControllerAnimator() {
        
        guard let parent = delegate?.popupsParent else {QL4("Parent is not set"); return} // parent until view shows on top of quick view + list but not navigation/tab bar
        colorControllerAnimator = GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
    }
    
    func config(mode: TopControllerMode, prefillData: EditNameColorViewInputs, settings: EditNameColorViewSettings) {
        guard nameTextField != nil else {QL4("Outlets not initialized"); return}
        
        self.mode = mode
        
        nameTextField.text = prefillData.name
        colorView.textColor = prefillData.color
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: settings.namePlaceholder, attributes: [NSForegroundColorAttributeName: UIColor.gray])
        initValidator(emptyNameMessage: settings.nameEmptyValidationMessage)
        
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
    
    func submit() -> InputsResult<EditNameColorResult>? {
        
        guard let validator = validator else {QL4("No validator"); return nil}
        guard let editingObj = editingObj else {QL4("No editing object"); return nil}
        
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
            
            if let name = nameTextField.text, let color = colorView.textColor {
                
                let inputs = EditNameColorViewInputs(name: name, color: color)
                let result = EditNameColorResult(inputs: inputs, editingObj: editingObj)
                
                // We return (for embedded mode) as well as pass to delegate (standalone)
                delegate?.onSubmitNameColor(result: result)
                return .ok(result)
                
            } else {
                QL4("Validation was not implemented correctly")
                return nil
            }
        }
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(_ color: UIColor) {
        closeColorPicker(color)
    }
    
    func onDismiss() {
    }
    
    // MARK: -
    
    func closeColorPicker(_ selectedColor: UIColor?) {
        if colorControllerAnimator?.isShowing ?? false {
            colorControllerAnimator?.close {[weak self] in

                self?.nameTextField.becomeFirstResponder()
                
                UIView.animate(withDuration: 0.3, animations: {[weak self] in
                    if let selectedColor = selectedColor {
                        self?.colorView.textColor = selectedColor
                    }
                })
                UIView.animate(withDuration: 0.15, animations: {[weak self] in
                    self?.colorView.transform = CGAffineTransform(scaleX: 2, y: 2)
                    UIView.animate(withDuration: 0.15, animations: {[weak self] in
                        self?.colorView.transform = CGAffineTransform(scaleX: 1, y: 1)
                    })
                })
            }
        }
    }
    
    @IBAction func onColorTap() {

        colorControllerAnimator?.open (button: colorView, addTopBarHeightToY: false, controllerCreator: {[weak self] in guard let weakSelf = self else {return nil}
            let controller = UIStoryboard.listColorPicker()
            controller.delegate = weakSelf
            return controller
            
        }, onFinish: {[weak self] in
            self?.view.endEditing(true)
        })
    }
}
