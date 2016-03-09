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


class AddEditListController: UIViewController, UITableViewDataSource, UITableViewDelegate, FlatColorPickerControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, SharedUserCellDelegate {
    
    @IBOutlet weak var listNameInputField: UITextField!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var addUserInputField: UITextField!
    @IBOutlet weak var offlineOverlayButton: UIButton!
    
    @IBOutlet weak var colorButton: UIButton!

    @IBOutlet weak var inventoriesButton: UIButton!
    
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
    private var userInputsValidator: Validator?
    
    var delegate: AddEditListControllerDelegate?
    
    var open: Bool = false
    
    var currentListsCount: Int? // to determine order. For now we set this field at view controller level, don't do an extra fetch in provider. Maybe it's better like this.
    
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
    
    private var userCellModels: [SharedUserCellModel] = [] {
        didSet {
            usersTableView.reloadData()
            self.adjustUsersTableViewHeightForContent()
        }
    }
    
    private var showingColorPicker: FlatColorPickerController?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        usersTableView.setEditing(true, animated: false)
        
        if !listToEdit.isSet { // add modus
            colorButton.tintColor = RandomFlatColorWithShade(.Dark)
        }
    }
    
    private func prefill(list: List) {
        listNameInputField.text = list.name
        userCellModels = list.users.map{SharedUserCellModel(user: $0, acceptedInvitation: true)} // for now we assume that users passed in edit mode have accepted the invitation. TODO!!!! check: do the shared users for editing list come from the server? Or do we store them independently of server. In latest case we have to improve logic here. We must not show "pull products" for users that have not accepted the invitation. Either we don't show the users that haven't accepted at all or we show them with a "pending" status (without "pull products" button). Latest requires some work, if we show this we also should allow e.g. to remove the pending invitation, in which case we need a new service in the server also.
        colorButton.tintColor = list.bgColor
        colorButton.imageView?.tintColor = list.bgColor
    }
    
    private func initValidator() {
        let listInputsValidator = Validator()
        listInputsValidator.registerField(self.listNameInputField, rules: [MinLengthRule(length: 1, message: "validation_list_name_not_empty")])
        
        let userInputsValidator = Validator()
        userInputsValidator.registerField(self.addUserInputField, rules: [MinLengthRule(length: 1, message: "validation_user_input_not_empty")])
        
        self.listInputsValidator = listInputsValidator
        self.userInputsValidator = userInputsValidator
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadInventories()
        
        initValidator()
        
        listNameInputField.becomeFirstResponder()
        
        let connectedAndLoggedIn = ConnectionProvider.connectedAndLoggedIn
        offlineOverlayButton.userInteractionEnabled = !connectedAndLoggedIn
        offlineOverlayButton.hidden = connectedAndLoggedIn
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
    
    @IBAction func onDoneTap(sender: UIBarButtonItem) {
        submit()
    }
    
    func submit() {
        
        // This is a workaround because right now the server requires us to send only emails of users in order to do the update
        // This is like this because the update was implemented as if we are editing the shared users the first time
        // But now we have an additional service where we do this beforehand
        // TODO clean solution?
        
        validateInputs(self.listInputsValidator) {[weak self] in
            
            if let weakSelf = self {
                
                if let inventory = weakSelf.selectedInventory {
                
                    if let listName = weakSelf.listNameInputField.text {
                        if let listToEdit = weakSelf.listToEdit {
                            let updatedList = listToEdit.copy(name: listName, users: weakSelf.userCellModels.map{$0.user}, bgColor: weakSelf.colorButton.tintColor, inventory: inventory)
                            Providers.listProvider.update([updatedList], remote: true, weakSelf.successHandler{
                                weakSelf.delegate?.onListUpdated(updatedList)
                            })
                        
                        } else {
                            if let currentListsCount = weakSelf.currentListsCount {
                                let listWithSharedUsers = List(uuid: NSUUID().UUIDString, name: listName, listItems: [], users: weakSelf.userCellModels.map{$0.user}, bgColor: weakSelf.colorButton.tintColor, order: currentListsCount, inventory: inventory)
                                Providers.listProvider.add(listWithSharedUsers, remote: true, weakSelf.successHandler{list in
                                    weakSelf.delegate?.onListAdded(list)
                                })
                                
                            } else {
                                print("Error: no currentListsCount")
                            }
                        }
                    } else {
                        print("Error: validation was not implemented correctly")
                    }
                    
                } else {
                    AlertPopup.show(message: "Please select an inventory", controller: weakSelf)
                    print("Error: selectedInventory is nil - validation was not implemented correctly")
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
    
    @IBAction func onCloseTap(sender: UIBarButtonItem) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onAddUserTap(sender: UIButton) {
        if !ConnectionProvider.connectedAndLoggedIn {
            AlertPopup.show(message: "You must be logged in to share your list", controller: self)
            
        } else {
            self.validateInputs(userInputsValidator) {[weak self] in
                
                if let weakSelf = self {
                    if let input = weakSelf.addUserInputField.text {
//                        SharedUserChecker.check(input, users: weakSelf.sharedUsers.map{$0.user}, controller: weakSelf, onSuccess: {
                            weakSelf.addUserUI(SharedUser(email: input))
//                        })
                    } else {
                        print("Error: validation was not implemented correctly")
                    }
                }
            }
        }
    }

    
    private func addUserUI(user: SharedUser) {
        userCellModels.append(SharedUserCellModel(user: user))
        addUserInputField.clear()
        adjustUsersTableViewHeightForContent()
    }
    
    private func adjustUsersTableViewHeightForContent() {
        let viewWithoutTableViewHeight: CGFloat = 120
        let tableViewCellHeight: CGFloat = 44
        let viewMaxHeight: CGFloat = 260
        let height = min(viewMaxHeight, viewWithoutTableViewHeight + (CGFloat(userCellModels.count) * tableViewCellHeight)) // tableview height as content, but not higher than max
        animateHeigth(height)
    }
    
    private func animateHeigth(height: CGFloat) {
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.view.frame = self!.view.frame.copy(height: height)
            self?.view.layoutIfNeeded()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCellModels.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath) as! ListSharedUserCell
        let cellModel = userCellModels[indexPath.row]
        cell.cellModel = cellModel
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            self.usersTableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    weakSelf.userCellModels.removeAtIndex(indexPath.row)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
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
    
    func clear() {
        listNameInputField.clear()
        addUserInputField.clear()
        userCellModels = []
        listToEdit = nil
        
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
                            self.colorButton.tintColor = selectedColor
                            self.colorButton.imageView?.tintColor = selectedColor
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
    
    // MARK: - SharedUserCellDelegate
    
    func onPullProductsTap(user: SharedUser, cell: ListSharedUserCell) {
        progressVisible(true)
        if let list = listToEdit {
            Providers.pullProvider.pullListProducs(list.uuid, srcUser: user, successHandler{[weak self] listItems in
                self?.progressVisible(false)
            })
        }
    }
}
