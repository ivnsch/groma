//
//  AddEditInventoryController.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol AddEditInventoryControllerDelegate {
//    func onInventoryAdded(inventory: Inventory) not used yet - single inventory
    func onInventoryUpdated(inventory: Inventory)
}

class AddEditInventoryController: UIViewController, SharedUsersViewControllerDelegate {
    
    @IBOutlet weak var inventoryNameInputField: UITextField!
    @IBOutlet weak var userCountLabel: UILabel!
    
    private var inventoryInputsValidator: Validator?
    
    var delegate: AddEditInventoryControllerDelegate?
    
    var open: Bool = false
    
    var inventoryToEdit: Inventory?

    private var sharedUsersController: SharedUsersViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initValidator()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let inventoryToEdit = inventoryToEdit {
            prefill(inventoryToEdit)
        }
    }
    
    private func prefill(inventory: Inventory) {
        inventoryNameInputField.text = inventory.name
        updateSharedUsersLabel(inventory.users)
    }
    
    private func updateSharedUsersLabel(sharedUsers: [SharedUser]) {
        userCountLabel.text = sharedUsers.count > 0 ? "\(sharedUsers.count)" : ""
    }
    
    private func initValidator() {
        let inventoryInputsValidator = Validator()
        inventoryInputsValidator.registerField(self.inventoryNameInputField, rules: [MinLengthRule(length: 1, message: "validation_inventory_name_not_empty")])
        
        self.inventoryInputsValidator = inventoryInputsValidator
    }

    
    @IBAction func onDoneTap(sender: UIBarButtonItem) {
        submit()
    }
    
    func submit() {
        
        validateInputs(inventoryInputsValidator) {[weak self] in
            
            if let weakSelf = self {
                
                if let inventoryName = weakSelf.inventoryNameInputField.text {
                    if let inventoryToEdit = weakSelf.inventoryToEdit, sharedUsersController = weakSelf.sharedUsersController {
                        let updatedInventory = inventoryToEdit.copy(name: inventoryName, users: sharedUsersController.sharedUsers)
                        Providers.inventoryProvider.updateInventory(updatedInventory, weakSelf.successHandler{
                            weakSelf.delegate?.onInventoryUpdated(updatedInventory)
                        })
                        
                    } else {
                        // for now only single inventory
//                        let inventoryWithSharedUsers = Inventory(uuid: NSUUID().UUIDString, name: inventoryName, users: weakSelf.sharedUsers)
//                        weakSelf.inventoryProvider.addInventory(inventoryWithSharedUsers, weakSelf.successHandler{
//                            weakSelf.delegate?.onInventoryAdded(inventoryWithSharedUsers)
//                        })
                        print("Error: AddEditInventoryController.submit no item to edit. This controller currently supports only edit mode.")
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

    
    @IBAction func onAddUsersTap() {
        toggleUsersController()
    }
    
    private func toggleUsersController() {
        
        let originalHeight: CGFloat = 90 // TODO dynamic
        
        if let sharedUsersController = sharedUsersController { // close
            
            addChildViewControllerAndView(sharedUsersController)
            self.sharedUsersController = sharedUsersController
            
            UIView.animateWithDuration(0.3, animations: {[weak self] in
                self?.view.frame = self!.view.frame.copy(height: originalHeight)
                self?.view.layoutIfNeeded()
                
                }, completion: {[weak self] finished in
                    sharedUsersController.removeFromParentViewControllerWithView()
                    self?.sharedUsersController = nil
                })
            
        } else { // open
            
            let sharedUsersController = UIStoryboard.sharedUsersViewController()

            sharedUsersController.view.frame = CGRectMake(0, originalHeight, view.frame.width, 100)
            
            sharedUsersController.view.layer.anchorPoint = CGPointMake(0.5, 0)
            sharedUsersController.view.frame.origin = CGPointMake(0, sharedUsersController.view.frame.origin.y - 100 / 2)
            
            sharedUsersController.view.transform = CGAffineTransformMakeScale(1, 0.001)
            addChildViewControllerAndView(sharedUsersController)
            self.sharedUsersController = sharedUsersController

            sharedUsersController.delegate = self
            if let sharedUsers = inventoryToEdit?.users {
                sharedUsersController.sharedUsers = sharedUsers
            }

            UIView.animateWithDuration(0.3) {[weak self] in
                self?.view.frame = self!.view.frame.copy(height: 260)
                self?.view.layoutIfNeeded()
                sharedUsersController.view.transform = CGAffineTransformMakeScale(1, 1)
            }
        }
    }
    
    func clear() {
        inventoryNameInputField.clear()
        inventoryToEdit = nil
        
        if sharedUsersController != nil {
            toggleUsersController()
        }
    }
    
    // MARK - SharedUsersViewControllerDelegate
    
    func onSharedUsersUpdated(users: [SharedUser]) {
        updateSharedUsersLabel(users)
    }
}
