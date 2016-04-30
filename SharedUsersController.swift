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
        
        onViewDidLoad?()
        
        addUserInputField.text = "ivanschuetz2@gmail.com"
        
    }
    
    private func initAddButtonHelper() -> AddButtonHelper? {
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {QL4("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = view.frame.height + tabBarHeight
        let addButtonHelper = AddButtonHelper(parentView: view, overrideCenterY: overrideCenterY) {[weak self] in
            self?.tryAddInputUser()
        }
        return addButtonHelper
    }
    
    // MARK: -

    func updateCellModels() {
        let invitedUserModels = invitedUsers.map{UserCellModel(user: $0, state: .Invited)}
        
        // For existing we have to filter out invited, because currently we store locally the invited users in shared users of the list, so when we edit the list (without having done sync, which would remove the invited users from shared users, as the server doesn't store them here) we would get duplicates (we call separately invited users service, to get the invited users).
        let existingUserModels = existingUsers.filter{!invitedUsers.contains($0)}.map{UserCellModel(user: $0, state: .Existing)}
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
                            
                            // TODO!!!! improve this, functionality is a bit weird. either submit the users immediately (needs maybe separate service?) or add some sort of indicator to add/edit screen showing that submitting the updated users is pending. At very least add a preference to show this dialog only once.
                            AlertPopup.show(title: "Info", message: "The user has not been invited yet. To submit the invitations you have to submit the list.\nIf you close the list without submitting, the participants list is resetted and no invitations are sent.", controller: weakSelf, okMsg: "Got it!")
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
    
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == addUserInputField {
            tryAddInputUser()
            sender.resignFirstResponder()
        }
        
        return false
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
