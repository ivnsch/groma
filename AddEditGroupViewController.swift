//
//  AddEditGroupViewController.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import ChameleonFramework

import Providers

//change
protocol AddEditGroupControllerDelegate: class {
    func onAddGroup(_ input: AddEditSimpleItemInput)
    func onUpdateGroup(_ input: AddEditSimpleItemInput, item: SimpleFirstLevelListItem, index: Int)
    
//    func instance(name: String, color: UIColor, order: Int) -> SimpleFirstLevelListItem
}

// TODO after final design either remove color code or reenable it


protocol SimpleFirstLevelListItem: class {
    var name: String {get}
    var color: UIColor {get}
    
//    func update(name: String, color: UIColor) -> Self
}

struct AddEditSimpleItemInput {
    let name: String
    let color: UIColor
//    let order: Int // TODO remove order
}


class AddEditGroupViewController: UIViewController, FlatColorPickerControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var groupNameInputField: UITextField!
    
    @IBOutlet weak var colorButton: UIButton!
    
    fileprivate var listInputsValidator: Validator?
    
    weak var delegate: AddEditGroupControllerDelegate?
    
    var open: Bool = false
    
//    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var modelToEdit: (item: SimpleFirstLevelListItem, index: Int)? {
        didSet {
            if let modelToEdit = modelToEdit {
                prefill(modelToEdit.item)
            }
        }
    }

    fileprivate var showingColorPicker: FlatColorPickerController?
    
    fileprivate var addButtonHelper: AddButtonHelper?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        addButtonHelper = initAddButtonHelper()
        addButtonHelper?.addObserver()
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {logger.e("No parentController"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            self?.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    
    fileprivate func prefill(_ list: SimpleFirstLevelListItem) {
        groupNameInputField.text = list.name
        setBackgroundColor(list.color)
    }
    
    fileprivate func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.groupNameInputField, rules: [NotEmptyTrimmedRule(message: trans("validation_recipe_name_not_empty"))])
        
        self.listInputsValidator = listInputsValidator
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        groupNameInputField.setPlaceholderWithColor(trans("placeholder_recipe_name"), color: UIColor.white)
        
        setBackgroundColor(UIColor.randomColor())
        
        groupNameInputField.becomeFirstResponder()
    }
    
    fileprivate func setBackgroundColor(_ color: UIColor) {
        
        func setContrastingTextColor(_ color: UIColor) {
            guard groupNameInputField != nil else {logger.e("Outlets not initialised yet"); return}
            
            let contrastingTextColor = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
            
            groupNameInputField.setPlaceholderWithColor(trans("placeholder_recipe_name"), color: contrastingTextColor)
            groupNameInputField.textColor = contrastingTextColor
            colorButton.setTitleColor(contrastingTextColor, for: .normal)
        }
        
        view.backgroundColor = color
        setContrastingTextColor(color)
    }
    
    @IBAction func onDoneTap(_ sender: UIBarButtonItem) {
        submit()
    }
    
    func submit() {
        
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) {[weak self] in
            
            guard let weakSelf = self else {return}
            guard let bgColor = weakSelf.view.backgroundColor else {logger.e("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.groupNameInputField.text?.trim() else {logger.e("Validation was not implemented correctly"); return}
            guard let delegate = weakSelf.delegate else {logger.e("No delegate"); return}
            
            let input = AddEditSimpleItemInput(name: listName, color: bgColor)

            if let modelToEdit = weakSelf.modelToEdit {
                delegate.onUpdateGroup(input, item: modelToEdit.item, index: modelToEdit.index)
            } else {
//                    let group = ProductGroup(uuid: NSUUID().uuidString, name: listName, color: bgColor, order: currentListsCount)
                delegate.onAddGroup(input)
            }
        }
    }
    
    fileprivate func validateInputs(_ validator: Validator?, onValid: () -> ()) {
        
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }
            present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    error.field.clearValidationError()
                }
            }
            
            onValid()
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == groupNameInputField {
            submit()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func onCloseTap(_ sender: UIBarButtonItem) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parent {
            
            let topBarHeight: CGFloat = 64
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convert(CGPoint(x: colorButton.center.x, y: colorButton.center.y - topBarHeight), from: view)
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
    
    func clear() {
        groupNameInputField.clear()
        modelToEdit = nil
        
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
                            self?.setBackgroundColor(selectedColor)
                        }
                    }) 
                    UIView.animate(withDuration: 0.15, animations: {
                        self?.colorButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                        UIView.animate(withDuration: 0.15, animations: {
                            self?.colorButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                        }) 
                    }) 
                    
                    self?.groupNameInputField.becomeFirstResponder()
                }
            )
        }
    }
    
    // MARK: -
    
    // Returns if quick controller can be closed
    func requestClose() -> Bool {
        let showingColorPicker = self.showingColorPicker
        dismissColorPicker(nil)
        return showingColorPicker == nil
    }
    
    deinit {
        logger.v("Deinit add edit groups controller")
    }
}
