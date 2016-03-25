//
//  QuickAddViewController.swift
//  shoppin
//
//  Created by ischuetz on 22/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

protocol QuickAddDelegate {
    func onAddProduct(product: Product)
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?)
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) // editingItem == nil -> add

//    func onValidationErrors(errors: [UITextField: ValidationError])
//    func planItem(productName: String, handler: PlanItem? -> ())
    
    func onCloseQuickAddTap()
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
    func onQuickListOpen()
    func onAddProductOpen()
    func onAddGroupOpen()
    func onAddGroupItemsOpen()
    
    func parentViewForAddButton() -> UIView
}

private enum AddProductOrGroupContent {
    case Product, Group
}

// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate {
    
    @IBOutlet weak var showGroupsButton: ButtonMore!
    @IBOutlet weak var showProductsButton: ButtonMore!
    @IBOutlet weak var showAddProductsOrGroupButton: ButtonMore!
    @IBOutlet weak var currentQuickAddLabel: UILabel!
    @IBOutlet weak var currentQuickAddLabelLeftConstraint: NSLayoutConstraint!

    @IBOutlet weak var sortByButton: ButtonMore!
    
    var delegate: QuickAddDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    @IBOutlet weak var searchBar: RoundTextField!
    
    private var navController: UINavigationController?
    private var quickAddListItemViewController: QuickAddListItemViewController? {
        return navController?.viewControllers.first as? QuickAddListItemViewController
    }
    
    private var showingController: UIViewController? {
        return navController?.viewControllers.last
    }
    
    private var sortBy: QuickAddItemSortBy = .Fav {
        didSet {
            (navController?.viewControllers.last as? QuickAddListItemViewController)?.contentData = (itemType, sortBy)
            updateSortByButton(sortBy)
        }
    }
    
    private var editingItem: AddEditItem? {
        didSet {
            if let editingItem = editingItem {
                searchBar.text = editingItem.product.name
            } else {
                QL3("Setting a nil editingItem")
            }
        }
    }
    

    var isEdit: Bool {
        return editingItem != nil
    }

    private var addButton: UIButton? = nil
    
    var open: Bool = false
    
    private let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    private var keyboardHeight: CGFloat?
    
    var modus: AddEditListItemControllerModus = .ListItem
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSortByButton(sortBy)

        updateQuickAddTop(.Product)
        
        searchBar.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func onClose() {
        removeAddButton()
    }
    
    func textFieldDidChange(textField: UITextField) {
        if !isEdit {
            if let quickAddListItemViewController = quickAddListItemViewController, searchText = textField.text {
                quickAddListItemViewController.searchText = searchText
            } else {
                QL3("quickAddListItemViewController is not set: \(quickAddListItemViewController), or text is not set: \(textField.text)")
            }
        }
    }
    
    // Show controller either in quick add mode (collection view + possible edit) or edit-only. If this is not called the controller shows without contents.
    func initContent(editingItem: AddEditItem? = nil) {

        if editingItem != nil {
            self.editingItem = editingItem
            showAddProductController()
            
        } else {
            let controller = UIStoryboard.quickAddListItemViewController()
            controller.delegate = self
            navController?.pushViewController(controller, animated: false)
        }
        
        searchBar.becomeFirstResponder()
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "navController" {
            navController = segue.destinationViewController as? UINavigationController
            navController?.view.clipsToBounds = false
        }
    }
    
    // Toggle for showProduct state - if showing product, show product button has to be disabled and group enabled, same for group
    // Assumes only 2 possible states, product and group (Bool)
    // TODO use image, button should not be disabled
    private func toggleItemTypeButtons(showProduct: Bool) {
//        showGroupsButton.enabled = showProduct
//        showProductsButton.enabled = !showProduct
    }
    
    // was used to expand the embedded view controller to fill available space when adding group items. Maybe will be used again in the future.
    //    // MARK: - AddElementViewControllerDelegate
    //
    //    func setContentViewExpanded(expanded: Bool) {
    //        if let originalFrame = originalViewFrame {
    //            delegate?.setContentViewExpanded(expanded, myTopOffset: toolButtonsHeight, originalFrame: originalFrame)
    //        } else {
    //            print("Error: no original frame in QuickAddListItemViewController")
    //        }
    //    }
    
    
    ///////////////////////////////////////////
    // TODO this section is ugly, look for better way + if possible put this logic somewhere else (done in a hurry)
    ///////////////////////////////////////////
    
    // returns: status changed: if it was showing and was subsequently hidden
    private func hideAddProductController() -> Bool {
        if navController?.viewControllers.last as? AddEditListItemViewController != nil {
            navController?.popViewControllerAnimated(false)
            delegate?.onQuickListOpen()
            sortByButton.selected = true
            return true
        }
        return false
    }
    
    // returns: status changed: if it was not showing and was subsequently shown
    private func showAddProductController() -> Bool {
        
        if navController?.viewControllers.last as? AddEditListItemViewController == nil { // don't show if already showing
            let controller = UIStoryboard.addEditListItemViewController()
            controller.modus = modus
            controller.delegate = self
            navController?.pushViewController(controller, animated: false)
            sortByButton.selected = false
            controller.onDidLoad = {[weak self] in // outlets are not initalised at this point yet
                controller.editingItem = self?.editingItem
            }
            delegate?.onAddProductOpen()
            
            
            func addAddButton() {
                if let parentView = delegate?.parentViewForAddButton(), window = view.window {
                    
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
                        
                        if let addEditListItemViewController = weakSelf.showingController as? AddEditListItemViewController {
                            addEditListItemViewController.submit()
                        } else {
                            QL3("Tapped add button but showing controller is not add edit controller")
                        }
                    }
                } else {
                    QL3("No parent view for add button")
                }
            }
            
            if addButton == nil {
                delay(0.5) {
                    addAddButton()
                }
            }
            return true
        }
        return false
    }
    
    private func hideAddProductOrGroupController() -> Bool {
        if (navController?.viewControllers.last as? AddEditListItemViewController != nil) {
            
            navController?.popToRootViewControllerAnimated(false)
            delegate?.onQuickListOpen()
        
            removeAddButton()

//            if (navController?.viewControllers.last as? AddEditListItemViewController != nil) {
//                showGroupsButton.selected = false
//                showProductsButton.selected = true
//            }
            
            return true
        }
        return false
    }
    
    // if it's showing, hides it, otherwise shows it
    private func toggleAddProductController() {
        if !hideAddProductController() { // was not showing
            showAddProductController() // show product (first segment)
        }

    }
    
    @IBAction func onSortByTap(sender: UIButton) {
        let toggled: QuickAddItemSortBy = {
            switch sortBy {
            case .Alphabetic: return .Fav
            case .Fav: return .Alphabetic
            }
        }()
        sortBy = toggled
        
        updateSortByButton(sortBy)
    }
    
    private func updateSortByButton(sortBy: QuickAddItemSortBy) {
        let imgName: String = {
            switch sortBy {
            case .Alphabetic: return "sort_alpha"
            case .Fav:  return "sort_fav"
            }
        }()
        sortByButton.setImage(UIImage(named: imgName), forState: .Normal)
        sortByButton.selected = true
    }
    
    @IBAction func onShowGroupsTap(sender: UIButton) {
        
        func onHasController(controller: QuickAddListItemViewController) {
            controller.contentData = (.Group, .Fav)
            toggleItemTypeButtons(true)
            
            updateQuickAddTop(.Group)
        }
        
        // update current controller or pop to controller and then update
        if let quickAddListItemViewController = navController?.presentedViewController as? QuickAddListItemViewController {
            onHasController(quickAddListItemViewController)
        } else {

            navController?.popToRootViewControllerAnimated(false) // assumption: QuickAddListItemViewController is root
            delegate?.onQuickListOpen()
            
            if let quickAddListItemViewController = quickAddListItemViewController {
                onHasController(quickAddListItemViewController)
            } else {
                print("Error: Unexpected state in QuickAddViewController: Root navigation controller is not QuickAddListItemViewController")
            }
        }
        
        removeAddButton()
    }
    
    private func removeAddButton() {
        addButton?.removeFromSuperview()
        addButton = nil
    }
    
    @IBAction func onShowProductsTap(sender: UIButton) {
        
        func onHasController(controller: QuickAddListItemViewController) {
            controller.contentData = (.Product, .Fav)
            toggleItemTypeButtons(true)

            updateQuickAddTop(.Product)
        }
        
        // update current controller or pop to controller and then update
        if let quickAddListItemViewController = navController?.presentedViewController as? QuickAddListItemViewController {
            onHasController(quickAddListItemViewController)
        } else {
            
            navController?.popToRootViewControllerAnimated(false) // assumption: QuickAddListItemViewController is root
            delegate?.onQuickListOpen()
            
            if let quickAddListItemViewController = quickAddListItemViewController {
                onHasController(quickAddListItemViewController)
            } else {
                print("Error: Unexpected state in QuickAddViewController: Root navigation controller is not QuickAddListItemViewController")
            }
        }
        
        removeAddButton()
    }
    
    @IBAction func onAddProductsOrGroupsTap(sender: UIButton) {
        
        updateQuickAddTop(.AddNew)
        
        toggleAddProductController()
    }

    
    private enum QuickAddTopState {
        case Product, Group, AddNew
    }
    private func updateQuickAddTop(topState: QuickAddTopState) {
        let title: String = {
            switch topState {
                case .Product: return "Products"
                case .Group: return "Groups"
                case .AddNew: return "New item"
            }
        }()
        currentQuickAddLabel.text = title

        showProductsButton.selected = topState == .Product
        showGroupsButton.selected =  topState == .Group
        sortByButton.selected = topState == .Product || topState == .Group

        
        // TODO remove this (with related contraint variable) or modify when final transition is decided
//        currentQuickAddLabelLeftConstraint.constant = 200
//        UIView.animateWithDuration(0.15, animations: {[weak self] in
//            self?.currentQuickAddLabel.alpha = 0
//            self?.view.layoutIfNeeded()
//            
//            }, completion: {[weak self] finished in
//                
//                if topState != .AddNew {
//                    
//                    self?.currentQuickAddLabelLeftConstraint.constant = -150
//                    self?.view.layoutIfNeeded()
//                    self?.currentQuickAddLabelLeftConstraint.constant = 14
//                    if topState == .Product {
//                        self?.currentQuickAddLabel.text = "Items"
//                    } else {
//                        self?.currentQuickAddLabel.text = "Groups"
//                    }
//                    
//                    UIView.animateWithDuration(0.15) {
//                        self?.view.layoutIfNeeded()
//                        self?.currentQuickAddLabel.alpha = 1
//                    }
//                }
//        })
    }
    
    //////////////////////////////////////////
    //////////////////////////////////////////
    
    
    // MARK: - QuickAddListItemDelegate
    
    // group was selected in group quick list
    func onAddGroup(group: ListItemGroup) {
        delegate?.onAddGroup(group, onFinish: nil)
    }
    
    // product was selected in product quick list
    func onAddProduct(product: Product) {
        delegate?.onAddProduct(product)
    }
    
    func onCloseQuickAddTap() {
        delegate?.onCloseQuickAddTap()
    }
    
    func onHasItems(hasItems: Bool) {
        if hasItems {
            hideAddProductController()
        } else {
            showAddProductController()
        }
    }
    
    // MARK: - Actions dispatch
    
    func handleFloatingButtonAction(action: FLoatingButtonAction) {
        if let _ = showingController as? QuickAddListItemViewController {
            print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            
            
        } else if let addEditListItemViewController = showingController as? AddEditListItemViewController {
            switch action {
            case .Submit:
                addEditListItemViewController.submit()
            case .Back:
                navController?.popViewControllerAnimated(false)
                delegate?.onQuickListOpen() // we are now back in quick list
            case .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            }
            
        } else {
            QL3("Not showing any controller")
        }
    }
    
    // MARK: - 
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(price: Float, quantity: Int, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, store: String, editingItem: Any?) {
        
        if let name = searchBar.text {
            
            let listItemInput = ListItemInput(name: name, quantity: quantity, price: price, section: section, sectionColor: sectionColor, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand, store: store)
            delegate?.onSubmitAddEditItem(listItemInput, editingItem: editingItem)
            
        } else {
            // There should be always text as we show add/edit only if user enters text and we find no products for it. If user removes the text, the add/edit controller is hidden.
            // It can be that user taps on submit while we search for products in the databse (which we do before hidding add/edit but this is unlikely as this is a very short time.
            QL3("Tried to submit item but there's no product name (text in the search bar)")
        }
    }

    // Not using plan for now
//    func planItem(productName: String, handler: PlanItem? -> ()) {
//        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
//            handler(planItemMaybe)
//        })
//    }
}
