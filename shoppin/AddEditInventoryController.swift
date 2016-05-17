//
//  AddEditInventoryController.swift
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
protocol AddEditInventoryControllerDelegate: class {
    func onAddInventory(inventory: Inventory)
    func onUpdateInventory(inventory: Inventory)
}

// TODO try to refactor with AddEditListController, lot of repeated code
class AddEditInventoryController: UIViewController, FlatColorPickerControllerDelegate, SharedUsersControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var listNameInputField: UITextField!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var sharedUsersButton: UIButton!
    
    private var listInputsValidator: Validator?
    
    weak var delegate: AddEditInventoryControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var listToEdit: Inventory? {
        didSet {
            if let listToEdit = listToEdit {
                prefill(listToEdit)
            }
        }
    }
    
    private var showingColorPicker: FlatColorPickerController?
    
    private var addButtonHelper: AddButtonHelper?

    private var users: [SharedUser] = [] {
        didSet {
            if !users.isEmpty {
                let title: String = {
                    if users.count == 1 {
                        return "\(users.count) participant"
                    } else {
                        return "\(users.count) participants"
                    }
                }()
                sharedUsersButton.setTitle(title, forState: .Normal)
            }
        }
    }
    private var invitedUsers: [SharedUser] = []
    
    private func prefill(list: Inventory) {
        listNameInputField.text = list.name
        
        users = list.users
        
        let sharedButtonVisible: Bool = {
            if ConnectionProvider.connectedAndLoggedIn {
                return true // if the user is connected and logged in, always shows the participants button
            } else {
                // if user is not connected/logged in, show participants button only if the list has already some participants. This is to avoid confusion, if there's no connection/account and list has no participants we just don't bother the user showing this button. If the list has participants though we show it, and show a dialog about missing connection/login if user taps it, so user knows why the probably expected (as the list has already participants) sharing functionality is not available. This overwrites the visibility set in viewDidLoad, which sets by default hidden when there's no connection/account.
                return !users.isEmpty
            }
        }()
        setSharedButtonVisibile(sharedButtonVisible)
        
        setBackgroundColor(list.bgColor)
    }
    
    private func setSharedButtonVisibile(visible: Bool) {
        sharedUsersButton.hidden = !visible
        colorButton.contentHorizontalAlignment = visible ? .Center : .Right
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.listNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])
        self.listInputsValidator = listInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        listNameInputField.setPlaceholderWithColor("Inventory name", color: UIColor.whiteColor())
        
        setBackgroundColor(UIColor.randomFlatColor())
        
        listNameInputField.becomeFirstResponder()
        
        setSharedButtonVisibile(ConnectionProvider.connectedAndLoggedIn)
    }
    
    private func setBackgroundColor(color: UIColor) {
        
        func setContrastingTextColor(color: UIColor) {
            guard listNameInputField != nil else {QL4("Outlets not initialised yet"); return}
            
            let contrastingTextColor = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
            
            listNameInputField.setPlaceholderWithColor("Inventory name", color: contrastingTextColor)
            listNameInputField.textColor = contrastingTextColor
            colorButton.setTitleColor(contrastingTextColor, forState: .Normal)
            sharedUsersButton.setTitleColor(contrastingTextColor, forState: .Normal)
        }
        
        view.backgroundColor = color
        setContrastingTextColor(color)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        listNameInputField.becomeFirstResponder()
        
        if addButtonHelper == nil {
            addButtonHelper = initAddButtonHelper() // in view did load parentViewController is nil
        }
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
    
    func submit() {
        
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) {[weak self] in
            
            guard let weakSelf = self else {return}
            guard let bgColor = weakSelf.view.backgroundColor else {QL4("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.listNameInputField.text else {QL4("Validation was not implemented correctly"); return}

            if let listToEdit = weakSelf.listToEdit {
                
                let totalUsers = weakSelf.users + weakSelf.invitedUsers

                let updatedInventory = listToEdit.copy(name: listName, users: totalUsers, bgColor: bgColor)
                weakSelf.delegate?.onUpdateInventory(updatedInventory)

            } else {
                if let currentListsCount = weakSelf.currentListsCount {
                    
                    // If it's a new inventory add myself as a participant, to be consistent with list after server updates it (server adds the caller as a participant)
                    let totalUsers = (Providers.userProvider.mySharedUser.map{[$0]} ?? []) + weakSelf.invitedUsers
                    
                    let inventory = Inventory(uuid: NSUUID().UUIDString, name: listName, users: totalUsers, bgColor: bgColor, order: currentListsCount)//change
                    weakSelf.delegate?.onAddInventory(inventory)
                } else {
                    print("Error: no currentListsCount")
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
    
    @IBAction func onSharedUsersTap() {
        if ConnectionProvider.connectedAndLoggedIn {
            let sharedUsersController = UIStoryboard.sharedUsersController()
            self.parentViewController?.navigationController?.pushViewController(sharedUsersController, animated: true)
            self.parentViewController?.navigationController?.setNavigationBarHidden(false, animated: false)
            sharedUsersController.delegate = self
            sharedUsersController.onViewDidLoad = {[weak self] in guard let weakSelf = self else {return}
                // we load the invited/known users on demand, so we load each time when we open the controller (we could also have a lazy variable but loading each time doesn't hurt, maybe we get updates of other users in the meantime).
                // we call this on view did load to ensure 100% init happens after outlets are sest
                weakSelf.loadKnownAndInvitedUsers{(known, invited) in
                    
                    // besides the users that have been already invited (submitted - come in server response), we also want to show possible invited users that have not been submitted yet (the user opened shared users controllers, added them, went back, opens again shared user controller, without leaving add/edit). Note that these appear equal to the submitted invitations. The difference, is that the not submitted ones will disappear after the user closes add/edit.
                    // we need to use distinct because the invited users we get from shared users controller(weakSelf.invitedUsers) of course contains both, and when we request invites from server(invited) there will be duplicates.
                    let allInvited = (invited + weakSelf.invitedUsers).distinctUsingEquatable()
                    
                    sharedUsersController.initUsers(weakSelf.users, invited: allInvited, all: known)
                }
            }
        
        } else {
            AlertPopup.show(message: NSLocalizedString("popup_please_login_for_participants", comment: ""), controller: self)
        }
    }
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == listNameInputField {
            submit()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    private func loadKnownAndInvitedUsers(onLoaded: (known: [SharedUser], invited: [SharedUser]) -> Void) {
        var allResult: [SharedUser]?
        var invitedResult: [SharedUser]?
        func check() {
            if let allResult = allResult, invitedResult = invitedResult {
                onLoaded(known: allResult, invited: invitedResult)
            }
        }
        Providers.userProvider.findAllKnownSharedUsers(successHandler {sharedUsers in
            allResult = sharedUsers
            check()
        })
        
        if let inventory = listToEdit {
            Providers.inventoryProvider.findInvitedUsers(inventory.uuid, successHandler {sharedUsers in
                invitedResult = sharedUsers
                check()
            })
        } else {
            invitedResult = []
            check()
        }
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
                    
                    self?.listNameInputField.becomeFirstResponder()
                }
            )
        }
    }
    
    // MARK: - SharedUsersControllerDelegate
    
    func onPull(user: SharedUser) {
        progressVisible(true)
        if let inventory = listToEdit {
            Providers.pullProvider.pullInventoryProducs(inventory.uuid, srcUser: user, successHandler{[weak self] products in  guard let weakSelf = self else {return}
                self?.progressVisible(false)
                AlertPopup.show(title: trans("popup_title_success"), message: trans("popup_please_login_for_participants"), controller: weakSelf)
            })
        }
    }
    
    func onUsersUpdated(exitingUsers: [SharedUser], invitedUsers: [SharedUser]) {
        self.users = exitingUsers
        self.invitedUsers = invitedUsers
    }
    
    func invitedUsers(handler: [SharedUser] -> Void) {
        if let inventory = listToEdit {
            Providers.inventoryProvider.findInvitedUsers(inventory.uuid, successHandler {users in
                handler(users)
            })
        } else { // adding inventory - there can't be invited users yet
            handler([])
        }
    }
    
    deinit {
        QL1("Deinit add edit inventory controller")
    }
}

