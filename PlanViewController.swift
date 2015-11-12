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

class PlanViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlanTableViewCellDelegate, AddEditPlanItemContentViewDelegate {

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var consumedPriceLabel: UILabel!
    @IBOutlet weak var priceDeltaLastMonthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!

    @IBOutlet weak var navigationBar: UINavigationBar!
    
    private var currentTopController: UIViewController?

    private var planItems: [PlanItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var currentInventory: Inventory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
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

        initPlanItems()
    }

    private func initPlanItems() {
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
        let planItem = planItems[indexPath.row]
        addEditController.editingPlanItem = planItem
        setAddEditPlanItemOpen(true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            let planItem = planItems[indexPath.row]
            tableView.wrapUpdates {[weak self] in
                self?.planItems.remove(planItem)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            }
            Providers.planProvider.removePlanItem(planItem, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.initPlanItems()
                self?.defaultErrorHandler()(providerResult: result)
            }))
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
            sum + element.totalPrice
        }
        totalPriceLabel.text = price.toLocalCurrencyString()
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true)
    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        setAddEditPlanItemOpen(!addEditController.open)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: true)
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    // MARK: - AddEditPlanItemContentViewDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        //        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }

    func onPlanItemAdded(planItem: PlanItem) {
        addItemUI(planItem)
    }
    
    func onPlanItemUpdated(planItem: PlanItem) {
        updateItemUI(planItem)
    }
    
    private func addItemUI(planItem: PlanItem) {
        if !planItems.update(planItem) {
            planItems.append(planItem)
        }
        updateTotalPlanPrice()
        tableView.reloadData()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: planItems.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
        addEditController.clearInputs()
    }

    private func updateItemUI(planItem: PlanItem) {
        planItems.update(planItem)
        updateTotalPlanPrice()
        tableView.reloadData()
        addEditController.clearInputs()
        addEditController.clearEditingItem()

        setAddEditPlanItemOpen(false)
        
        // scroll to cell
//        if let index = planItems.indexOfUsingIdentifiable(planItem) {
//            let indexPath = NSIndexPath(forRow: index, inSection: 0)
//            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
//        } else {
//            print("Error: PlanViewController.updateItemUI. Invalid state: can't find updating plan item in table view")
//        }
    }
    
    private func toPlanItemInput(name: String, priceText: String, quantityText: String, category: String, baseQuantity: Float, unit: ProductUnit) -> PlanItemInput? {
        if let price = priceText.floatValue, quantity = Int(quantityText) {
            return PlanItemInput(name: name, quantity: quantity, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
        } else {
            print("TODO validation in toPlanItemInput")
            return nil
        }
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // TODO refactor top controller with list items, manage products etc.
    
    private lazy var addEditController: AddEditPlanItemController = {
        let controller = AddEditPlanItemController()
        self.initTopController(controller, height: 250)
        controller.currentInventory = self.currentInventory
        controller.delegate = self
        return controller
    }()
    
    private func setAddEditPlanItemOpen(open: Bool) {
        
        if !open {
            addEditController.clearInputs()
            addEditController.clearEditingItem()
        }

        addEditController.open = open

        animateTopView(addEditController, open: open, tableView: tableView)
    }
    
    
    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view

        view.frame = CGRectMake(0, CGRectGetHeight(navigationBar.frame) + 60, self.view.frame.width, height) // 60 total view height
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    // parameter: tableView: This is normally the listitem's table view, except when we are in section-only mode, which needs a different table view
    private func animateTopView(controller: UIViewController, open: Bool, tableView: UITableView) {
        let view = controller.view
        if open {
            self.addChildViewControllerAndView(controller)
            let topInset = CGRectGetHeight(navigationBar.frame) + CGRectGetHeight(view.bounds) + 60 // 60 total view height
            tableViewOverlay.frame = CGRectMake(tableView.frame.origin.x, topInset, tableView.frame.width, tableView.frame.height - tableView.topInset)
            self.view.insertSubview(tableViewOverlay, aboveSubview: tableView)
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
            
            let topInset = open ? CGRectGetHeight(view.frame) : 0
//            let topInset: CGFloat = 0
            let bottomInset = self.tabBarController?.tabBar.frame.height
            tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
            tableView.topOffset = -tableView.inset.top
            
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
        if addEditController.open {
            setAddEditPlanItemOpen(false)
        }
    }    
}