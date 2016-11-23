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
    func onAddProduct(_ product: Product)
    func onAddGroup(_ group: ListItemGroup, onFinish: VoidFunction?)
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) // editingItem == nil -> add

//    func onValidationErrors(errors: [UITextField: ValidationError])
//    func planItem(productName: String, handler: PlanItem? -> ())
    
    func onCloseQuickAddTap()
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
    func onQuickListOpen()
    func onAddProductOpen()
    func onAddGroupOpen()
    func onAddGroupItemsOpen()
    
    func parentViewForAddButton() -> UIView
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void)
    
    func onRemovedSectionCategoryName(_ name: String)
    func onRemovedBrand(_ name: String)
}

private enum AddProductOrGroupContent {
    case product, group
}

// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate, QuickAddPageControllerDelegate, UITextFieldDelegate {
    
    weak var delegate: QuickAddDelegate?
    
    var itemType: QuickAddItemType = .product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    @IBOutlet weak var searchBar: RoundTextField!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    fileprivate weak var navController: UINavigationController?
    fileprivate var quickAddListItemViewController: QuickAddPageController? {
        return navController?.viewControllers.first as? QuickAddPageController
    }
    
    fileprivate var showingController: UIViewController? {
        return navController?.viewControllers.last
    }
    
    fileprivate var editingItem: AddEditItem? {
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
    
    fileprivate let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    fileprivate var keyboardHeight: CGFloat?
    
    var modus: AddEditListItemControllerModus = .listItem
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.addTarget(self, action: #selector(QuickAddViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        searchBarHeightConstraint.constant = DimensionsManager.searchBarHeight
    }
    
    // MARK: - QuickAddPageControllerDelegate
    
    func onPageChanged(_ newIndex: Int, pageType: QuickAddItemType) {
        itemType = pageType
        searchBar.text = ""
    }

    // MARK: -
    
    func onClose() {
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        
        QL1("textFieldDidChange, text: \(textField.text)")
        
        if !isEdit {
            if let controller = quickAddListItemViewController, let searchText = textField.text {
                controller.search(searchText)
            } else {
                QL3("Controller: \(quickAddListItemViewController) or search is nil: \(textField.text)")
            }
        } else {
            QL3("Trying to search while isEdit (quick add has an edit item) - doing nothing.")
        }
    }
    
    // Show controller either in quick add mode (collection view + possible edit) or edit-only. If this is not called the controller shows without contents.
    func initContent(_ editingItem: AddEditItem? = nil) {

        if editingItem != nil {
            self.editingItem = editingItem
            _ = showAddProductController()
            
        } else {
            let controller = UIStoryboard.quickAddPageController()
            controller.delegate = self
            controller.quickAddListItemDelegate = self
            
            // HACK - to show the products with section colors when we are in list items - TODO proper solution
            if itemType == .productForList {
                controller.itemTypeForFirstPage = itemType
                controller.list = list
            }
            
            navController?.pushViewController(controller, animated: false)
        }
        
        searchBar.becomeFirstResponder()
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "navController" {
            navController = segue.destination as? UINavigationController
        } else {
            QL3("Not handled segue")
        }
    }
    
    
    ///////////////////////////////////////////
    // TODO this section is ugly, look for better way + if possible put this logic somewhere else (done in a hurry)
    ///////////////////////////////////////////
    
    // returns: status changed: if it was showing and was subsequently hidden
    fileprivate func hideAddProductController() -> Bool {
        if navController?.viewControllers.last as? AddEditListItemViewController != nil {
            _ = navController?.popViewController(animated: false)
            
            // Change back from "Next" to default
            searchBar.returnKeyType = .default
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
    fileprivate func showAddProductController() -> Bool {
        
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
                controller?.modus = weakSelf.modus // has to be set before initialising validator
            }
            controller.onDidLoad = {[weak self, weak controller] in guard let weakSelf = self else {return}
                controller?.editingItem = weakSelf.editingItem
            }
            
            // show "Next" in the keyboard
            searchBar.returnKeyType = .next
            // without this the key doesn't change immediately. According to some internet sites this can cause issues with autocorrection, but we don't need it
            searchBar.resignFirstResponder()
            searchBar.becomeFirstResponder()
            
            delegate?.onAddProductOpen()
            
            return true
        }
        return false
    }
    
    fileprivate enum QuickAddTopState {
        case product, group, addNew
    }

    //////////////////////////////////////////
    //////////////////////////////////////////
    
    
    // MARK: - QuickAddListItemDelegate
    
    // group was selected in group quick list
    func onAddGroup(_ group: ListItemGroup) {
        delegate?.onAddGroup(group, onFinish: nil)
    }
    
    // product was selected in product quick list
    func onAddProduct(_ product: Product) {
        delegate?.onAddProduct(product)
    }
    
    func onCloseQuickAddTap() {
        delegate?.onCloseQuickAddTap()
    }
    
    func onHasItems(_ hasItems: Bool) {
        if hasItems {
            _ = hideAddProductController()
            quickAddListItemViewController?.setEmptyViewVisible(false) // this is a no op for .Product as we never show empty view here (we show add products view instead)
            searchBar.text = searchBar.text?.uncapitalizeFirst() // revert posible capitalization done in hasItems == true. A possible manual capitalization of the user would also be reverted but it's very improbable user will capitalize the search input.
        } else {
            switch itemType {
            case .product:
                fallthrough
            case .productForList:
                searchBar.text = searchBar.text?.capitalizeFirst() // on has not items the search text becomes item name input, so we capitalize the first letter.
                _ = showAddProductController()
            case .group: quickAddListItemViewController?.setEmptyViewVisible(true)
            }
        }
    }
    
    // MARK: - Actions dispatch
    
    func handleFloatingButtonAction(_ action: FLoatingButtonAction) {
        if let _ = showingController as? QuickAddListItemViewController {
            print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            
            
        } else if let addEditListItemViewController = showingController as? AddEditListItemViewController {
            switch action {
            case .submit:
                addEditListItemViewController.submit()
            case .back:
                _ = navController?.popViewController(animated: false)
                delegate?.onQuickListOpen() // we are now back in quick list
            case .add, .toggle, .expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            }
            
        } else {
            QL3("Not showing any controller")
        }
    }
    
    // MARK: - AddEditListItemViewControllerDelegate
    
    func runAdditionalSubmitValidations() -> ValidatorDictionary<ValidationError>? {
        return (ValidationRule(field: searchBar, rules: [NotEmptyTrimmedRule(message: "validation_item_name_not_empty")], errorLabel: nil).validateField().map{
            var dict = ValidatorDictionary<ValidationError>()
            dict[searchBar] = $0
            return dict
//            [searchBar: $0]
        })
    }
    
    func onValidationErrors(_ errors: ValidatorDictionary<ValidationError>) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(_ price: Float, quantity: Int, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: StoreProductUnit, brand: String, editingItem: Any?) {
        
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
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        delegate?.addEditSectionOrCategoryColor(name, handler: handler)
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
        delegate?.onRemovedSectionCategoryName(name)
    }
    
    func onRemovedBrand(_ name: String) {
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
    
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        if sender == searchBar {
            if let addEditListItemController = navController?.viewControllers.last as? AddEditListItemViewController {
                addEditListItemController.focusFirstTextField()
            }
        }
        return false
    }
}
