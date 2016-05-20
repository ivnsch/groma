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
import QorumLogs

//change
protocol AddEditGroupControllerDelegate: class {
    func onAddGroup(group: ListItemGroup)
    func onUpdateGroup(group: ListItemGroup)
}

// TODO after final design either remove color code or reenable it

class AddEditGroupViewController: UIViewController, FlatColorPickerControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var groupNameInputField: UITextField!
    
    @IBOutlet weak var colorButton: UIButton!
    
    private var listInputsValidator: Validator?
    
    weak var delegate: AddEditGroupControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var listToEdit: ListItemGroup? {
        didSet {
            if let listToEdit = listToEdit {
                prefill(listToEdit)
            }
        }
    }
    
    private var showingColorPicker: FlatColorPickerController?
    
    private var addButtonHelper: AddButtonHelper?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        addButtonHelper = initAddButtonHelper()
        addButtonHelper?.addObserver()
    }
    
    private func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parentViewController?.view else {QL4("No parentController"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            self?.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    
    private func prefill(list: ListItemGroup) {
        groupNameInputField.text = list.name
        setBackgroundColor(list.bgColor)
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.groupNameInputField, rules: [MinLengthRule(length: 1, message: trans("validation_group_name_not_empty"))])
        
        self.listInputsValidator = listInputsValidator
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        groupNameInputField.setPlaceholderWithColor(trans("placeholder_group_name"), color: UIColor.whiteColor())
        
        setBackgroundColor(UIColor.randomColor())
        
        groupNameInputField.becomeFirstResponder()
    }
    
    private func setBackgroundColor(color: UIColor) {
        
        func setContrastingTextColor(color: UIColor) {
            guard groupNameInputField != nil else {QL4("Outlets not initialised yet"); return}
            
            let contrastingTextColor = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
            
            groupNameInputField.setPlaceholderWithColor(trans("placeholder_group_name"), color: contrastingTextColor)
            groupNameInputField.textColor = contrastingTextColor
            colorButton.setTitleColor(contrastingTextColor, forState: .Normal)
        }
        
        view.backgroundColor = color
        setContrastingTextColor(color)
    }
    
    @IBAction func onDoneTap(sender: UIBarButtonItem) {
        submit()
    }
    
    func submit() {
        
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) {[weak self] in
            
            guard let weakSelf = self else {return}
            guard let bgColor = weakSelf.view.backgroundColor else {QL4("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.groupNameInputField.text else {QL4("Validation was not implemented correctly"); return}

            if let listToEdit = weakSelf.listToEdit {
                let updatedGroup = listToEdit.copy(name: listName, bgColor: bgColor)
                weakSelf.delegate?.onUpdateGroup(updatedGroup)
            } else {
                if let currentListsCount = weakSelf.currentListsCount {
                    let group = ListItemGroup(uuid: NSUUID().UUIDString, name: listName, bgColor: bgColor, order: currentListsCount)
                    weakSelf.delegate?.onAddGroup(group)
                } else {
                    QL4("No currentListsCount")
                }
            }
        }
    }
    
    private func validateInputs(validator: Validator?, onValid: () -> ()) {
        
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            onValid()
        }
    }
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == groupNameInputField {
            submit()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func onCloseTap(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parentViewController {
            
            let topBarHeight: CGFloat = 64
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convertPoint(CGPointMake(colorButton.center.x, colorButton.center.y - topBarHeight), fromView: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPointMake(fractionX, fractionY)
            
            picker.view.frame = CGRectMake(0, topBarHeight, parentViewController.view.frame.width, parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransformMakeScale(0, 0)
            
            UIView.animateWithDuration(0.3) {
                picker.view.transform = CGAffineTransformMakeScale(1, 1)
            }
            
            view.endEditing(true)
            
        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
        
    }
    
    func clear() {
        groupNameInputField.clear()
        listToEdit = nil
        
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
        //        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    private func dismissColorPicker(selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animateWithDuration(0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransformMakeScale(0.001, 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self?.setBackgroundColor(selectedColor)
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self?.colorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self?.colorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                    
                    self?.groupNameInputField.becomeFirstResponder()
                }
            )
        }
    }
    
    deinit {
        QL1("Deinit add edit groups controller")
    }
}