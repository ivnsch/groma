//
//  AddEditListController.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import ChameleonFramework

protocol AddEditListControllerDelegate {
    func onListAdded(list: List)
    func onListUpdated(list: List)
}

class AddEditListController: UIViewController, UITableViewDataSource, UITableViewDelegate, FlatColorPickerControllerDelegate {
    
    private var listProvider = ProviderFactory().listProvider
    
    @IBOutlet weak var listNameInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!
    @IBOutlet weak var userCountLabel: UILabel!
    
    @IBOutlet weak var colorButton: UIButton!

    private var listInputsValidator: Validator?
    private var userInputsValidator: Validator?
    
    var delegate: AddEditListControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var listToEdit: List?
    
    var sharedUsers: [SharedUser] = [] {
        didSet {
            usersTableView.reloadData()
            userCountLabel.text = sharedUsers.count > 0 ? "\(sharedUsers.count)" : ""
        }
    }
    
    private var showingColorPicker: FlatColorPickerController?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        usersTableView.setEditing(true, animated: false)
        
        if let listToEdit = listToEdit {
            prefill(listToEdit)
        }
        
        if !listToEdit.isSet {
            colorButton.tintColor = RandomFlatColorWithShade(.Dark)
        }
    }
    
    private func prefill(list: List) {
        listNameInputField.text = list.name
        sharedUsers = list.users
        colorButton.tintColor = list.bgColor
        colorButton.imageView?.tintColor = list.bgColor
        
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.listNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])
        
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [MinLengthRule(length: 1, message: "validation_user_input_not_empty")])
        
        self.listInputsValidator = listInputsValidator
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initValidator()
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
                
                if let listName = weakSelf.listNameInputField.text {
                    if let listToEdit = weakSelf.listToEdit {
                        let updatedList = listToEdit.copy(name: listName, users: weakSelf.sharedUsers, bgColor: weakSelf.colorButton.tintColor)
                        weakSelf.listProvider.update([updatedList], weakSelf.successHandler{
                            weakSelf.delegate?.onListUpdated(updatedList)
                        })
                    
                    } else {
                        if let currentListsCount = weakSelf.currentListsCount {
                            let listWithSharedUsers = List(uuid: NSUUID().UUIDString, name: listName, listItems: [], users: weakSelf.sharedUsers, bgColor: weakSelf.colorButton.tintColor, order: currentListsCount)
                            weakSelf.listProvider.add(listWithSharedUsers, weakSelf.successHandler{list in
                                weakSelf.delegate?.onListAdded(list)
                            })
                        } else {
                            print("Error: no currentListsCount")
                        }
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
    
    @IBAction func onAddUserTap(sender: UIButton) {
        self.validateInputs(userInputsValidator) {[weak self] in
            if let weakSelf = self {
                if let input = weakSelf.addUserInputField.text {
                    // TODO do later a verification here if email exists in the server
                    weakSelf.sharedUsers.append(SharedUser(email: input))
                    weakSelf.addUserInputField.clear()
                    
                } else {
                    print("Error: validation was not implemented correctly")
                }
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedUsers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! ListSharedUserCell
        let sharedUser = sharedUsers[indexPath.row]
        cell.sharedUser = sharedUser
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.usersTableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    weakSelf.sharedUsers.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.addUserInputField.resignFirstResponder() // hide keyboard
    }

    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded()
        
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
        listNameInputField.clear()
        addUserInputField.clear()
        sharedUsers = []
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
