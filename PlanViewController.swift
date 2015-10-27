//
//  PlanViewController.swift
//  shoppin
//
//  Created by ischuetz on 06/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import KLCPopup
import SwiftValidator

class PlanViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlanTableViewCellDelegate, AddItemViewDelegate, AddEditPlanItemContentViewDelegate {

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var consumedPriceLabel: UILabel!
    @IBOutlet weak var priceDeltaLastMonthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!

    @IBOutlet weak var addItemView: AddItemView!
    @IBOutlet weak var addItemViewBottomConstraint: NSLayoutConstraint!
    
    private var addEditItemPopup: KLCPopup?
    private var addEditItemView: AddEditPlanItemContentView?
    
    private var planItems: [PlanItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var currentInventory: Inventory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addItemView.delegate = self
        addItemView.bottomConstraint = addItemViewBottomConstraint
        
        setEditing(false, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Providers.inventoryProvider.inventories(successHandler {[weak self] inventories in
            if let inventory = inventories.first {
                self?.currentInventory = inventory
            } else {
                print("TODO in plan but no inventory created yet")
                // what do we do here, multiple possiblities - create inventory automatically at intro but what happens if user has already an account on other device (with same inventory name)
                // maybe show a popup at start asking if want to synchronize (login), if not auto create the inventory - or always autocreate and let the inventory "there" if new
                // (inventories have uuids so same name is not a problem, maybe do a check and rename in "home(2)" or something like that.
                // Alternatively do a merge but with which inventory etc, this may be complex.
            }
            
        })
        
        Providers.planProvider.planItems(successHandler {[weak self] planItems in
            self?.planItems = planItems
            self?.updateCalculationsView()
        })
    }
    
    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return planItems.count
    }
    
    
    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let planItem = planItems[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("planCell", forIndexPath: indexPath) as! PlanTableViewCell
        cell.planItem = planItem
        cell.row = indexPath.row
        cell.delegate = self
        cell.selectionStyle = self.editing ? .Gray : .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if editing {
            let planItem = planItems[indexPath.row]
            let addEditView = createAndInitAddEditView()
            addEditView.prefill(planItem)
            addEditItemPopup = createAddEditPopup(addEditView)
            addEditItemPopup?.show()
        }
    }
    
    // MARK: - PlanTableViewCellDelegate
    
    func onPlusTap(planItem: PlanItem, cell: PlanTableViewCell, row: Int) {
        changePlanItemQuantity(cell, row: row, planItem: planItem, delta: 1)
    }
    
    func onMinusTap(planItem: PlanItem, cell: PlanTableViewCell, row: Int) {
        changePlanItemQuantity(cell, row: row, planItem: planItem, delta: -1)
    }
    
    // MARK:
    
    private func changePlanItemQuantity(cell: PlanTableViewCell, row: Int, planItem: PlanItem, delta: Int) {
        
        if planItem.quantity + delta >= 0 {
            
            Providers.planProvider.incrementPlanItem(planItem, delta: delta, successHandler({[weak self] result in
                
                if let weakSelf = self {
                    
                    weakSelf.updateIncrementUI(planItem, delta: delta, cell: cell, row: row)
                    weakSelf.updateTotalPlanPrice()
                    
                    if planItem.quantity + delta == 0 {
//                        cell.startDeleteProgress { // TODO?
                        
                            weakSelf.tableView.reloadData()

                            // TODO is it necessary to have multiple [weak self] in nested blocks? (we one above in incrementInventoryItem)
                            Providers.planProvider.removePlanItem(planItem, weakSelf.successHandler{[weak self] result in
                                self?.removeUI(row)
                            })
//                        }
                    } else {
                        weakSelf.tableView.reloadData()
                    }
                }
            }))
        }
    }
    
    func updateCalculationsView() {
        updateTotalPlanPrice()
        // TODO consumed, delta last month
    }
    
    private func updateIncrementUI(originalItem: PlanItem, delta: Int, cell: PlanTableViewCell, row: Int) {
        let incrementedItem = originalItem.incrementQuantityCopy(delta)
        planItems[row] = incrementedItem
        cell.planItem = incrementedItem
        cell.quantityLabel.text = "\(incrementedItem.quantity)"
    }
    
    private func removeUI(row: Int) {
        tableView.wrapUpdates {[weak self] in
            self?.planItems.removeAtIndex(row)
            self?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Bottom)
        }
    }
    
    private func updateTotalPlanPrice() {
        let price = planItems.reduce(0) {sum, element in
            sum + (Float(element.quantity) * element.product.price)
        }
        totalPriceLabel.text = price.toLocalCurrencyString()
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        addItemView.setVisible(editing, animated: animated)
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    private func createAndInitAddEditView() -> AddEditPlanItemContentView {
        let addEditItemView = NSBundle.loadView("AddEditPlanItemContentView", owner: self) as! AddEditPlanItemContentView
        addEditItemView.frame = CGRectMake(0, 0, 300, 400)
        addEditItemView.delegate = self
        self.addEditItemView = addEditItemView
        return addEditItemView
    }
    
    private func createAddEditPopup(contentView: AddEditPlanItemContentView) -> KLCPopup {
        return KLCPopup(contentView: contentView, showType: KLCPopupShowType.ShrinkIn, dismissType: KLCPopupDismissType.ShrinkOut, maskType: KLCPopupMaskType.Dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
    }
    
    // MARK: - AddItemViewDelegate
    
    func onAddTap() {
        addEditItemPopup = createAddEditPopup(createAndInitAddEditView())
        addEditItemPopup?.show()
    }
    
    // MARK: - AddEditPlanItemContentViewDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        //        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String) {
        addPlanItem(name, price: priceText, quantity: quantityText, category: category)
    }

    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, category: String) {
        addPlanItem(name, price: priceText, quantity: quantityText, category: category)
    }
    
    func onUpdateTap(name: String, price: String, quantity: String, category: String) {
        updatePlanItem(name, price: price, quantity: quantity, category: category)
    }
    
    func onCancelTap() {
        addEditItemPopup?.dismiss(true)
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.listItemsProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    private func updatePlanItem(name: String, price priceText: String, quantity quantityText: String, category: String) {
        if let planItemInput = toPlanItemInput(name, priceText: priceText, quantityText: quantityText, category: category), inventory = currentInventory {
            Providers.planProvider.updatePlanItem(planItemInput, inventory: inventory, successHandler{[weak self] planItem in
                self?.addEditItemPopup?.dismiss(true)
                self?.updateItemUI(planItem)
            })
        } else {
            print("Error: Couldn't create planItemInput or no current inventory")
        }
    }

    private func addPlanItem(name: String, price priceText: String, quantity quantityText: String, category: String) {
        if let planItemInput = toPlanItemInput(name, priceText: priceText, quantityText: quantityText, category: category), inventory = currentInventory {
            Providers.planProvider.addPlanItem(planItemInput, inventory: inventory, successHandler{[weak self] planItem in
                self?.addEditItemPopup?.dismiss(true)
                self?.addItemUI(planItem)
            })
        }
    }
    
    private func addItemUI(planItem: PlanItem) {
        planItems.append(planItem)
        updateTotalPlanPrice()
        tableView.reloadData()
    }

    private func updateItemUI(planItem: PlanItem) {
        planItems.update(planItem)
        updateTotalPlanPrice()
        tableView.reloadData()
    }
    
    private func toPlanItemInput(name: String, priceText: String, quantityText: String, category: String) -> PlanItemInput? {
        if let price = priceText.floatValue, quantity = Int(quantityText) {
            return PlanItemInput(name: name, quantity: quantity, price: price, category: category)
        } else {
            print("TODO validation in toPlanItemInput")
            return nil
        }
    }
}