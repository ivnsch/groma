//
//  SharedUsersController.swift
//  shoppin
//
//  Created by ischuetz on 24/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers

protocol SharedUsersControllerDelegate: class {
    func onPull(_ user: DBSharedUser)
    func onUsersUpdated(_ existingUsers: [DBSharedUser], invitedUsers: [DBSharedUser])
    func invitedUsers(_ handler: @escaping ([DBSharedUser]) -> Void)
}

private enum SharedUserState {case new, existing, invited}

private struct UserCellModel {
    let user: DBSharedUser
    let state: SharedUserState
    init(user: DBSharedUser, state: SharedUserState) {
        self.user = user
        self.state = state
    }
}

class SharedUsersController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewSharedUserCellDelegate, ExistingSharedUserCellDelegate, InvitedSharedUserCellDelegate {

    @IBOutlet weak var addUserInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    
    fileprivate var userInputsValidator: Validator?
    
    var users: [DBSharedUser] {
        return userModels.map{$0.user}
    }
    
    weak var delegate: SharedUsersControllerDelegate?
    
    fileprivate var userModels: [UserCellModel] = [] {
        didSet {
            usersTableView.reloadData()
        }
    }
    
    fileprivate var existingUsers: [DBSharedUser] = []
    fileprivate var invitedUsers: [DBSharedUser] = []
    fileprivate var allKnownUsers: [DBSharedUser] = []

    var onViewDidLoad: VoidFunction?

    func initUsers(_ existing: [DBSharedUser], invited: [DBSharedUser], all: [DBSharedUser]) {
        self.existingUsers = existing
        self.invitedUsers = invited
        self.allKnownUsers = all
        updateCellModels()
    }
    
    fileprivate func initValidator() {
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [EmailRule(message: trans("validation_email_format"))])
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = trans("title_participants")
        
        initValidator()
        
        addUserInputField.becomeFirstResponder()
        
        onViewDidLoad?()
        
        addUserInputField.text = "ivanschuetz2@gmail.com"
        
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let tabBarHeight = tabBarController?.tabBar.bounds.size.height else {logger.e("No tabBarController"); return nil}
        
        let overrideCenterY: CGFloat = view.frame.height + tabBarHeight
        let addButtonHelper = AddButtonHelper(parentView: view, overrideCenterY: overrideCenterY) {[weak self] in
            self?.tryAddInputUser()
        }
        return addButtonHelper
    }
    
    // MARK: -

    func updateCellModels() {
        let invitedUserModels = invitedUsers.map{UserCellModel(user: $0, state: .invited)}
        
        // For existing we have to filter out invited, because currently we store locally the invited users in shared users of the list, so when we edit the list (without having done sync, which would remove the invited users from shared users, as the server doesn't store them here) we would get duplicates (we call separately invited users service, to get the invited users).
        let existingUserModels = existingUsers.filter{!invitedUsers.contains($0)}.map{UserCellModel(user: $0, state: .existing)}
        let newUserModels = allKnownUsers.filter{!existingUsers.contains($0) && !invitedUsers.contains($0)}.map{UserCellModel(user: $0, state: .new)}
        
        userModels = existingUserModels + invitedUserModels + newUserModels
    }
    
    fileprivate func tryAddInputUser() {
        if !ConnectionProvider.connectedAndLoggedIn {
            MyPopupHelper.showPopup(parent: self, type: .error, message: trans("popups_participants_must_be_logged_in"), centerYOffset: -80)

        } else {
            validateInputs(userInputsValidator) {[weak self] in
                
                if let weakSelf = self {
                    if let inputEmail = weakSelf.addUserInputField.text {
                        SharedUserChecker.check(inputEmail, users: weakSelf.existingUsers, controller: weakSelf, onSuccess: {
                            let sharedUser = DBSharedUser(email: inputEmail)
                            weakSelf.addSharedUser(sharedUser)
                            weakSelf.addUserInputField.clear()
                            
                            // TODO!!!! improve this, functionality is a bit weird. either submit the users immediately (needs maybe separate service?) or add some sort of indicator to add/edit screen showing that submitting the updated users is pending. At very least add a preference to show this dialog only once.
                            MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: trans("popups_participants_invitation_explanation"), okText: trans("popup_button_got_it"), centerYOffset: -80)
                        })
                    } else {
                        print("Error: validation was not implemented correctly")
                    }
                }
            }
        }
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
    
    // MARK: - Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModel = userModels[(indexPath as NSIndexPath).row]
        switch cellModel.state {
        case .new:
            let cell = tableView.dequeueReusableCell(withIdentifier: "newUserCell", for: indexPath) as! NewSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        case .existing:
            let cell = tableView.dequeueReusableCell(withIdentifier: "existingUserCell", for: indexPath) as! ExistingSharedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        case .invited:
            let cell = tableView.dequeueReusableCell(withIdentifier: "invitedUserCell", for: indexPath) as! InvitedUserCell
            cell.sharedUser = cellModel.user
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.usersTableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    weakSelf.userModels.remove(at: (indexPath as NSIndexPath).row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    fileprivate func addSharedUser(_ sharedUser: DBSharedUser) {
        invitedUsers.append(sharedUser)
        updateCellModels()
        usersTableView.reloadData()
        notifyDelegateUsersUpdated()
    }
    
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == addUserInputField {
            tryAddInputUser()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    // MARK: - NewSharedUserCellDelegate
    
    func onAddSharedUser(_ sharedUser: DBSharedUser, cell: NewSharedUserCell) {
        addSharedUser(sharedUser)
    }
    
    // MARK: - ExistingSharedUserCellDelegate
    
    func onDeleteSharedUser(_ sharedUser: DBSharedUser, cell: ExistingSharedUserCell) {
        _ = existingUsers.remove(sharedUser)
        updateCellModels()
        usersTableView.reloadData()
        notifyDelegateUsersUpdated()
    }
    
    fileprivate func notifyDelegateUsersUpdated() {
        delegate?.onUsersUpdated(existingUsers, invitedUsers: invitedUsers)
    }
    
    func onPullSharedUser(_ sharedUser: DBSharedUser, cell: ExistingSharedUserCell) {
        delegate?.onPull(sharedUser)
    }
    
    // MARK: - InvitedSharedUserCellDelegate
    
    func onInviteInfoSharedUser(_ sharedUser: DBSharedUser, cell: InvitedUserCell) {
        MyPopupHelper.showPopup(parent: self, type: .info, message: trans("popups_invitation_pending"), centerYOffset: -80)
    }
}
