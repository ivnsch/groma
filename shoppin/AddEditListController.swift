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
import CMPopTipView

import Providers

protocol AddEditListControllerDelegate: class {
    func onAddList(_ list: List)
    func onUpdateList(_ list: List, listInput: ListInput)
}

// TODO try to refactor with AddEditInventoryController, lot of repeated code
class AddEditListController: UIViewController, FlatColorPickerControllerDelegate, SharedUsersControllerDelegate, UITextFieldDelegate, CMPopTipViewDelegate {
    
    @IBOutlet weak var listNameInputField: UITextField!
    
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var sharedUsersButton: UIButton!
    
    @IBOutlet weak var inventoriesLabel: UILabel!
    @IBOutlet weak var inventoriesButton: UIButton!
    
    @IBOutlet weak var storeInputField: UITextField!
    @IBOutlet weak var sharedUsersWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var storeAlignRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var storeSpaceToParticipantsConstraint: NSLayoutConstraint!
    
    fileprivate var inventories: [DBInventory] = [] {
        didSet {
            selectedInventory = listToEdit?.inventory ?? inventories.first
        }
    }
    fileprivate var selectedInventory: DBInventory? {
        didSet {
            let title = selectedInventory?.name ?? ""
            inventoriesButton.setTitle(title, for: UIControl.State())
        }
    }
    fileprivate var inventoriesPopup: CMPopTipView?

    fileprivate var listInputsValidator: Validator?
    
    fileprivate var addButtonHelper: AddButtonHelper?

    fileprivate var currentFirstResponder: UITextField? {
        return [listNameInputField, storeInputField].findFirst { $0.isFirstResponder }
    }

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
                sharedUsersButton.setTitle(title, for: UIControl.State())
            }
        }
    }
    
    fileprivate var invitedUsers: [DBSharedUser] = []

    weak var delegate: AddEditListControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    // NOTE: expected to be called after viewDidLoad (to overwrite e.g. the shared users button visibility)
    var listToEdit: List? {
        didSet {
            if let listToEdit = listToEdit {
                prefill(listToEdit)
                
                // Editing of store for now disabled, see comment under "Edit store note" for reason
                storeInputField.isEnabled = false
                storeInputField.isUserInteractionEnabled = false
                storeInputField.placeholder = nil
            }
        }
    }
    
    var isEdit: Bool {
        return listToEdit != nil
    }
    
    
    fileprivate var colorPopup: MyPopup?
    
    fileprivate func prefill(_ list: List) {
        listNameInputField.text = list.name

        users = list.users.toArray()
        
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

        inventoriesButton.setTitle(list.inventory.name, for: UIControl.State())
        
        storeInputField.text = list.store ?? ""
        setBackgroundColor(list.color)
    }
    
    fileprivate func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(listNameInputField, rules: [NotEmptyTrimmedRule(message: trans("validation_list_name_not_empty"))])
        self.listInputsValidator = listInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInventories()
        
        initValidator()
        
        listNameInputField.setPlaceholderWithColor(trans("placeholder_list_name"), color: UIColor.white)
        storeInputField.setPlaceholderWithColor(trans("placeholder_store"), color: UIColor.white)
        
        setBackgroundColor(UIColor.randomFlat)
        
//        setSharedButtonVisibile(ConnectionProvider.connectedAndLoggedIn)
        setSharedButtonVisibile(false) // for now always false since sharing it's working yet
    }
    
    fileprivate func setBackgroundColor(_ color: UIColor) {
        
        func setContrastingTextColor(_ color: UIColor) {
            guard listNameInputField != nil else {logger.e("Outlets not initialised yet"); return}
            
            let contrastingTextColor = UIColor.white
            
            listNameInputField.setPlaceholderWithColor(trans("placeholder_list_name"), color: contrastingTextColor)
            storeInputField.setPlaceholderWithColor(trans("placeholder_store"), color: contrastingTextColor)
            listNameInputField.textColor = contrastingTextColor
            storeInputField.textColor = contrastingTextColor
            inventoriesLabel.textColor = contrastingTextColor
            colorButton.setTitleColor(contrastingTextColor, for: .normal)
            sharedUsersButton.setTitleColor(contrastingTextColor, for: .normal)
            inventoriesButton.setTitleColor(contrastingTextColor, for: .normal)
        }
        
        view.backgroundColor = color
        setContrastingTextColor(color)
    }
    
    fileprivate func setSharedButtonVisibile(_ visible: Bool) {
        sharedUsersButton.isHidden = !visible
        if sharedUsersButton.isHidden {
            sharedUsersWidthConstraint.constant = 0
        }
        storeAlignRightConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(visible ? 998 : 999))
        storeSpaceToParticipantsConstraint.priority = UILayoutPriority(rawValue: UILayoutPriority.RawValue(visible ? 999 : 998))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        listNameInputField.becomeFirstResponder()
        
        if addButtonHelper == nil {
            addButtonHelper = initAddButtonHelper() // in view did load parentViewController is nil
        }
        addButtonHelper?.addObserver()
        
        initGrowColorAnimator()
    }
    
    fileprivate func initGrowColorAnimator() {
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
    
    // MARK: - Inventories picker

    fileprivate func createPicker(options: [String], selectedOption: String?) -> UIViewController {
        let picker = TooltipPicker()
        picker.view.frame = CGRect(x: 0, y: 0, width: 150, height: 100)
        picker.config(options: options, selectedOption: selectedOption) { [weak self] selectedOption in
            guard let weakSelf = self else { return }
            weakSelf.selectedInventory = weakSelf.inventories.findFirst { $0.name == selectedOption }
        }
        return picker
    }

    fileprivate func loadInventories() {
        Prov.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            self?.inventories = inventories.toArray()
        })
    }
    
    @IBAction func onInventoryTap(_ sender: UIButton) {
        if let popup = inventoriesPopup {
            popup.dismiss(animated: true)
            (view as? AddEditListControllerView)?.popupFrame = nil // restore normal tap area
        } else {
            let options = inventories.map { $0.name }
            let selectedInventory = self.selectedInventory ?? listToEdit?.inventory // if user hasn't selected, select list's inventory
            let picker = createPicker(options: options, selectedOption: selectedInventory?.name)
            let popup = MyTipPopup(customView: picker.view)
            
            popup.delegate = self
            popup.presentPointing(at: inventoriesButton, in: view, animated: true)
            addChild(picker)
            popup.onDismiss = { [weak picker] in
                picker?.removeFromParent()
            }

            if let view = view as? AddEditListControllerView {
                view.popupFrame = popup.frame // include popup in tap area
            } else {
                logger.e("Cast failed, view: \(view)")
            }
        }
    }

    // MARK: - CMPopTipViewDelegate
    
    func popTipViewWasDismissed(byUser popTipView: CMPopTipView!) {
        (view as? AddEditListControllerView)?.popupFrame = nil // restore normal tap area
    }
    
    // MARK: -
    
    func submit() {
        
        // TODO what is this todo, is it still relevant?
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) { [weak self] in
            
            guard let weakSelf = self else {return}
            guard let inventory = weakSelf.selectedInventory else {
                let currentFirstResponder = weakSelf.currentFirstResponder
                view.endEditing(true)
                MyPopupHelper.showPopup(parent: weakSelf.root, type: .info, message: trans("popup_please_select_inventory"), onOkOrCancel: {
                    currentFirstResponder?.becomeFirstResponder()
                })
                return
            }
            guard let bgColor = weakSelf.view.backgroundColor else {logger.e("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.listNameInputField.text?.trim() else {logger.e("Validation was not implemented correctly"); return}
            
            let store: String? = weakSelf.storeInputField.optText?.trim()
            
            
            if let listToEdit = weakSelf.listToEdit {
            
                // Edit store note
                // This was the start of update store functionality but this turns to be complicated, for the user we have to update the referenced store products, which is easy but if the list has participants, we also have to do this also for them, which is not so easy, should we do this immediately or when pulling, how, etc. Doing nothing for the participants is not an option as they'd stay in a list with new store B but the store products have still store A which is an invalid state and leads to inconsistencies - e.g. when they update the price of the store product, it will affect store products in other lists with store A, while they expect it to affect lists with store B as this is the store that the list is showing. Note: we can't just update the store of the products! This would change the store of this products also in other lists - we have to change the reference of the list items to store products.
//                // If oldDifferentStore is nil, it means the store was not updated
//                func afterStoreUpdateCheck(oldDifferentStore: String?) {
//                    
//                    let message: String = {
//                        if store?.isEmpty ?? true {
//                            return "You're removing the store of '\(listName)'. The products used in this list will be replaced with products that don't have a list. This may affect the current prices in this list."
//                        } else {
//                            return "You're assigning a new store to '\(listName)'. The products used in this list will be replaced with products of the new store. This may affect the current prices in this list."
//                        }
//                    }()
//                    
//                    ConfirmationPopup.show(title: "Store update", message: message, okTitle: "Continue", cancelTitle: "Cancel", controller: weakSelf, onOk: {
//                        
//                        let totalUsers = weakSelf.users + weakSelf.invitedUsers
//                        
//                        // Note on shared users: if the shared users controller was not opened this will be nil so listToEdit is not affected (passing nil on copy is a noop)
//                        let updatedList = listToEdit.copy(name: listName, users: totalUsers, bgColor: bgColor, inventory: inventory, store: ListCopyStore(store))
//                        self?.delegate?.onUpdateList(updatedList, oldDifferentStore: oldDifferentStore)
//                        
//                    }, onCancel: nil)
//                }
//                if store != listToEdit.store {
//                    afterStoreUpdateCheck(store)
//                } else {
//                    afterStoreUpdateCheck(nil)
//                }
            
//                let totalUsers = weakSelf.users + weakSelf.invitedUsers // TODO?

                // Note on shared users: if the shared users controller was not opened this will be nil so listToEdit is not affected (passing nil on copy is a noop)
                let listInput = ListInput(name: listName, color: bgColor, store: store ?? "", inventory: inventory)
                self?.delegate?.onUpdateList(listToEdit, listInput: listInput)
            
            } else {
                if let currentListsCount = weakSelf.currentListsCount {
                    
                    // If it's a new list add myself as a participant, to be consistent with list after server updates it (server adds the caller as a participant)
                    
                    let totalUsers = (Prov.userProvider.mySharedUser.map{[$0]} ?? []) + weakSelf.invitedUsers
                    
                    let list = List(uuid: NSUUID().uuidString, name: listName, users: totalUsers, color: bgColor, order: currentListsCount, inventory: inventory, store: store)
                    
                    self?.delegate?.onAddList(list)
                    
                } else {
                    logger.e("No currentListsCount")
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

            let currentFirstResponder = self.currentFirstResponder
            view.endEditing(true)
            ValidationAlertCreator.present(errors, parent: root, firstResponder: currentFirstResponder)

        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    (error.field as? ValidatableTextField)?.showValidationError()
                }
            }

            onValid()
        }
    }

    @IBAction func onColorTap() {
        guard let parent = parent else { logger.e("Parent is not set"); return }

        let topBarHeight: CGFloat = Theme.navBarHeight

        let popup = MyPopup(parent: parent.view, frame: CGRect(x: 0, y: topBarHeight, width: parent.view.bounds.width, height: parent.view.bounds.height - topBarHeight))
        let controller = UIStoryboard.listColorPicker()
        controller.delegate = self
        parent.addChild(controller)

        controller.view.frame = CGRect(x: 0, y: 0, width: parent.view.width, height: parent.view.height)
        popup.contentView = controller.view
        self.colorPopup = popup

        popup.show(from: colorButton, offsetY: -topBarHeight)

        view.endEditing(true)
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
            let currentFirstResponder = self.currentFirstResponder
            view.endEditing(true)
            // TODO more convenient way to do this (pass a callback to ok as well as cancel - onDismiss?)
            MyPopupHelper.showPopup(parent: root, type: .info, message: trans("popup_please_login_for_participants"), onOkOrCancel: {
                currentFirstResponder?.becomeFirstResponder()
            })
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == listNameInputField || sender == storeInputField {
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
        
        if let list = listToEdit {
            Prov.listProvider.findInvitedUsers(list.uuid, successHandler {sharedUsers in
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
        colorPopup?.hide(onFinish: { [weak self] in
            UIView.animate(withDuration: 0.3, animations: {[weak self] in
                if let selectedColor = selectedColor {
                    self?.setBackgroundColor(selectedColor)
                }
            })
            self?.listNameInputField.becomeFirstResponder()
            self?.colorPopup = nil
        })
    }
    
    // MARK: - SharedUsersControllerDelegate
    
    func onPull(_ user: DBSharedUser) {
        parent?.progressVisible(true)
        
        if let list = listToEdit {
            Prov.pullProvider.pullListProducs(list.uuid, srcUser: user, successHandler{[weak self] listItems in  guard let weakSelf = self else {return}
                self?.parent?.progressVisible(false)
                MyPopupHelper.showPopup(parent: weakSelf, type: .info, message: trans("popup_list_products_updated_to_match_user", user.email))
            })
        }
    }
    
    func onUsersUpdated(_ exitingUsers: [DBSharedUser], invitedUsers: [DBSharedUser]) {
        self.users = exitingUsers
        self.invitedUsers = invitedUsers        
    }
    
    func invitedUsers(_ handler: @escaping ([DBSharedUser]) -> Void) {
        if let list = listToEdit {
            Prov.listProvider.findInvitedUsers(list.uuid, successHandler {users in
                handler(users)
            })
        } else { // adding a list - there can't be invited users yet
            handler([])
        }
    }
    
    // MARK: -
    
    // Returns if quick controller can be closed
    func requestClose() -> Bool {
        let isColorPickerOpen = colorPopup != nil
        dismissColorPicker(nil)
        return !isColorPickerOpen // at this point the variable actually means "wasColorPickerOpen"
    }
    
    deinit {
        logger.v("Deinit add edit list controller")
    }
}
