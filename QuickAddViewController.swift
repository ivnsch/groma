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


protocol QuickAddDelegate: class {
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
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void)
    
    func onRemovedSectionCategoryName(name: String)
    func onRemovedBrand(name: String)
}

private enum AddProductOrGroupContent {
    case Product, Group
}

// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate, QuickAddPageControllerDelegate, UITextFieldDelegate {
    
    weak var delegate: QuickAddDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    @IBOutlet weak var searchBar: RoundTextField!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    private weak var navController: UINavigationController?
    private var quickAddListItemViewController: QuickAddPageController? {
        return navController?.viewControllers.first as? QuickAddPageController
    }
    
    private var showingController: UIViewController? {
        return navController?.viewControllers.last
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

    deinit {
        QL1("Deinit quick add")
    }
    
    var open: Bool = false
    
    private let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    private var keyboardHeight: CGFloat?
    
    var modus: AddEditListItemControllerModus = .ListItem
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.addTarget(self, action: #selector(QuickAddViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        searchBarHeightConstraint.constant = DimensionsManager.searchBarHeight
    }
    
    // MARK: - QuickAddPageControllerDelegate
    
    func onPageChanged(newIndex: Int, pageType: QuickAddItemType) {
        itemType = pageType
        searchBar.text = ""
    }

    // MARK: -
    
    func onClose() {
    }
    
    func textFieldDidChange(textField: UITextField) {
        
        QL1("textFieldDidChange, text: \(textField.text)")
        
        if !isEdit {
            if let controller = quickAddListItemViewController, searchText = textField.text {
                controller.search(searchText)
            } else {
                QL3("Controller: \(quickAddListItemViewController) or search is nil: \(textField.text)")
            }
        } else {
            QL3("Trying to search while isEdit (quick add has an edit item) - doing nothing.")
        }
    }
    
    // Show controller either in quick add mode (collection view + possible edit) or edit-only. If this is not called the controller shows without contents.
    func initContent(editingItem: AddEditItem? = nil) {

        if editingItem != nil {
            self.editingItem = editingItem
            showAddProductController()
            
        } else {
            let controller = UIStoryboard.quickAddPageController()
            controller.delegate = self
            controller.quickAddListItemDelegate = self
            
            // HACK - to show the products with section colors when we are in list items - TODO proper solution
            if itemType == .ProductForList {
                controller.itemTypeForFirstPage = itemType
                controller.list = list
            }
            
            navController?.pushViewController(controller, animated: false)
        }
        
        searchBar.becomeFirstResponder()
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "navController" {
            navController = segue.destinationViewController as? UINavigationController
        } else {
            QL3("Not handled segue")
        }
    }
    
    
    ///////////////////////////////////////////
    // TODO this section is ugly, look for better way + if possible put this logic somewhere else (done in a hurry)
    ///////////////////////////////////////////
    
    // returns: status changed: if it was showing and was subsequently hidden
    private func hideAddProductController() -> Bool {
        if navController?.viewControllers.last as? AddEditListItemViewController != nil {
            navController?.popViewControllerAnimated(false)
            
            // Change back from "Next" to default
            searchBar.returnKeyType = .Default
            // without this the key doesn't change immediately. According to some internet sites this can cause issues with autocorrection, but we don't need it
            searchBar.resignFirstResponder()
            searchBar.becomeFirstResponder()
            
            delegate?.onQuickListOpen()
//            sortByButton.selected = true
            return true
        }
        return false
    }
    
    // returns: status changed: if it was not showing and was subsequently shown
    private func showAddProductController() -> Bool {
        
        // TODO now that we removed all the topbar buttons and added swiper, do we still need this check?
        if navController?.viewControllers.last as? AddEditListItemViewController == nil { // don't show if already showing
            let controller = UIStoryboard.addEditListItemViewController()
            controller.delegate = self
            
            // Something clips the section autocompletion list - after some tests with a dummy view it seems to be the navigation controller - QuickAddViewController does not clip, neither AddEditListItemViewController (for the test added it directly as top menu instead of QuickAddViewController). See also http://stackoverflow.com/questions/18735154/uinavigationcontroller-clips-subviews Couldn't fix (TODO) so for now reducing the number of rows in autocompletion.
            view.clipsToBounds = false
            navController?.view.clipsToBounds = false
//            navController?.view.layer.masksToBounds = false
//            if let vcs = navController?.viewControllers {
//                for vc in vcs {
//                    vc.view.clipsToBounds = false
//                }
//            }
            
            navController?.pushViewController(controller, animated: false)
//            sortByButton.selected = false
            controller.onViewDidLoad = {[weak self, weak controller] in guard let weakSelf = self else {return}
                
            }
            controller.onDidLoad = {[weak self, weak controller] in guard let weakSelf = self else {return}
                controller?.editingItem = weakSelf.editingItem
                controller?.modus = weakSelf.modus
            }
            
            // show "Next" in the keyboard
            searchBar.returnKeyType = .Next
            // without this the key doesn't change immediately. According to some internet sites this can cause issues with autocorrection, but we don't need it
            searchBar.resignFirstResponder()
            searchBar.becomeFirstResponder()
            
            delegate?.onAddProductOpen()
            
            return true
        }
        return false
    }
    
    private enum QuickAddTopState {
        case Product, Group, AddNew
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
            quickAddListItemViewController?.setEmptyViewVisible(false) // this is a no op for .Product as we never show empty view here (we show add products view instead)
            searchBar.text = searchBar.text?.uncapitalizeFirst() // revert posible capitalization done in hasItems == true. A possible manual capitalization of the user would also be reverted but it's very improbable user will capitalize the search input.
        } else {
            switch itemType {
            case .Product:
                fallthrough
            case .ProductForList:
                searchBar.text = searchBar.text?.capitalizeFirst() // on has not items the search text becomes item name input, so we capitalize the first letter.
                showAddProductController()
            case .Group: quickAddListItemViewController?.setEmptyViewVisible(true)
            }
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
    
    // MARK: - AddEditListItemViewControllerDelegate
    
    func runAdditionalSubmitValidations() -> [UITextField: ValidationError]? {
        return (ValidationRule(textField: searchBar, rules: [NotEmptyTrimmedRule(message: "validation_item_name_not_empty")], errorLabel: nil).validateField().map{
            [searchBar: $0]
        })
    }
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(price: Float, quantity: Int, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: StoreProductUnit, brand: String, editingItem: Any?) {
        
        if let name = searchBar.text?.trim() {
            
            let listItemInput = ListItemInput(name: name, quantity: quantity, price: price, section: section, sectionColor: sectionColor, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand)
            delegate?.onSubmitAddEditItem(listItemInput, editingItem: editingItem)
            
        } else {
            // There should be always text as we show add/edit only if user enters text and we find no products for it. If user removes the text, the add/edit controller is hidden.
            // It can be that user taps on submit while we search for products in the databse (which we do before hidding add/edit but this is unlikely as this is a very short time.
            QL3("Tried to submit item but there's no product name (text in the search bar)")
        }
    }

    func parentViewForAddButton() -> UIView? {
        return delegate?.parentViewForAddButton()
    }
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void) {
        delegate?.addEditSectionOrCategoryColor(name, handler: handler)
    }
    
    func onRemovedSectionCategoryName(name: String) {
        delegate?.onRemovedSectionCategoryName(name)
    }
    
    func onRemovedBrand(name: String) {
        delegate?.onRemovedBrand(name)
    }
    
    func endEditing() {
        view.endEditing(true)
    }
    
    // Not using plan for now
//    func planItem(productName: String, handler: PlanItem? -> ()) {
//        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
//            handler(planItemMaybe)
//        })
//    }
    
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        if sender == searchBar {
            if let addEditListItemController = navController?.viewControllers.last as? AddEditListItemViewController {
                addEditListItemController.focusFirstTextField()
            }
        }
        return false
    }
}
