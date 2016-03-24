//
//  SharedUsersController.swift
//  shoppin
//
//  Created by ischuetz on 24/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

protocol SharedUsersControllerDelegate {
    func onPull(user: SharedUser)
    func onUsersUpdated(users: [SharedUser])
}

private struct UserCellModel {
    let user: SharedUser
    let isNew: Bool
    init(user: SharedUser, isNew: Bool) {
        self.user = user
        self.isNew = isNew
    }
}

class SharedUsersController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewSharedUserCellDelegate, ExistingSharedUserCellDelegate {

    @IBOutlet weak var addUserInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    
    private var userInputsValidator: Validator?

    private var addButton: UIButton? = nil
    private var keyboardHeight: CGFloat?
    
    var users: [SharedUser] {
        return userModels.map{$0.user}
    }
    
    var delegate: SharedUsersControllerDelegate?
    
    private var userModels: [UserCellModel] = [] {
        didSet {
            usersTableView.reloadData()
        }
    }
    private var allKnownUsers: [SharedUser] = [] {
        didSet {
            updateCellModels()
        }
    }
    var existingUsers: [SharedUser] = [] {
        didSet {
            if usersTableView != nil {
                updateCellModels()
            } else {
                QL4("Outlets not initialised yet")
            }
        }
    }
    
    var onViewDidLoad: VoidFunction?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func initValidator() {
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [EmailRule(message: "validation_email_wrong")])
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Providers.userProvider.findAllKnownSharedUsers(successHandler {[weak self] sharedUsers in
            self?.allKnownUsers = sharedUsers
        })
        
        navigationItem.title = "Participants"
        
        initValidator()
        
        addUserInputField.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
        
        onViewDidLoad?()
        
        addAddButton()
    }
    
    // MARK: - Add button
    
    func addAddButton() {
        func add() {
            if let parentView = parentViewController?.view, window = view.window {
                let keyboardHeight = self.keyboardHeight ?? {
                    QL4("Couldn't get keyboard height dynamically, returning hardcoded value")
                    return 216
                }()
                let buttonHeight: CGFloat = 40
                
                let addButton = AddItemButton(frame: CGRectMake(0, window.frame.height - keyboardHeight - buttonHeight, parentView.frame.width, buttonHeight))
                self.addButton = addButton
                parentView.addSubview(addButton)
                parentView.bringSubviewToFront(addButton)
                addButton.tapHandler = {[weak self] in guard let weakSelf = self else {return}
                    weakSelf.tryAddInputUser()
                }
            } else {
                QL3("No parent view for add button")
            }
        }
        
        if addButton == nil {
            delay(0.5) {
                add()
            }
        }
    }
    
    // MARK: - Keyboard
    
    func keyboardWillAppear(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                keyboardHeight = keyboardSize.height
            } else {
                QL3("Couldn't retrieve keyboard size from user info")
            }
        } else {
            QL3("Notification has no user info")
        }
        
        delay(0.5) {[weak self] in // let the keyboard reach it's final position before showing the button
            self?.addButton?.hidden = false
        }
    }
    
    func keyboardWillDisappear(notification: NSNotification) {
        // when showing validation popup the keyboard disappears so we have to remove the button - otherwise it looks weird
        addButton?.hidden = true
    }
    
    // MARK: -

    func updateCellModels() {
        let existingUserModels = existingUsers.map{UserCellModel(user: $0, isNew: false)}
        let newUserModels = allKnownUsers.filter{!existingUsers.contains($0)}.map{UserCellModel(user: $0, isNew: true)}
        userModels = existingUserModels + newUserModels
    }
    
    private func tryAddInputUser() {
        if !ConnectionProvider.connectedAndLoggedIn {
            AlertPopup.show(message: "You must be logged in to share your list", controller: self)
            
        } else {
            validateInputs(userInputsValidator) {[weak self] in
                
                if let weakSelf = self {
                    if let inputEmail = weakSelf.addUserInputField.text {
                        SharedUserChecker.check(inputEmail, users: weakSelf.existingUsers, controller: weakSelf, onSuccess: {
                            let sharedUser = SharedUser(email: inputEmail)
                            weakSelf.addSharedUser(sharedUser)
                            weakSelf.addUserInputField.clear()
                        })
                    } else {
                        print("Error: validation was not implemented correctly")
                    }
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
    
    // MARK: - Table view
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userModels.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellModel = userModels[indexPath.row]
        if cellModel.isNew {
            let cell = tableView.dequeueReusableCellWithIdentifier("newUserCell", forIndexPath: indexPath) as! NewSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("existingUserCell", forIndexPath: indexPath) as! ExistingSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.usersTableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    weakSelf.userModels.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            }
        }
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    private func addSharedUser(sharedUser: SharedUser) {
        existingUsers.append(sharedUser)
        usersTableView.reloadData()
        delegate?.onUsersUpdated(existingUsers)
    }
    
    // MARK: - NewSharedUserCellDelegate
    
    func onAddSharedUser(sharedUser: SharedUser, cell: NewSharedUserCell) {
        addSharedUser(sharedUser)
    }
    
    // MARK: - ExistingSharedUserCellDelegate
    
    func onDeleteSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell) {
        existingUsers.remove(sharedUser)
        usersTableView.reloadData()
        delegate?.onUsersUpdated(existingUsers)
    }
    
    func onPullSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell) {
        delegate?.onPull(sharedUser)
    }
}
