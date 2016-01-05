//
//  QuickAddViewController.swift
//  shoppin
//
//  Created by ischuetz on 22/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol QuickAddDelegate {
    func onAddProduct(product: Product)
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?)
    func onCloseQuickAddTap()
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
    
    func onValidationErrors(errors: [UITextField: ValidationError])
    func planItem(productName: String, handler: PlanItem? -> ())
    
    func onQuickListOpen()
    func onAddProductOpen()
    func onAddGroupOpen()
    func onAddGroupItemsOpen()
}

private enum AddProductOrGroupContent {
    case Product, Group
}


// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate {
    
    @IBOutlet weak var showGroupsButton: ButtonMore!
    @IBOutlet weak var showProductsButton: ButtonMore!
    @IBOutlet weak var showAddProductsOrGroupButton: ButtonMore!
    @IBOutlet weak var currentQuickAddLabel: UILabel!
    @IBOutlet weak var currentQuickAddLabelLeftConstraint: NSLayoutConstraint!
    
    var addProductsOrGroupBgColor: UIColor?
    
    var delegate: QuickAddDelegate?
    
    var productDelegate: AddEditListItemViewControllerDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    private var navController: UINavigationController?
    private var quickAddListItemViewController: QuickAddListItemViewController? {
        return navController?.viewControllers.first as? QuickAddListItemViewController
    }
    
    var open: Bool = false
    
    private let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    var modus: AddEditListItemControllerModus = .ListItem
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showAddProductsOrGroupButton.backgroundColor = addProductsOrGroupBgColor
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "navController" {
            navController = segue.destinationViewController as? UINavigationController
            if let quickAddListItemViewController = quickAddListItemViewController {
                quickAddListItemViewController.delegate = self
                
            }
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
            
            navController?.popViewControllerAnimated(true)
            delegate?.onQuickListOpen()
            
            return true
        }
        return false
    }
    
    // returns: status changed: if it was not showing and was subsequently shown
    private func showAddProductController() -> Bool {
        
        if navController?.viewControllers.last as? AddEditListItemViewController == nil { // don't show if already showing
            let controller = UIStoryboard.addEditListItemViewController()
            controller.view.backgroundColor = addProductsOrGroupBgColor
            controller.modus = modus
            controller.delegate = productDelegate
            navController?.pushViewController(controller, animated: true)
            delegate?.onAddProductOpen()
            return true
        }
        return false
    }
    
    private func hideAddProductOrGroupController() -> Bool {
        if (navController?.viewControllers.last as? AddEditListItemViewController != nil) {
            
            navController?.popToRootViewControllerAnimated(true)
            delegate?.onQuickListOpen()
        
            if (navController?.viewControllers.last as? AddEditListItemViewController != nil) {
                showGroupsButton.selected = false
                showProductsButton.selected = true
            }
            
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
    
    @IBAction func onShowGroupsTap(sender: UIButton) {
        
        func onHasController(controller: QuickAddListItemViewController) {
            controller.itemType = .Group
            toggleItemTypeButtons(true)
            
            showGroupsButton.selected = true
            showProductsButton.selected = false
            updateQuickAddTop(.Group)
        }
        
        // update current controller or pop to controller and then update
        if let quickAddListItemViewController = navController?.presentedViewController as? QuickAddListItemViewController {
            onHasController(quickAddListItemViewController)
        } else {

            navController?.popToRootViewControllerAnimated(true) // assumption: QuickAddListItemViewController is root
            delegate?.onQuickListOpen()
            
            if let quickAddListItemViewController = quickAddListItemViewController {
                onHasController(quickAddListItemViewController)
            } else {
                print("Error: Unexpected state in QuickAddViewController: Root navigation controller is not QuickAddListItemViewController")
            }
        }
    }
    
    @IBAction func onShowProductsTap(sender: UIButton) {
        
        func onHasController(controller: QuickAddListItemViewController) {
            controller.itemType = .Product
            toggleItemTypeButtons(true)
            
            showProductsButton.selected = true
            showGroupsButton.selected = false
            updateQuickAddTop(.Product)
        }
        
        // update current controller or pop to controller and then update
        if let quickAddListItemViewController = navController?.presentedViewController as? QuickAddListItemViewController {
            onHasController(quickAddListItemViewController)
        } else {
            
            navController?.popToRootViewControllerAnimated(true) // assumption: QuickAddListItemViewController is root
            delegate?.onQuickListOpen()
            
            if let quickAddListItemViewController = quickAddListItemViewController {
                onHasController(quickAddListItemViewController)
            } else {
                print("Error: Unexpected state in QuickAddViewController: Root navigation controller is not QuickAddListItemViewController")
            }
        }
    }
    
    @IBAction func onAddProductsOrGroupsTap(sender: UIButton) {
        
        showProductsButton.selected = false
        showGroupsButton.selected = false
        updateQuickAddTop(.AddNew)
        
        toggleAddProductController()
    }

    
    private enum QuickAddTopState {
        case Product, Group, AddNew
    }
    private func updateQuickAddTop(topState: QuickAddTopState) {
        currentQuickAddLabelLeftConstraint.constant = 200
        UIView.animateWithDuration(0.15, animations: {[weak self] in
            self?.currentQuickAddLabel.alpha = 0
            self?.view.layoutIfNeeded()
            
        }, completion: {[weak self] finished in
            
            if topState != .AddNew {
                
                self?.currentQuickAddLabelLeftConstraint.constant = -150
                self?.view.layoutIfNeeded()
                self?.currentQuickAddLabelLeftConstraint.constant = 14
                if topState == .Product {
                    self?.currentQuickAddLabel.text = "Items"
                } else {
                    self?.currentQuickAddLabel.text = "Groups"
                }
                
                UIView.animateWithDuration(0.15) {
                    self?.view.layoutIfNeeded()
                    self?.currentQuickAddLabel.alpha = 1
                }
            }
        })
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
    
    
    // MARK: - Actions dispatch
    
    func handleFloatingButtonAction(action: FLoatingButtonAction) {
        let showingController = navController?.viewControllers.last
        
        if let _ = showingController as? QuickAddListItemViewController {
            print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            
            
        } else if let addEditListItemViewController = showingController as? AddEditListItemViewController {
            switch action {
            case .Submit:
                addEditListItemViewController.submit(AddEditListItemViewControllerAction.Add)
            case .Back:
                navController?.popViewControllerAnimated(true)
                delegate?.onQuickListOpen() // we are now back in quick list
            case .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            }
        }
    }
}
