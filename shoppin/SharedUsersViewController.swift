//
//  SharedUsersViewController.swift
//  shoppin
//
//  Created by ischuetz on 10/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import Providers

protocol SharedUsersViewControllerDelegate: class {
    // Note: this is only a table view update, no providers
    func onSharedUsersUpdated(_ users: [DBSharedUser])
}

class SharedUsersViewController: UIViewController {

    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!
    
    fileprivate var userInputsValidator: Validator?

    weak var delegate: SharedUsersViewControllerDelegate?

    var sharedUsers: [DBSharedUser] = [] {
        didSet {
            usersTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initValidator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        usersTableView.setEditing(true, animated: false)
        
        
    }
    
    fileprivate func validateInputs(_ validator: Validator?, onValid: () -> ()) {
        
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (_, error) in errors {
                (error.field as? ValidatableTextField)?.showValidationError()
            }
            // Outdated implementation
//            present(ValidationAlertCreator.create(errors), animated: true, completion: nil)

        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    (error.field as? ValidatableTextField)?.showValidationError()
                }
            }
            
            onValid()
        }
    }
    
    @IBAction func onAddUserTap(_ sender: UIButton) {
        self.validateInputs(self.userInputsValidator) {[weak self] in
            if let weakSelf = self {
                if let input = weakSelf.addUserInputField.text {
                    // TODO do later a verification here if email exists in the server
                    weakSelf.sharedUsers.append(DBSharedUser(email: input))
                    weakSelf.delegate?.onSharedUsersUpdated(weakSelf.sharedUsers)
                    weakSelf.addUserInputField.clear()

                } else {
                    print("Error: validation was not implemented correctly")
                }
            }
        }
    }
    
    fileprivate func initValidator() {
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [MinLengthRule(length: 1, message: trans("validation_user_input_not_empty"))])
        
        self.userInputsValidator = userInputsValidator
    }

    
    func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedUsers.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! InventorySharedUserCell
        let sharedUser = sharedUsers[(indexPath as NSIndexPath).row]
        cell.sharedUser = sharedUser
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle == .delete {
            self.usersTableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    weakSelf.sharedUsers.remove(at: (indexPath as NSIndexPath).row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    weakSelf.delegate?.onSharedUsersUpdated(weakSelf.sharedUsers)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
        return false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.addUserInputField.resignFirstResponder() // hide keyboard
    }

    func clear() {
        addUserInputField.clear()
    }
}
