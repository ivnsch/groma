//
//  SharedUsersViewController.swift
//  shoppin
//
//  Created by ischuetz on 10/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol SharedUsersViewControllerDelegate: class {
    // Note: this is only a table view update, no providers
    func onSharedUsersUpdated(users: [SharedUser])
}

class SharedUsersViewController: UIViewController {

    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!
    
    private var userInputsValidator: Validator?

    weak var delegate: SharedUsersViewControllerDelegate?

    var sharedUsers: [SharedUser] = [] {
        didSet {
            usersTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initValidator()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        usersTableView.setEditing(true, animated: false)
        
        
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
    
    @IBAction func onAddUserTap(sender: UIButton) {
        self.validateInputs(self.userInputsValidator) {[weak self] in
            if let weakSelf = self {
                if let input = weakSelf.addUserInputField.text {
                    // TODO do later a verification here if email exists in the server
                    weakSelf.sharedUsers.append(SharedUser(email: input))
                    weakSelf.delegate?.onSharedUsersUpdated(weakSelf.sharedUsers)
                    weakSelf.addUserInputField.clear()

                } else {
                    print("Error: validation was not implemented correctly")
                }
            }
        }
    }
    
    private func initValidator() {
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [MinLengthRule(length: 1, message: trans("validation_user_input_not_empty"))])
        
        self.userInputsValidator = userInputsValidator
    }

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedUsers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! InventorySharedUserCell
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
                    weakSelf.delegate?.onSharedUsersUpdated(weakSelf.sharedUsers)
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

    func clear() {
        addUserInputField.clear()
    }
}