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

import RealmSwift
import Providers

//change
protocol AddEditInventoryControllerDelegate: class {
    func onAddInventory(_ inventory: DBInventory)
    func onUpdateInventory(_ inventory: DBInventory, inventoryInput: InventoryInput)
}

// TODO try to refactor with AddEditListController, lot of repeated code
class AddEditInventoryController: UIViewController, FlatColorPickerControllerDelegate, SharedUsersControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var listNameInputField: UITextField!
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var sharedUsersButton: UIButton!

    @IBOutlet weak var colorButtonHCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var colorButtonRightPaddingConstraint: NSLayoutConstraint!

    fileprivate var listInputsValidator: Validator?
    
    weak var delegate: AddEditInventoryControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    var listToEdit: DBInventory? {
        didSet {
            if let listToEdit = listToEdit {
                prefill(listToEdit)
            }
        }
    }
    
    fileprivate var showingColorPicker: FlatColorPickerController?
    
    fileprivate var addButtonHelper: AddButtonHelper?

    fileprivate var users: [DBSharedUser] = [] {
        didSet {
            if !users.isEmpty {
                let title: String = {
                    if users.count == 1 {
                        return trans("participants_count_singular", "\(users.count)")
                    } else {
                        return trans("participants_count_plural", "\(users.count)")
                    }
                }()
                sharedUsersButton.setTitle(title, for: UIControlState())
            }
        }
    }
    fileprivate var invitedUsers: [DBSharedUser] = []
    
    fileprivate func prefill(_ inventory: DBInventory) {
        listNameInputField.text = inventory.name
        
        users = inventory.users.toArray()
        
        let sharedButtonVisible: Bool = {
            if ConnectionProvider.connectedAndLoggedIn {
//                return true // if the user is connected and logged in, always shows the participants button
                return false // for now always false since sharing it's working yet
            } else {
                // if user is not connected/logged in, show participants button only if the list has already some participants. This is to avoid confusion, if there's no connection/account and list has no participants we just don't bother the user showing this button. If the list has participants though we show it, and show a dialog about missing connection/login if user taps it, so user knows why the probably expected (as the list has already participants) sharing functionality is not available. This overwrites the visibility set in viewDidLoad, which sets by default hidden when there's no connection/account.
                return !users.isEmpty
            }
        }()
        setSharedButtonVisibile(sharedButtonVisible)
        
        setBackgroundColor(inventory.bgColor())
    }
    
    fileprivate func setSharedButtonVisibile(_ visible: Bool) {
        sharedUsersButton.isHidden = !visible
        
        colorButtonHCenterConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(visible ? 999 : 998))
        colorButtonRightPaddingConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(visible ? 998 : 999))
    }
    
    fileprivate func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.listNameInputField, rules: [NotEmptyTrimmedRule(message: trans("validation_inventory_name_not_empty"))])
        self.listInputsValidator = listInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
        
        listNameInputField.setPlaceholderWithColor(trans("placeholder_inventory_name"), color: UIColor.white)
        
        setBackgroundColor(UIColor.randomFlat)
        
        listNameInputField.becomeFirstResponder()
        
//        setSharedButtonVisibile(ConnectionProvider.connectedAndLoggedIn)
        setSharedButtonVisibile(false) // for now always false since sharing it's working yet
    }
    
    fileprivate func setBackgroundColor(_ color: UIColor) {
        
        func setContrastingTextColor(_ color: UIColor) {
            guard listNameInputField != nil else {logger.e("Outlets not initialised yet"); return}
            
            let contrastingTextColor = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
            
            listNameInputField.setPlaceholderWithColor(trans("placeholder_inventory_name"), color: contrastingTextColor)
            listNameInputField.textColor = contrastingTextColor
            colorButton.setTitleColor(contrastingTextColor, for: .normal)
            sharedUsersButton.setTitleColor(contrastingTextColor, for: .normal)
        }
        
        view.backgroundColor = color
        setContrastingTextColor(color)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        listNameInputField.becomeFirstResponder()
        
        if addButtonHelper == nil {
            addButtonHelper = initAddButtonHelper() // in view did load parentViewController is nil
        }
        addButtonHelper?.addObserver()
    }
    
    fileprivate func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentView = parent?.view else {logger.e("No parentController"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentView) {[weak self] in
            self?.submit()
        }
        return addButtonHelper
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
            guard let bgColor = weakSelf.view.backgroundColor else {logger.e("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.listNameInputField.text?.trim() else {logger.e("Validation was not implemented correctly"); return}

            if let listToEdit = weakSelf.listToEdit {
                
//                let totalUsers = weakSelf.users + weakSelf.invitedUsers // TODO?

                let inventoryInput = InventoryInput(name: listName, color: bgColor)
                
                weakSelf.delegate?.onUpdateInventory(listToEdit, inventoryInput: inventoryInput)

            } else {
                if let currentListsCount = weakSelf.currentListsCount {
                    
                    // If it's a new inventory add myself as a participant, to be consistent with list after server updates it (server adds the caller as a participant)
                    
                    let totalUsers = (Prov.userProvider.mySharedUser.map{[$0]} ?? []) + weakSelf.invitedUsers
                    
                    let inventory = DBInventory(uuid: NSUUID().uuidString, name: listName, users: totalUsers, bgColor: bgColor, order: currentListsCount)
                    
                    weakSelf.delegate?.onAddInventory(inventory)
                } else {
                    print("Error: no currentListsCount")
                }
            }
        }
    }
    
    fileprivate func validateInputs(_ validator: Validator?, onValid: () -> ()) {
        
        guard validator != nil else {return}

        if let errors = validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
            }

            let currentFirstResponder = listNameInputField.isFirstResponder ? listNameInputField : nil
            view.endEditing(true)
            ValidationAlertCreator.present(errors, parent: root, firstResponder: currentFirstResponder)

        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    error.field.clearValidationError()
                }
            }
            
            onValid()
        }
    }
    
    @IBAction func onColorTap() {
        let picker = UIStoryboard.listColorPicker()
        self.view.layoutIfNeeded() // TODO is this necessary? don't think so check and remove
        
        if let parentViewController = parent {
            
            let topBarHeight: CGFloat = Theme.navBarHeight
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            parentViewController.addChildViewControllerAndView(picker) // add to superview (lists controller) because it has to occupy full space (navbar - tab)
            picker.delegate = self
            showingColorPicker = picker
            
            let buttonPointInParent = parentViewController.view.convert(CGPoint(x: colorButton.center.x, y: colorButton.center.y - topBarHeight), from: view)
            let fractionX = buttonPointInParent.x / parentViewController.view.frame.width
            let fractionY = buttonPointInParent.y / (parentViewController.view.frame.height - topBarHeight)
            
            picker.view.layer.anchorPoint = CGPoint(x: fractionX, y: fractionY)
            
            picker.view.frame = CGRect(x: 0, y: topBarHeight, width: parentViewController.view.frame.width, height: parentViewController.view.frame.height - topBarHeight)
            
            picker.view.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            UIView.animate(withDuration: 0.3, animations: {
                picker.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }) 
            
            view.endEditing(true)

        } else {
            print("Warning: AddEditListController.onColorTap: no parentViewController")
        }
    }
    
    @IBAction func onSharedUsersTap() {
        if ConnectionProvider.connectedAndLoggedIn {
            let sharedUsersController = UIStoryboard.sharedUsersController()
            self.parent?.navigationController?.pushViewController(sharedUsersController, animated: true)
            self.parent?.navigationController?.setNavigationBarHidden(false, animated: false)
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
            MyPopupHelper.showPopup(parent: self, type: .info, message: trans("popup_please_login_for_participants"), centerYOffset: -80)
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == listNameInputField {
            submit()
            sender.resignFirstResponder()
        }
        
        return false
    }
    
    fileprivate func loadKnownAndInvitedUsers(_ onLoaded: @escaping (_ known: [DBSharedUser], _ invited: [DBSharedUser]) -> Void) {

        var allResult: [DBSharedUser]?
        var invitedResult: [DBSharedUser]?
        func check() {
            if let allResult = allResult, let invitedResult = invitedResult {
                onLoaded(allResult, invitedResult)
            }
        }
        Prov.userProvider.findAllKnownSharedUsers(successHandler {sharedUsers in
            allResult = sharedUsers
            check()
        })
        
        if let inventory = listToEdit {
            Prov.inventoryProvider.findInvitedUsers(inventory.uuid, successHandler {sharedUsers in
                invitedResult = sharedUsers
                check()
            })
        } else {
            invitedResult = []
            check()
        }
    }
    
    // MARK: - FlatColorPickerControllerDelegate
    
    func onColorPicked(_ color: UIColor) {
        dismissColorPicker(color)
    }
    
    func onDismiss() {
        //        dismissColorPicker(nil) // not used see FIXME in FlatColorPickerController.viewDidLoad
    }
    
    fileprivate func dismissColorPicker(_ selectedColor: UIColor?) {
        if let showingColorPicker = showingColorPicker {
            
            UIView.animate(withDuration: 0.3, animations: {
                showingColorPicker.view.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                
                }, completion: {[weak self] finished in
                    self?.showingColorPicker = nil
                    self?.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        if let selectedColor = selectedColor {
                            self?.setBackgroundColor(selectedColor)
                        }
                    }) 
                    UIView.animate(withDuration: 0.15, animations: {
                        self?.colorButton.transform = CGAffineTransform(scaleX: 2, y: 2)
                        UIView.animate(withDuration: 0.15, animations: {
                            self?.colorButton.transform = CGAffineTransform(scaleX: 1, y: 1)
                        }) 
                    }) 
                    
                    self?.listNameInputField.becomeFirstResponder()
                }
            )
        }
    }
    
    // MARK: - SharedUsersControllerDelegate
    
    func onPull(_ user: DBSharedUser) {
        progressVisible(true)
        if let inventory = listToEdit {
            Prov.pullProvider.pullInventoryProducs(inventory.uuid, srcUser: user, successHandler{[weak self] products in  guard let weakSelf = self else {return}
                self?.progressVisible(false)
                MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: trans("popup_please_login_for_participants"), centerYOffset: -80)
            })
        }
    }
    
    func onUsersUpdated(_ exitingUsers: [DBSharedUser], invitedUsers: [DBSharedUser]) {
        self.users = exitingUsers
        self.invitedUsers = invitedUsers
    }
    
    func invitedUsers(_ handler: @escaping ([DBSharedUser]) -> Void) {
        if let inventory = listToEdit {
            Prov.inventoryProvider.findInvitedUsers(inventory.uuid, successHandler {users in
                handler(users)
            })
        } else { // adding inventory - there can't be invited users yet
            handler([])
        }
    }
    
    // MARK: -
    
    // Returns if quick controller can be closed
    func requestClose() -> Bool {
        let showingColorPicker = self.showingColorPicker
        dismissColorPicker(nil)
        return showingColorPicker == nil
    }
    
    deinit {
        logger.v("Deinit add edit inventory controller")
    }
}

