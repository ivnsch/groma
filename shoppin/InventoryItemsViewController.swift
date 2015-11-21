//
//  InventoryItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 01/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import SwiftValidator

class InventoryItemsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AddEditInventoryControllerDelegate, BottonPanelViewDelegate, AddEditInventoryItemControllerDelegate, InventoryItemsTableViewControllerDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var settingsView: UIView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!

    private var sortByPopup: CMPopTipView?
    
    private var tableViewController: InventoryItemsTableViewController?

    @IBOutlet weak var floatingViews: FloatingViews!

    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!

    private var addEditInventoryControllerManager: ExpandableTopViewController<AddEditInventoryController>?
    private var addEditInventoryItemControllerManager: ExpandableTopViewController<AddEditInventoryItemController>?

    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    private var inventory: Inventory? {
        didSet {
            tableViewController?.sortBy = .Count
            tableViewController?.inventory = inventory
            if let inventory = inventory {
                navigationItem.title = inventory.name
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navSingleTap = UITapGestureRecognizer(target: self, action: "navSingleTap")
        navSingleTap.numberOfTapsRequired = 1
        navigationController?.navigationBar.subviews.first?.userInteractionEnabled = true
        navigationController?.navigationBar.subviews.first?.addGestureRecognizer(navSingleTap)
        
        if let tableView = tableViewController?.tableView {
            addEditInventoryControllerManager = initAddEditInventoryControllerManager(tableView)
            addEditInventoryItemControllerManager = initAddEditInventoryItemsManager(tableView)
            
        } else {
            print("Error: InventoryItemsViewController.viewDidLoad no tableview in tableViewController")
        }
        
    }

    private func initAddEditInventoryControllerManager(tableView: UITableView) -> ExpandableTopViewController<AddEditInventoryController> {
        let top: CGFloat = navigationController!.navigationBar.frame.maxY
        let manager: ExpandableTopViewController<AddEditInventoryController> = ExpandableTopViewController(top: top, height: 90, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventory()
            controller.delegate = self
//            controller.view.clipsToBounds = true
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    
    private func initAddEditInventoryItemsManager(tableView: UITableView) -> ExpandableTopViewController<AddEditInventoryItemController> {
        let top: CGFloat = navigationController!.navigationBar.frame.maxY
        let manager: ExpandableTopViewController<AddEditInventoryItemController> = ExpandableTopViewController(top: top, height: 180, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventoryItem()
            controller.delegate = self
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    func navSingleTap() {
        addEditInventoryControllerManager?.controller?.inventoryToEdit = inventory
        addEditInventoryItemControllerManager?.expand(false)
        addEditInventoryControllerManager?.expand(!(addEditInventoryControllerManager?.expanded ?? true)) // if for some reason manager was not set, contract (!true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        initFloatingViews()
        
        Providers.inventoryProvider.firstInventory(successHandler {[weak self] inventory in
            self?.navigationItem.title = inventory.name
            self?.inventory = inventory
        })
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy(sortByOption.value)
        sortByButton.setTitle(sortByOption.key, forState: .Normal)
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    private func sortBy(sortBy: InventorySortBy) {
        tableViewController?.sortBy = sortBy
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedInventoryItemsTableViewSegue" {
            tableViewController = segue.destinationViewController as? InventoryItemsTableViewController
            tableViewController?.delegate = self
        }
    }
    
    @IBAction func onSortByTap(sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sortByButton, inView: view, animated: true)
        }
    }
    
    private func initFloatingViews() {
        floatingViews.setActions(Array<FLoatingButtonAction>())
        floatingViews.delegate = self
    }
    
    // MARK: - AddEditInventoryViewController
    
    func onInventoryUpdated(inventory: Inventory) {
        self.inventory = inventory
        addEditInventoryControllerManager?.expand(false)
    }
    
    @IBAction func onEditTap(sender: UIButton) {
        
        if let tableViewController = tableViewController {
            tableViewController.setEditing(!tableViewController.editing, animated: true)
            editButton.title = tableViewController.editing ? "Done" : "Edit"
            
        } else {
            print("Warn: InventoryItemsViewController.onEditTap edit tap but no tableViewController")
        }
    }

    // No add directly to inventory for now (or maybe ever). Otherwise user may get confused about how to use the app - it should be clear that items are added automatically when making cart as bought.
//    @IBAction func onAddTap(sender: UIButton) {
//        setAddEditInventoryItemControllerOpen(!addEditInventoryItemController.open)
//    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        handleFloatingViewAction(action)
    }
    
    private func handleFloatingViewAction(action: FLoatingButtonAction) {
        switch action {
        case .Submit:
            if addEditInventoryControllerManager?.expanded ?? false {
                addEditInventoryControllerManager?.controller?.submit()
            } else if addEditInventoryItemControllerManager?.expanded ?? false {
                addEditInventoryItemControllerManager?.controller?.submit()
            } else {
                print("Warn: InventoryItemsViewController.handleFloatingViewAction: .Submit called but no top view controller is open")
            }
        default: break
        }
    }
    
    // MARK: - AddEditInventoryItemControllerDelegate
    
    
    func onSubmit(name: String, category: String, price: Float, quantity: Int, editingInventoryItem: InventoryItem?) {
        
        if let inventory = inventory {
            
            if let editingInventoryItem = editingInventoryItem {
                let updatedCategory = editingInventoryItem.product.category.copy(name: category)
                let updatedProduct = editingInventoryItem.product.copy(name: name, price: price, category: updatedCategory)
                // TODO! calculate quantity delta correctly?
                let updatedInventoryItem = editingInventoryItem.copy(quantity: quantity, quantityDelta: quantity, product: updatedProduct)
                Providers.inventoryItemsProvider.updateInventoryItem(inventory, item: updatedInventoryItem, successHandler {[weak self] in
                    // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
                    self?.tableViewController?.clearAndLoadFirstPage()
                    self?.addEditInventoryItemControllerManager?.controller?.clear()
                    self?.addEditInventoryItemControllerManager?.expand(false)
                })
                
            } else {
                
                print("Not supported: Adding directly to inventory")
//                let input = InventoryItemInput(name: name, quantity: quantity, price: price, category: category)
//                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, successHandler{[weak self] addedInventoryWithHistoryEntry in
//                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
//                    self?.tableViewController?.clearAndLoadFirstPage()
//                    self?.addEditInventoryItemController.clear()
//                    self?.setAddEditInventoryItemControllerOpen(false)
//                })
            }
        }
    }
    
    func onCancelTap() {
    }

    func onValidationErrors(errors: [UITextField : ValidationError]) {
        presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    // MARK: - InventoryItemsTableViewControllerDelegate
    
    func onInventoryItemSelected(inventoryItem: InventoryItem, indexPath: NSIndexPath) {
        if tableViewController?.editing ?? false {
            addEditInventoryItemControllerManager?.expand(true)
            addEditInventoryItemControllerManager?.controller?.editingInventoryItem = inventoryItem
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = view.frame.height
        self.view.layoutIfNeeded()
    }
}