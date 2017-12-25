//
//  QuickAddViewController.swift
//  shoppin
//
//  Created by ischuetz on 22/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import Providers

protocol QuickAddDelegate: class {
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void)
    
    func onAddItem(_ item: Item) // Maybe remove this - now that we have onAddIngredient it's not necessarily. We currently don't add only items anywhere.
    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs) // only used with item type .ingredient

    func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) // TODO!!!!!!!!!!!!!! remove (from origin)
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController)
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) // editingItem == nil -> add
    
    // Adds the "basic part" of the new item corresponding to the objects used in quick add. E.g. in case of list item, this is a quantifiable product. This is used for the first step of add new item process, in which we show first the new item in quick add (at this point we only added the "basic part" before animating it to the table view (where we add the actual item).
    func onSubmitAddEditItem2(_ input: ListItemInput, editingItem: Any?, onFinish: ((QuickAddItem, Bool) -> Void)?)
    
//    func onValidationErrors(errors: [UITextField: ValidationError])
//    func planItem(productName: String, handler: PlanItem? -> ())
    
    func onCloseQuickAddTap()
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
    func onQuickListOpen()
    func onAddProductOpen()
    func onAddGroupOpen()
    func onAddGroupItemsOpen()
    
    func parentViewForAddButton() -> UIView
    func onAddedIngredientsSubviews()
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void)
    
    func onRemovedSectionCategoryName(_ name: String)
    func onRemovedBrand(_ name: String)
    
    func onFinishAddCellAnimation(addedItem: AnyObject)
    var offsetForAddCellAnimation: CGFloat {get}
}

extension QuickAddDelegate {
    
    var offsetForAddCellAnimation: CGFloat {
        return 0
    }

    func onAddedIngredientsSubviews() {
    }
}


private enum AddProductOrGroupContent {
    case product, group, recipe
}

// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate, QuickAddPageControllerDelegate, UITextFieldDelegate {
    
    weak var delegate: QuickAddDelegate?
    weak var addIngredientDelegate: QuickAddDelegate? // Used only when items type == .ingredient
    
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
                searchBar.text = editingItem.product?.product.item.name ?? ""
            } else {
                logger.w("Setting a nil editingItem")
            }
        }
    }
    

    var isEdit: Bool {
        return editingItem != nil
    }

    deinit {
        logger.v("Deinit quick add")
    }
    
    var open: Bool = false
    
    fileprivate let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    fileprivate var keyboardHeight: CGFloat?
    
    var modus: AddEditListItemControllerModus = .listItem
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?

    // For now only recipes controller sets this (it's needed for the add ingredient scroller)
    var topConstraint: NSLayoutConstraint? {
        didSet {
            quickAddListItemViewController?.topConstraint = topConstraint
        }
    }

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
    
    func hideKeyboard() {
        view.endEditing(true)
        searchBar.resignFirstResponder()
    }
    
    func restoreKeyboard() {
        searchBar.becomeFirstResponder()
    }

    // MARK: -
    
    func onClose() {
        _ = quickAddListItemViewController?.closeChildControllers()
    }
    
    // Returns if quick add controller can be closed
    func requestClose() -> Bool {
        
        let anyQuickAddListItemChildShowing = quickAddListItemViewController?.closeChildControllers() ?? false
        let addEdtListItemChildShowing = (showingController as? AddEditListItemViewController)?.closeChildControllers() ?? false
        
        return !(anyQuickAddListItemChildShowing || addEdtListItemChildShowing)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        logger.v("textFieldDidChange, text: \(String(describing: textField.text))")
        
        if !isEdit {
            if let controller = quickAddListItemViewController, let searchText = textField.text {
                controller.search(searchText)
            } else {
                logger.w("Controller: \(String(describing: quickAddListItemViewController)) or search is nil: \(String(describing: textField.text))")
            }
        } else {
            logger.w("Trying to search while isEdit (quick add has an edit item) - doing nothing.")
        }
    }
    
    // Show controller either in quick add mode (collection view + possible edit) or edit-only. If this is not called the controller shows without contents.
    func initContent(_ editingItem: AddEditItem? = nil) {

        if editingItem != nil {
            self.editingItem = editingItem
            _ = showAddProductController()
            
        } else {
            let controller = UIStoryboard.quickAddPageController()
            controller.pageCount = itemType == .ingredients ? 1 : 2 // See note in pageCount
            controller.delegate = self
            controller.quickAddListItemDelegate = self
            
            // HACK - to show the products with section colors when we are in list items - TODO proper solution
            if itemType == .productForList {
                controller.itemTypeForFirstPage = itemType
                controller.list = list
            } else if itemType == .ingredients {
                controller.itemTypeForFirstPage = itemType
            }
            
            navController?.pushViewController(controller, animated: false)
        }
        
        searchBar.becomeFirstResponder()
    }

    func showTapToAddMoreHintIfEnabled() {
        
        func showHint() {
            let height: CGFloat = 40
            let label = UILabel(frame: CGRect(x: 0, y: view.bounds.maxY - height, width: view.width, height: height))
            label.backgroundColor = Theme.lightGreyBackground
            label.textColor = Theme.grey
            label.text = trans("hint_tap_to_add_more")
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: LabelMore.mapToFontSize(40) ?? 12)
            view.addSubview(label)
            label.alpha = 0
            
            anim {
                label.alpha = 1
            }
            delay(2) {
                anim(Theme.defaultAnimDuration, {
                    label.alpha = 0
                }) {
                    label.removeFromSuperview()
                }
            }
        }
        
        let showedTapToEditCounterNumber: NSNumber = PreferencesManager.loadPreference(.showedTapToEditCounter) ?? 0
        let showedTapToEditCount = showedTapToEditCounterNumber.intValue
        
        if showedTapToEditCount < 2 {
            showHint()
            PreferencesManager.savePreference(.showedTapToEditCounter, value: NSNumber(value: showedTapToEditCount + 1))
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "navController" {
            navController = segue.destination as? UINavigationController
        } else {
            logger.w("Not handled segue")
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
            
            controller.keyboardHeight = self.keyboardHeight
            
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
    func onAddGroup(_ group: ProductGroup) {
        delegate?.onAddGroup(group, onFinish: nil)
    }
    
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickListController: QuickAddListItemViewController) {
        delegate?.onAddRecipe(ingredientModels: ingredientModels, quickAddController: self)
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        delegate?.getAlreadyHaveText(ingredient: ingredient, handler)
    }
    
    // product was selected in product quick list
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        delegate?.onAddProduct(product, quantity: quantity, onAddToProvider: {[weak self] result in
            if result.isNewItem {
                self?.showTapToAddMoreHintIfEnabled()
            }
            onAddToProvider(result)
        })
    }
    
    func onAddItem(_ item: Item) {
        delegate?.onAddItem(item)
    }
    
    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs) {
        delegate?.onAddIngredient(item: item, ingredientInput: ingredientInput)
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
            case .product: fallthrough
            case .ingredients: fallthrough
            case .productForList:
                searchBar.text = searchBar.text?.capitalizeFirst() // on has not items the search text becomes item name input, so we capitalize the first letter.
                _ = showAddProductController()
            case .group: fallthrough
            case .recipe: quickAddListItemViewController?.setEmptyViewVisible(true)
            
            }
        }
    }

    func onAddedIngredientsSubviews() {
        delegate?.onAddedIngredientsSubviews()
    }
    
    func onFinishAddCellAnimation(addedItem: AnyObject) {
        delegate?.onFinishAddCellAnimation(addedItem: addedItem)
    }
    
    var offsetForAddCellAnimation: CGFloat {
        return delegate?.offsetForAddCellAnimation ?? 0
    }
    
    // MARK: - Actions dispatch
    
    func handleFloatingButtonAction(_ action: FLoatingButtonAction) {
        if let _ = showingController as? QuickAddListItemViewController {
            print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(String(describing: showingController)) instance")
            
            
        } else if let addEditListItemViewController = showingController as? AddEditListItemViewController {
            switch action {
            case .submit:
                addEditListItemViewController.submit()
            case .back:
                _ = navController?.popViewController(animated: false)
                delegate?.onQuickListOpen() // we are now back in quick list
            case .add, .toggle, .expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(String(describing: showingController)) instance")
            }
            
        } else {
            logger.w("Not showing any controller")
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
    
    func onOkTap(_ price: Float, quantity: Float, section: String, sectionColor: UIColor, note: String?, baseQuantity: Float, unit: String, brand: String, edible: Bool, editingItem: Any?) {
        
        if let name = searchBar.text?.trim() {
            
            let listItemInput = ListItemInput(name: name, quantity: quantity, price: price, section: section, sectionColor: sectionColor, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand, edible: edible)

            delegate?.onSubmitAddEditItem2(listItemInput, editingItem: editingItem) {[weak self] quickAddItem, isNew in
                
                if editingItem == nil { // add - item was not in the db yet
                    _ = self?.hideAddProductController() // go back to quick add items
                    self?.quickAddListItemViewController?.addProductController?.showAddedItem(quickAddItem: quickAddItem, quantity: quantity)
                    
                } else {
                    // Update - we don't go back to quick list here but display "old" way to update i.e. simply update item in table view and scroll to row, without any additional animation.
                    // Note that update can happen in 2 cases: 1. Explicit update (user edits an item) - in this case we probably even close the top controller after it, or let it there, or clear it but it doesn't make sense to go back to quick add. 2. When user is in "add" context - i.e. fills the form for a new item with data of an already existing item. In this case, it could make sense to go back to the quick add and highlight (i.e. shortly scale) the item in the collection view and perform add to cell animation if it's not in the table view yet, but we're going to skip this for now and simply treat it as an explicit update. Besides, 2. can't actually happen at the time of writing this, as the form is opened only if the name of the item doesn't exist yet (as product or item, depending in which controller we are), and if we change the name to something existent, the form will be closed automatically. But this behaviour needs to be reevaluated because of some other issues, so this may change.
                    self?.delegate?.onSubmitAddEditItem(listItemInput, editingItem: editingItem)
                }
            }
            
        } else {
            // There should be always text as we show add/edit only if user enters text and we find no products for it. If user removes the text, the add/edit controller is hidden.
            // It can be that user taps on submit while we search for products in the databse (which we do before hidding add/edit but this is unlikely as this is a very short time.
            logger.w("Tried to submit item but there's no product name (text in the search bar)")
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
//        Prov.planProvider.planItem(productName, successHandler {planItemMaybe in
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
    
    /// Return true to consume the event (i.e. prevent closing of this controller)
    func onTapNavBarCloseTap() -> Bool {
        return quickAddListItemViewController?.onTapNavBarCloseTap() ?? false
    }
    
    func closeRecipeController() {
        quickAddListItemViewController?.addGroupController?.closeRecipeController()
    }
    
    // MARK: - Keyboard
    // We need to remember the keyboard height here, in order to pass it to AddEditListItemViewController such that the submit view can be animated to the correct position
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObserver()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        quickAddListItemViewController?.topConstraint = topConstraint
        quickAddListItemViewController?.topController = self
        quickAddListItemViewController?.topParentController = self.parent
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObserver()
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(AddButtonHelper.keyboardWillChangeFrame(_:)),
                                               name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillChangeFrame(_ notification: Foundation.Notification) {
        if let userInfo = (notification as NSNotification).userInfo {
            if let frame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                //                logger.v("keyboardWillChangeFrame, frame: \(frame)")
                keyboardHeight = frame.height
            } else {
                logger.w("Couldn't retrieve keyboard size from user info")
            }
        } else {
            logger.w("Notification has no user info")
        }
    }
}
