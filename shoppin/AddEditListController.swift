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
import QorumLogs

protocol AddEditListControllerDelegate {
    func onListAdded(list: List)
    func onListUpdated(list: List)
}

// TODO try to refactor with AddEditInventoryController, lot of repeated code
class AddEditListController: UIViewController, FlatColorPickerControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SharedUsersControllerDelegate {
    
    @IBOutlet weak var listNameInputField: UITextField!
    
    @IBOutlet weak var colorButton: UIButton!
    @IBOutlet weak var sharedUsersButton: UIButton!
    @IBOutlet weak var inventoriesButton: UIButton!
    
    @IBOutlet weak var storeInputField: UITextField!
    @IBOutlet weak var sharedUsersWidthConstraint: NSLayoutConstraint!
    
    private var inventories: [Inventory] = [] {
        didSet {
            selectedInventory = inventories.first
        }
    }
    private var selectedInventory: Inventory? {
        didSet {
            let title = selectedInventory?.name ?? ""
            inventoriesButton.setTitle(title, forState: .Normal)
        }
    }
    private var inventoriesPopup: CMPopTipView?

    private var listInputsValidator: Validator?
    
    private var showingColorPicker: FlatColorPickerController?

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

    var delegate: AddEditListControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
    // NOTE: expected to be called after viewDidLoad (to overwrite e.g. the shared users button visibility)
    var listToEdit: List? {
        didSet {
            if let listToEdit = listToEdit {
                prefill(listToEdit)
            }
        }
    }
    
    var isEdit: Bool {
        return listToEdit != nil
    }
    
    private func prefill(list: List) {
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

        storeInputField.text = list.store ?? ""
        view.backgroundColor = list.bgColor
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(listNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])
        listInputsValidator.registerField(storeInputField, rules: [MaxLengthRule(length: 50, message: "validation_store_max")])
        self.listInputsValidator = listInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInventories()
        
        initValidator()
        
        view.backgroundColor = UIColor.flatMagentaColorDark()
        
        listNameInputField.setPlaceholderWithColor("List name", color: UIColor.whiteColor())
        storeInputField.setPlaceholderWithColor("Store (optional)", color: UIColor.whiteColor())
        
        listNameInputField.becomeFirstResponder()
        
        setSharedButtonVisibile(ConnectionProvider.connectedAndLoggedIn)
    }
    
    private func setSharedButtonVisibile(visible: Bool) {
        sharedUsersButton.hidden = !visible
        if sharedUsersButton.hidden {
            sharedUsersWidthConstraint.constant = 0
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    
    // MARK: - Inventories picker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return inventories.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = inventories[row].name
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedInventory = inventories[row]
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    private func loadInventories() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            self?.inventories = inventories
        })
    }
    
    @IBAction func onInventoryTap(sender: UIButton) {
        if let popup = inventoriesPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(inventoriesButton, inView: view, animated: true)
        }
    }

    // MARK: -
    
    func submit() {
        
        // TODO what is this todo, is it still relevant?
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) {[weak self] in
            
            guard let weakSelf = self else {return}
            guard let inventory = weakSelf.selectedInventory else {AlertPopup.show(message: "Please select an inventory", controller: weakSelf); return}
            guard let bgColor = weakSelf.view.backgroundColor else {QL4("Invalid state: view has no bg color"); return}
            guard let listName = weakSelf.listNameInputField.text else {QL4("Validation was not implemented correctly"); return}
            
            let store: String? = weakSelf.storeInputField.optText
            
            if let listToEdit = weakSelf.listToEdit {
                // Note on shared users: if the shared users controller was not opened this will be nil so listToEdit is not affected (passing nil on copy is a noop)
                let updatedList = listToEdit.copy(name: listName, users: weakSelf.users, bgColor: bgColor, inventory: inventory, store: ListCopyStore(store))
                Providers.listProvider.update([updatedList], remote: true, weakSelf.successHandler{
                    weakSelf.delegate?.onListUpdated(updatedList)
                })
            
            } else {
                if let currentListsCount = weakSelf.currentListsCount {
                    let listWithSharedUsers = List(uuid: NSUUID().UUIDString, name: listName, listItems: [], users: weakSelf.users ?? [], bgColor: bgColor, order: currentListsCount, inventory: inventory, store: store)
                    Providers.listProvider.add(listWithSharedUsers, remote: true, weakSelf.successHandler{list in
                        weakSelf.delegate?.onListAdded(list)
                    })
                    
                } else {
                    QL4("No currentListsCount")
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
            AlertPopup.show(message: "Please login to manage participants", controller: self)
        }
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
                
                }, completion: {finished in
                    self.showingColorPicker = nil
                    self.showingColorPicker?.removeFromParentViewControllerWithView()
                    
                    UIView.animateWithDuration(0.3) {
                        if let selectedColor = selectedColor {
                            self.view.backgroundColor = selectedColor
                        }
                    }
                    UIView.animateWithDuration(0.15) {
                        self.colorButton.transform = CGAffineTransformMakeScale(2, 2)
                        UIView.animateWithDuration(0.15) {
                            self.colorButton.transform = CGAffineTransformMakeScale(1, 1)
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - SharedUsersControllerDelegate
    
    func onPull(user: SharedUser) {
        progressVisible(true)
        if let list = listToEdit {
            Providers.pullProvider.pullListProducs(list.uuid, srcUser: user, successHandler{[weak self] listItems in
                self?.progressVisible(false)
            })
        }
    }
    
    func onUsersUpdated(exitingUsers: [SharedUser], invitedUsers: [SharedUser]) {
        self.users = exitingUsers
        self.invitedUsers = invitedUsers        
    }
    
    func invitedUsers(handler: [SharedUser] -> Void) {
        if let list = listToEdit {
            Providers.listProvider.findInvitedUsers(list.uuid, successHandler {users in
                handler(users)
            })
        } else { // adding a list - there can't be invited users yet
            handler([])
        }
    }
}
