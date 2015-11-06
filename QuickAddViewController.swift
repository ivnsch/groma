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

private typealias AddProductOrGroupSegment = (content: AddProductOrGroupContent, segmentText: String)


// The container for quick add, manages top bar buttons and a navigation controller for content (quick add list, add products, add groups)
class QuickAddViewController: UIViewController, QuickAddListItemDelegate, QuickAddGroupViewControllerDelegate {
    
    @IBOutlet weak var orderAlphabeticallyButton: UIButton!
    @IBOutlet weak var showGroupsButton: UIButton!
    @IBOutlet weak var showProductsButton: UIButton!
    @IBOutlet weak var showAddProductsOrGroupButton: UIButton!

    @IBOutlet weak var addProductOrGroupSegmentedControl: UISegmentedControl!
    @IBOutlet weak var addProductOrGroupSegmentedControlContainer: UIView!
    private var addProductOrGroupSegments: [AddProductOrGroupSegment] = [
        AddProductOrGroupSegment(content: .Product, segmentText: "Product"),
        AddProductOrGroupSegment(content: .Group, segmentText: "Group"),
    ]
    
    @IBOutlet weak var addProductOrGroupSegmentedControlContainerWidthConstraint: NSLayoutConstraint!
    
    var delegate: QuickAddDelegate?
    
    var productDelegate: AddEditListItemControllerDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
    var originalViewFrame: CGRect?
    
    private var navController: UINavigationController?
    private var quickAddListItemViewController: QuickAddListItemViewController? {
        return navController?.viewControllers.first as? QuickAddListItemViewController
    }
    
    var open: Bool = false
    
    private let toolButtonsHeight: CGFloat = 50 // for now hardcoded, since theres no toolbar-view yet (only buttons + constraits constants). TODO

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAddProductOrGroupSegments()
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
    
    @IBAction func onOrderAlphabeticallyTap(sender: UIButton) {
        // TODO
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
    
    //////////////////////////////////////////
    // MARK: - Product or group segment
    //////////////////////////////////////////
    
    // TODO put the add product or group / segment logic in separate entity
    
    private func initAddProductOrGroupSegments() {
        for (index, segment) in addProductOrGroupSegments.enumerate() {
            addProductOrGroupSegmentedControl.setTitle(segment.segmentText, forSegmentAtIndex: index)
        }
    }
    
    @IBAction func onProductOrGroupSegmentChanged(sender: UISegmentedControl) {
        let content = addProductOrGroupSegments[sender.selectedSegmentIndex].content
        switch content {
        case .Product:
            showAddProductController()
        case .Group:
            showAddGroupController()
        }
    }
    
    ///////////////////////////////////////////
    // TODO this section is ugly, look for better way + if possible put this logic somewhere else (done in a hurry)
    ///////////////////////////////////////////
    
    // returns: status changed: if it was showing and was subsequently hidden
    private func hideAddProductController() -> Bool {
        if navController?.viewControllers.last as? AddEditListItemViewController != nil {
            
            navController?.popViewControllerAnimated(true)
            delegate?.onQuickListOpen()
            
            setAddProductOrGroupSegmentedControlExpanded(false)
            return true
        }
        return false
    }
    
    // returns: status changed: if it was not showing and was subsequently shown
    private func showAddProductController() -> Bool {
        
        if !hideAddGroupController() // if group controller is showing, show product means only pop
            && navController?.viewControllers.last as? AddEditListItemViewController == nil { // don't show if already showing
                let controller = UIStoryboard.addEditListItemViewController()
                controller.delegate = productDelegate
                navController?.pushViewController(controller, animated: true)
                setAddProductOrGroupSegmentedControlExpanded(true)
                delegate?.onAddProductOpen()
                return true
        }
        return false
    }
    
    private func hideAddProductOrGroupController() -> Bool {
        if (navController?.viewControllers.last as? AddEditListItemViewController != nil) || (navController?.viewControllers.last as? QuickAddGroupViewController != nil) {
            
            navController?.popToRootViewControllerAnimated(true)
            delegate?.onQuickListOpen()
            
            setAddProductOrGroupSegmentedControlExpanded(false)
            return true
        }
        return false
    }
    
    private func showAddGroupController() -> Bool {
        // the group controller is always shown after product (it's in segment control, which is not visible until product is shown) so show group is always a push
        //        if navController?.viewControllers.last as? AddEditListItemViewController == nil {
        let controller = UIStoryboard.quickAddGroupViewController()
        controller.delegate = self
        navController?.pushViewController(controller, animated: true)
        setAddProductOrGroupSegmentedControlExpanded(true)
        delegate?.onAddGroupOpen()
        //        }
        return false
    }
    
    // returns: status changed: if it was showing and was subsequently hidden
    // FIXME "toRoot", etc. Lot of assumptions in this file
    private func hideAddGroupController(toRoot: Bool = false) -> Bool {
        if navController?.viewControllers.last as? QuickAddGroupViewController != nil {
            if toRoot {
                
                navController?.popToRootViewControllerAnimated(true)
                delegate?.onQuickListOpen()
                
                setAddProductOrGroupSegmentedControlExpanded(false)
            } else {
                navController?.popViewControllerAnimated(true)
                delegate?.onAddProductOpen()
            }
            return true
        }
        return false
    }
    
    // if it's showing, hides it, otherwise shows it
    private func toggleAddProductController() {
        if !hideAddProductController() && !hideAddGroupController(true) { // was not showing any of these (== didn't hide them)
            showAddProductController() // show product (first segment)
        }
    }
    
    private func setAddProductOrGroupSegmentedControlExpanded(expanded: Bool) {
        let expandedConstant: CGFloat = 136
        let collapsedConstant: CGFloat = 10
        
        let constant: CGFloat = expanded ? expandedConstant : collapsedConstant
        
        if addProductOrGroupSegmentedControlContainerWidthConstraint.constant != constant { // FIXME this is cumbersome way to check if view is open currently
            addProductOrGroupSegmentedControlContainerWidthConstraint.constant = constant
            UIView.animateWithDuration(0.3) {[weak self] in
                self?.addProductOrGroupSegmentedControlContainer.alpha = expanded ? 1 : 0
                self?.addProductOrGroupSegmentedControl.alpha = expanded ? 1 : 0
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func onShowGroupsTap(sender: UIButton) {
        
        func onHasController(controller: QuickAddListItemViewController) {
            controller.itemType = .Group
            toggleItemTypeButtons(true)
            setAddProductOrGroupSegmentedControlExpanded(false)
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
            setAddProductOrGroupSegmentedControlExpanded(false)
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
        toggleAddProductController()
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
    
    // MARK: - QuickAddGroupViewControllerDelegate
    
    // group was created in input view
    func onGroupCreated(group: ListItemGroup) {
        delegate?.onAddGroup(group) {[weak self] in
            self?.navController?.popToRootViewControllerAnimated(true)
            self?.delegate?.onQuickListOpen()
        }
    }
    
    func onGroupUpdated(group: ListItemGroup) {
        // do nothing - no group update in quick add (yet?)
        print("Warn: QuickAddViewController.onGroupUpdated called, this should not happen!")
    }
    
    func onGroupItemsOpen() {
        delegate?.onAddGroupItemsOpen()
    }
    
    func onGroupItemsSubmit() {
        delegate?.onAddGroupOpen()
    }
    
    func onEmptyViewTap() {
        if let addEditGroupController = navController?.viewControllers.last as? QuickAddGroupViewController {
            addEditGroupController.showAddItemsController()
            
        } else {
            print("Error: QuickAddViewController.onEmptyViewTap: Invalid state: if tap on empty view current controller should be AddEditListItemViewController (since this view is in this controller)")
        }
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
            
            
        } else if let quickAddGroupViewController = showingController as? QuickAddGroupViewController {
            switch action {
            case .Submit:
                quickAddGroupViewController.submit()
            case .Back:
                navController?.popViewControllerAnimated(true)
                delegate?.onAddProductOpen() // we are now back in product
            case .Add:
                quickAddGroupViewController.showAddItemsController()
            case .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            }
            
            
        } else if let quickAddGroupItemsViewController = showingController as? QuickAddGroupItemsViewController {
            switch action {
            case .Submit:
                quickAddGroupItemsViewController.submit()
            case .Back:
                navController?.popViewControllerAnimated(true)
                delegate?.onAddGroupOpen() // we are now back in group
            case .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(showingController) instance")
            }
        }
        
    }
}
