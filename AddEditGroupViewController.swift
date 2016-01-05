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

//change
protocol AddEditGroupControllerDelegate {
    func onGroupAdded(inventory: ListItemGroup)
    func onGroupUpdated(inventory: ListItemGroup)
}

// TODO after final design either remove color code or reenable it

class AddEditGroupViewController: UIViewController, FlatColorPickerControllerDelegate {
    
    @IBOutlet weak var groupNameInputField: UITextField!
    
    @IBOutlet weak var colorButton: UIButton!
    
    private var listInputsValidator: Validator?
    
    var delegate: AddEditGroupControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var listToEdit: ListItemGroup?
    
    private var showingColorPicker: FlatColorPickerController?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let listToEdit = listToEdit {
            prefill(listToEdit)
        }
        
        if !listToEdit.isSet {
            colorButton.tintColor = RandomFlatColorWithShade(.Dark)
        }
    }
    
    private func prefill(list: ListItemGroup) {
        groupNameInputField.text = list.name
        colorButton.tintColor = list.bgColor
        colorButton.imageView?.tintColor = list.bgColor
        
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.groupNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])
        
        self.listInputsValidator = listInputsValidator
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        groupNameInputField.becomeFirstResponder()
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
            
            if let weakSelf = self {
                
                if let listName = weakSelf.groupNameInputField.text {
                    if let listToEdit = weakSelf.listToEdit {
                        let updatedList = listToEdit.copy(name: listName)
                        
                        Providers.listItemGroupsProvider.update(updatedList, remote: true, weakSelf.successHandler{//change
                            weakSelf.delegate?.onGroupUpdated(updatedList)
                        })

                    } else {
//                        if let currentListsCount = weakSelf.currentListsCount { // TODO order
                        let inventoryWithSharedUsers = ListItemGroup(uuid: NSUUID().UUIDString, name: listName, bgColor: weakSelf.colorButton.tintColor)
                            Providers.listItemGroupsProvider.add(inventoryWithSharedUsers, remote: true, weakSelf.successHandler{
                                weakSelf.delegate?.onGroupAdded(inventoryWithSharedUsers)
                            })
                            
//                        } else {
//                            print("Error: no currentListsCount")
//                        }
                    }
                } else {
                    print("Error: validation was not implemented correctly")
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
            self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            onValid()
        }
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
        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
        
    }
    
    @IBAction func onAddUsersTap() {
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.view.frame = self!.view.frame.copy(height: 260)
            self?.view.layoutIfNeeded()
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
                
                }, completion: {finished in
                    self.showingColorPicker = nil
                    self.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self.colorButton.tintColor = selectedColor
                            self.colorButton.imageView?.tintColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self.colorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self.colorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                }
            )
        }
    }
}