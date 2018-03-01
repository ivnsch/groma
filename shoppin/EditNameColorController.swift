//
//  EditCategoryView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers


////////////////
// Generic - TODO move to own files

enum InputsResult<T> {
    case ok(T)
    case err(ValidatorDictionary<ValidationError>)
}

enum TopControllerMode {
    case embedded(isLast: Bool) // isLast: Whether it's the last (at the bottom/end of parent) - used for text fields return type
    case standalone

    static func ==(a: TopControllerMode, b: TopControllerMode) -> Bool {
        switch (a, b) {
        case (.embedded(let isLast1), .embedded(let isLast2)):
            return isLast1 == isLast2
        case (.standalone, .standalone): return true
        default: return false
        }
    }
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


class EditNameColorController: UIViewController, FlatColorPickerControllerDelegate, UITextFieldDelegate {

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

        nameTextField.delegate = self
        
        initTextFieldPlaceholders()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    fileprivate func initTextFieldPlaceholders() {
        colorView.attributedPlaceholder = NSAttributedString(string: colorView.placeholder ?? "", attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {if mode == .standalone {logger.e("No parentController")}; return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            _ = self?.submit()
        }
        return addButtonHelper
    }
    
    fileprivate func initColorControllerAnimator() {
        
        guard let parent = delegate?.popupsParent else {logger.e("Parent is not set"); return} // parent until view shows on top of quick view + list but not navigation/tab bar
        colorControllerAnimator = GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
    }
    
    func config(mode: TopControllerMode, prefillData: EditNameColorViewInputs, settings: EditNameColorViewSettings) {
        guard nameTextField != nil else {logger.e("Outlets not initialized"); return}
        
        self.mode = mode
        
        nameTextField.text = prefillData.name
        colorView.textColor = prefillData.color
        
        nameTextField.attributedPlaceholder = NSAttributedString(string: settings.namePlaceholder, attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        initValidator(emptyNameMessage: settings.nameEmptyValidationMessage)

        switch mode {
        case .standalone:
            addButtonHelper = initAddButtonHelper() // parent controller not set yet in earlier lifecycle methods
            addButtonHelper?.addObserver()
            nameTextField.returnKeyType = .done
            focus()

        case .embedded(let isLast):
            nameTextField.returnKeyType = isLast ? .default : .next
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

    func submit() -> InputsResult<EditNameColorResult>? {
        
        guard let validator = validator else {logger.e("No validator"); return nil}
        guard let editingObj = editingObj else {logger.e("No editing object"); return nil}

        if let errors = validator.validate() {
            for (_, error) in errors {
                (error.field as? ValidatableTextField)?.showValidationError()
            }
            if mode == .standalone {
                let currentFirstResponder = nameTextField.isFirstResponder ? nameTextField : nil
                view.endEditing(true)
                ValidationAlertCreator.present(errors, parent: root, firstResponder: currentFirstResponder)
            }
            return .err(errors)
            
        } else {
            for (_, error) in validator.errors {
                (error.field as? ValidatableTextField)?.showValidationError()
            }
            
            if let name = nameTextField.text, let color = colorView.textColor {
                
                let inputs = EditNameColorViewInputs(name: name, color: color)
                let result = EditNameColorResult(inputs: inputs, editingObj: editingObj)
                
                // We return (for embedded mode) as well as pass to delegate (standalone)
                delegate?.onSubmitNameColor(result: result)
                return .ok(result)
                
            } else {
                logger.e("Validation was not implemented correctly")
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

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ sender: UITextField) -> Bool {

        if sender == nameTextField {
            switch mode {
            case .embedded(let isLast):
                if isLast {
                    // Do nothing - parent controller submits everything with save button
                } else {
                    // delegate?.onEditNameColorNavigateToNextTextField() // Not needed right now...
                }
                break
            case .standalone:
                _ = submit()
                sender.resignFirstResponder()
            }
        }
        return false
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
