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
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate, QuickAddPageControllerDelegate {
    
    var delegate: QuickAddDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    @IBOutlet weak var searchBar: RoundTextField!
    
    private var navController: UINavigationController?
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
        // TODO!!!! check memory, this is never being called though the controller should be allocated when closed. Also, on a short run with instruments noticed memory consumption keeps increasing when we do things in the app but never decreases.
        print("Quick add deinit")
    }
    
    var open: Bool = false
    
    private let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    private var keyboardHeight: CGFloat?
    
    var modus: AddEditListItemControllerModus = .ListItem
    
    private var addButtonHelper: AddButtonHelper?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addButtonHelper?.addObserver()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        addButtonHelper?.removeObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)

        addButtonHelper = initAddButtonHelper()
    }
    
    private func initAddButtonHelper() -> AddButtonHelper? {
        guard let parentViewForAddButton = delegate?.parentViewForAddButton() else {QL4("No delegate: \(delegate)"); return nil}
        let addButtonHelper = AddButtonHelper(parentView: parentViewForAddButton) {[weak self] in guard let weakSelf = self else {return}
            if let addEditListItemViewController = weakSelf.showingController as? AddEditListItemViewController {
                addEditListItemViewController.submit()
            } else {
                QL3("Tapped add button but showing controller is not add edit controller")
            }
        }
        return addButtonHelper
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
            controller.modus = modus
            controller.delegate = self
            navController?.pushViewController(controller, animated: false)
//            sortByButton.selected = false
            controller.onDidLoad = {[weak self] in // outlets are not initalised at this point yet
                controller.editingItem = self?.editingItem
            }
            delegate?.onAddProductOpen()
            
            addButtonHelper?.add()

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
        } else {
            switch itemType {
            case .Product:
                searchBar.text = searchBar.text?.capitalizedString // on has not items the search text becomes item name input, so we capitalize the first letter. Note we don't revert this in hasItems = true, because maybe the user entered a capitalised string. Also nothing bad happens if we let the string capitalised.
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
