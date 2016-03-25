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
    func onUsersUpdated(existingUsers: [SharedUser], invitedUsers: [SharedUser])
    func invitedUsers(handler: [SharedUser] -> Void)
}

private enum SharedUserState {case New, Existing, Invited}

private struct UserCellModel {
    let user: SharedUser
    let state: SharedUserState
    init(user: SharedUser, state: SharedUserState) {
        self.user = user
        self.state = state
    }
}

class SharedUsersController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewSharedUserCellDelegate, ExistingSharedUserCellDelegate, InvitedSharedUserCellDelegate {

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
    
    private var existingUsers: [SharedUser] = []
    private var invitedUsers: [SharedUser] = []
    private var allKnownUsers: [SharedUser] = []

    var onViewDidLoad: VoidFunction?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func initUsers(existing: [SharedUser], invited: [SharedUser], all: [SharedUser]) {
        self.existingUsers = existing
        self.invitedUsers = invited
        self.allKnownUsers = all
        updateCellModels()
    }
    
    private func initValidator() {
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [EmailRule(message: "validation_email_wrong")])
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        let existingUserModels = existingUsers.map{UserCellModel(user: $0, state: .Existing)}
        let invitedUserModels = invitedUsers.map{UserCellModel(user: $0, state: .Invited)}
        let newUserModels = allKnownUsers.filter{!existingUsers.contains($0) && !invitedUsers.contains($0)}.map{UserCellModel(user: $0, state: .New)}
        userModels = existingUserModels + invitedUserModels + newUserModels
    }
    
    private func tryAddInputUser() {
        if !ConnectionProvider.connectedAndLoggedIn {
            AlertPopup.show(message: "You must be logged in to share with other users", controller: self)
            
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
        switch cellModel.state {
        case .New:
            let cell = tableView.dequeueReusableCellWithIdentifier("newUserCell", forIndexPath: indexPath) as! NewSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        case .Existing:
            let cell = tableView.dequeueReusableCellWithIdentifier("existingUserCell", forIndexPath: indexPath) as! ExistingSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        case .Invited:
            let cell = tableView.dequeueReusableCellWithIdentifier("invitedUserCell", forIndexPath: indexPath) as! InvitedUserCell
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
        invitedUsers.append(sharedUser)
        updateCellModels()
        usersTableView.reloadData()
        notifyDelegateUsersUpdated()
    }
    
    // MARK: - NewSharedUserCellDelegate
    
    func onAddSharedUser(sharedUser: SharedUser, cell: NewSharedUserCell) {
        addSharedUser(sharedUser)
    }
    
    // MARK: - ExistingSharedUserCellDelegate
    
    func onDeleteSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell) {
        existingUsers.remove(sharedUser)
        updateCellModels()
        usersTableView.reloadData()
        notifyDelegateUsersUpdated()
    }
    
    private func notifyDelegateUsersUpdated() {
        delegate?.onUsersUpdated(existingUsers, invitedUsers: invitedUsers)
    }
    
    func onPullSharedUser(sharedUser: SharedUser, cell: ExistingSharedUserCell) {
        delegate?.onPull(sharedUser)
    }
    
    // MARK: - InvitedSharedUserCellDelegate
    
    func onInviteInfoSharedUser(sharedUser: SharedUser, cell: InvitedUserCell) {
        AlertPopup.show(message: "Invitation pending", controller: self)
    }
}
