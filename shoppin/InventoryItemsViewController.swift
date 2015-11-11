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

class InventoryItemsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AddEditInventoryControllerDelegate, BottonPanelViewDelegate, AddEditInventoryItemControllerDelegate, InventoryItemsTableViewControllerDelegate {

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
    }
    
    func navSingleTap() {
        addEditInventoryController.inventoryToEdit = inventory
        setAddEditInventoryControllerOpen(!addEditInventoryController.open)
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
        setAddEditInventoryControllerOpen(false)
    }
    
    // MARK: - Edit Inventory
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    private var currentTopController: UIViewController?
    
    
    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view
        
        view.frame = CGRectMake(0, navigationController!.navigationBar.frame.maxY, self.view.frame.width, height)
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    private lazy var addEditInventoryController: AddEditInventoryController = {
        let controller = UIStoryboard.addEditInventory()
        controller.delegate = self
        controller.view.clipsToBounds = true
        
        self.initTopController(controller, height: 90)
        return controller
    }()
    
    private lazy var addEditInventoryItemController: AddEditInventoryItemController = {
        let controller = UIStoryboard.addEditInventoryItem()
        controller.delegate = self
        
        self.initTopController(controller, height: 180)
        return controller
    }()
    
    private func setAddEditInventoryControllerOpen(open: Bool) {
        
        if addEditInventoryItemController.open {
           setAddEditInventoryItemControllerOpen(false)
        }
        
        addEditInventoryController.open = open
        
        if open {
            floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit)])
        } else {
            floatingViews.setActions(Array<FLoatingButtonAction>())
            addEditInventoryController.clear()
        }
        
        if let tableView = tableViewController?.tableView {
            animateTopView(addEditInventoryController, open: open, tableView: tableView)
        }
    }
    
    private func setAddEditInventoryItemControllerOpen(open: Bool) {
        
        if addEditInventoryController.open {
            setAddEditInventoryControllerOpen(false)
        }
        
        addEditInventoryItemController.open = open
        
        if open {
            floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit)])
        } else {
            floatingViews.setActions(Array<FLoatingButtonAction>())
            addEditInventoryItemController.clear()
        }
        
        if let tableView = tableViewController?.tableView {
            animateTopView(addEditInventoryItemController, open: open, tableView: tableView)
        }
    }
    
    // parameter: tableView: This is normally the listitem's table view, except when we are in section-only mode, which needs a different table view
    private func animateTopView(controller: UIViewController, open: Bool, tableView: UITableView) {
        let view = controller.view
        if open {
            self.addChildViewControllerAndView(controller)

            tableViewOverlay.frame = self.view.frame
            self.view.insertSubview(tableViewOverlay, aboveSubview: tableView)
            self.view.bringSubviewToFront(floatingViews)
            self.view.bringSubviewToFront(controller.view)
        } else {
            tableViewOverlay.removeFromSuperview()
        }

        UIView.animateWithDuration(0.3, animations: {
            if open {
                self.tableViewOverlay.alpha = 0.2
            } else {
                self.tableViewOverlay.alpha = 0
            }
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, open ? 1 : 0.001)

            self.topControlTopConstraint.constant = view.frame.height
            self.view.layoutIfNeeded()
            
            }) { finished in
                
                if !open {
                    controller.removeFromParentViewControllerWithView()
                }
        }
    }
    
    private lazy var tableViewOverlay: UIView = {
        let view = UIButton()
        view.backgroundColor = UIColor.blackColor()
        view.userInteractionEnabled = true
        view.alpha = 0
        view.addTarget(self, action: "onTableViewOverlayTap:", forControlEvents: .TouchUpInside)
        return view
    }()
    
    // closes top controller (whichever it may be)
    func onTableViewOverlayTap(sender: UIButton) {
        if addEditInventoryController.open {
            setAddEditInventoryControllerOpen(false)
        }
        if addEditInventoryItemController.open {
            setAddEditInventoryItemControllerOpen(false)
        }
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
            if addEditInventoryController.open {
                addEditInventoryController.submit()
            } else if addEditInventoryItemController.open {
                addEditInventoryItemController.submit()
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
                let updatedProduct = editingInventoryItem.product.copy(name: name, price: price, category: category)
                // TODO! calculate quantity delta correctly?
                let updatedInventoryItem = editingInventoryItem.copy(quantity: quantity, quantityDelta: quantity, product: updatedProduct)
                Providers.inventoryItemsProvider.updateInventoryItem(inventory, item: updatedInventoryItem, successHandler {[weak self] in
                    // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
                    self?.tableViewController?.clearAndLoadFirstPage()
                    self?.addEditInventoryItemController.clear()
                    self?.setAddEditInventoryItemControllerOpen(false)
                })
                
            } else {
                
                let input = InventoryItemInput(name: name, quantity: quantity, price: price, category: category)
                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, successHandler{[weak self] addedInventoryWithHistoryEntry in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
                    self?.tableViewController?.clearAndLoadFirstPage()
                    self?.addEditInventoryItemController.clear()
                    self?.setAddEditInventoryItemControllerOpen(false)
                })
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
            setAddEditInventoryItemControllerOpen(true)
            addEditInventoryItemController.editingInventoryItem = inventoryItem
        }
    }
}