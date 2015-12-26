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

class PlanViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PlanTableViewCellDelegate/*, AddEditPlanItemContentViewDelegate*/
, QuickAddDelegate, AddEditListItemViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate
{

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var consumedPriceLabel: UILabel!
    @IBOutlet weak var priceDeltaLastMonthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var emptyPlanView: UIView!

    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var topBar: ListTopBarView!

    private var updatingPlanItem: PlanItem?
    
    private var currentTopController: UIViewController?

    private var planItems: [PlanItem] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var currentInventory: Inventory?
    
    private var addEditPlanItemControllerManager: ExpandableTopViewController<AddEditListItemViewController>?
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        setEditing(false, animated: false)

        topQuickAddControllerManager = initTopQuickAddControllerManager()
        addEditPlanItemControllerManager = initAddEditPlanItemControllerManager()
        
        initTopBar()
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyPlanViewTap:"))
        emptyPlanView.addGestureRecognizer(tapRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketPlanItem:", name: WSNotificationName.PlanItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopBar() {
        topBar.title = "Plan (\(NSDate.currentMonthName()))"
        topBar.positionTitleLabelLeft(true, animated: false)
        topBar.delegate = self
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonIds([.ToggleOpen])
    }
    
    private func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = CGRectGetHeight(topBar.frame) + 30
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: 290, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.productDelegate = self
            controller.modus = .PlanItem
            if let backgroundColor = self?.view.backgroundColor {
                controller.addProductsOrGroupBgColor = UIColor.opaqueColorByApplyingTransparentColorOrBackground(backgroundColor.colorWithAlphaComponent(0.3), backgroundColor: UIColor.whiteColor())
            }
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    private func initAddEditPlanItemControllerManager() -> ExpandableTopViewController<AddEditListItemViewController> {
        let top = CGRectGetHeight(topBar.frame) + 30
        let manager: ExpandableTopViewController<AddEditListItemViewController> = ExpandableTopViewController(top: top, height: 200, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditListItemViewController()
            controller.delegate = self
            controller.onViewDidLoad = {
                controller.modus = .PlanItem
            }
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Providers.inventoryProvider.inventories(successHandler {[weak self] inventories in
            if let inventory = inventories.first {
                self?.currentInventory = inventory
                
                self?.initPlanItems() // TODO pass the inventory
                
            } else {
                print("TODO in plan but no inventory created yet")
                // what do we do here, multiple possiblities - create inventory automatically at intro but what happens if user has already an account on other device (with same inventory name)
                // maybe show a popup at start asking if want to synchronize (login), if not auto create the inventory - or always autocreate and let the inventory "there" if new
                // (inventories have uuids so same name is not a problem, maybe do a check and rename in "home(2)" or something like that.
                // Alternatively do a merge but with which inventory etc, this may be complex.
            }
            
        })
    }
    
    func onEmptyPlanViewTap(sender: UITapGestureRecognizer) {
        toggleTopAddController()
    }
    
    private func updateEmptyPlanView() {
        emptyPlanView.setHiddenAnimated(!planItems.isEmpty)
    }
    
    private func initPlanItems(scrollToItem: PlanItem? = nil) {
        Providers.planProvider.planItems(successHandler {[weak self] planItems in
            self?.planItems = planItems
            self?.updateEmptyPlanView()
            
            if let scrollToItem = scrollToItem {
                if let index = self?.planItems.indexOfUsingIdentifiable(scrollToItem) {
                    let indexPath = NSIndexPath(forRow: index, inSection: 0)
                    self?.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                    
                } else {
                    print("Error: PlanViewController.initPlanItems: After fetch plan items the item to scroll to was not found")
                }
            }
            
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
        updatingPlanItem = planItem
        addEditPlanItemControllerManager?.expand(true)
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
        addEditPlanItemControllerManager?.controller?.updatingPlanItem = planItem
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            let planItem = planItems[indexPath.row]
            removePlanItemUI(planItem)
            Providers.planProvider.removePlanItem(planItem, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.initPlanItems()
                self?.defaultErrorHandler()(providerResult: result)
            }))
        }
    }
    
    private func indexPathForPlanItem(planItem: PlanItem) -> NSIndexPath? {
        let indexMaybe = planItems.enumerate().filter{$0.element.same(planItem)}.first?.index
        return indexMaybe.map{NSIndexPath(forRow: $0, inSection: 0)}
    }
    
    private func removePlanItemUI(planItem: PlanItem) {
        if let indexPath = indexPathForPlanItem(planItem) {
            removePlanItemUI(planItem, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.removePlanItemUI: Info: planItem to be updated was not in table view: \(planItem)")
        }
    }

    
    private func removePlanItemUI(planItem: PlanItem, indexPath: NSIndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.planItems.remove(planItem)
            self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
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
    
    private func updateIncrementUI(originalItem: PlanItem, delta: Int, cell: PlanTableViewCell?, row: Int) {
        let incrementedItem = originalItem.incrementQuantityCopy(delta)
        planItems[row] = incrementedItem
        if let cell = cell {
            cell.planItem = incrementedItem
            cell.quantityLabel.text = "\(incrementedItem.quantity)"
        }
    }
    
    private func removeUI(row: Int) {
        tableView.wrapUpdates {[weak self] in
            self?.planItems.removeAtIndex(row)
            self?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Bottom)
            self?.updateEmptyPlanView()
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
        topQuickAddControllerManager?.expand(!(topQuickAddControllerManager?.expanded ?? true)) // if for some reason not set, contract (!true)
//        setAddEditPlanItemOpen(!(addEditPlanItemControllerManager?.expanded ?? true)) // if for some reason not set, contract (!true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        tableView.setEditing(editing, animated: true)
        
        if editing {

        } else {
            topBar.setLeftButtonIds([.Edit])
        }
    }
    
//    // MARK: - AddEditPlanItemContentViewDelegate
//    

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
//        addEditPlanItemControllerManager?.controller?.clearInputs()
        
        topQuickAddControllerManager?.expand(false)
    }

    private func updateItemUI(planItem: PlanItem) {
        planItems.update(planItem)
        updateTotalPlanPrice()
        tableView.reloadData()
        
        // this is not necessary anymore because the expand manager always re-creates the controller but this implementation detail may change
//        addEditPlanItemControllerManager?.controller?.clearInputs()
//        addEditPlanItemControllerManager?.controller?.clearEditingItem()

        setAddEditPlanItemOpen(false)
    }
//
//    private func toPlanItemInput(name: String, priceText: String, quantityText: String, category: String, baseQuantity: Float, unit: ProductUnit) -> PlanItemInput? {
//        if let price = priceText.floatValue, quantity = Int(quantityText) {
//            return PlanItemInput(name: name, quantity: quantity, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
//        } else {
//            print("TODO validation in toPlanItemInput")
//            return nil
//        }
//    }
//    

    
    private func setAddEditPlanItemOpen(open: Bool) {
        
        if !open {
            // this is not necessary anymore because the expand manager always re-creates the controller but this implementation detail may change
//            addEditPlanItemControllerManager?.controller?.clearInputs()
//            addEditPlanItemControllerManager?.controller?.clearEditingItem()
        }

        addEditPlanItemControllerManager?.expand(open)
    }
    
    // MARK: - QuickAddDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
    }
    
    private func onGroupsAdded() {
        if let _ = currentInventory {
            initPlanItems() // TODO pass the inventory
            
        } else {
            print("Invalid state, coming back from groups and no list")
        }
    }

    private func onProductsAdded(scrollToItem: PlanItem?) {
        if let _ = currentInventory {
            initPlanItems(scrollToItem) // TODO pass the inventory
            
        } else {
            print("Invalid state, coming back from groups and no list")
        }
    }

    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let inventory = currentInventory {
            Providers.planProvider.addGroupItems(group.items, inventory: inventory, successHandler{[weak self] planItems in
                self?.onGroupsAdded()
                // TODO!! show popover with "group added etc"
            })
        }
    }
    
    
    func onAddProduct(product: Product) {
        if let inventory = currentInventory {
            Providers.planProvider.addProduct(product, inventory: inventory, successHandler {[weak self] planItem in
                self?.onProductsAdded(planItem)
            })
        }
    }
    
    func onQuickListOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
    }
    
    func onAddProductOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Add),
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    
    // MARK: - AddEditListItemViewControllerDelegate

    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {

        if !name.isEmpty {
            
            if let price = priceText.floatValue, quantity = Int(quantityText), inventory = currentInventory {
                let planItemInput = PlanItemInput(name: name, quantity: quantity, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit)
                
                Providers.planProvider.addPlanItems([planItemInput], inventory: inventory, self.successHandler{[weak self] planItems in
                    self?.initPlanItems() // TODO update only added?
                })
            } else {
                print("TODO validation in processListItemInputs >>>") // TODO why do we get text here in delegate validation can be done in quick add, we have a method that receives validation errors!
            }
        }
    }

    // TODO remove not used
    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        if let updatingPlanItem = updatingPlanItem, price = priceText.floatValue, quantity = Int(quantityText), inventory = currentInventory {
            updatePlanItem(updatingPlanItem, inventory: inventory, name: name, price: price, quantity: quantity, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit)
        } else {
            print("Error: AddEditPlanItemController.updatePlanItem: validation not implemented correctly or currentInventory not set")
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }

    
    // TODO remove not used
    func onCancelTap() {
    }
    
    private func updatePlanItem(planItem: PlanItem, inventory: Inventory, name: String, price: Float, quantity: Int, category: String, categoryColor: UIColor, baseQuantity: Float, unit: ProductUnit) {
        let updatedCategory = planItem.product.category.copy(name: category, color: categoryColor)
        let updatedProduct = planItem.product.copy(name: name, price: price, category: updatedCategory, baseQuantity: baseQuantity, unit: unit)
        let quantityDelta = quantity - planItem.quantity // TODO! this is not most likely not correct, needs to include also planItem.quantityDelta?
        let updatedPlanItem = planItem.copy(product: updatedProduct, quantity: quantity, quantityDelta: quantityDelta)
        
        Providers.planProvider.updatePlanItem(updatedPlanItem, inventory: inventory, successHandler{[weak self] planItem in
            self?.onPlanItemUpdated(planItem)
        })
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    func onExpandableClose() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
        setEditing(!self.tableView.editing, animated: false)
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        // not used
        switch buttonId {
        case .Add:
            sendActionToTopController(.Add)
        case .Submit:
            if addEditPlanItemControllerManager?.expanded ?? false {
                addEditPlanItemControllerManager?.controller?.submit(.Update)
            } else {
                sendActionToTopController(.Submit)
            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            setEditing(!self.tableView.editing, animated: false)
        }
    }
    
    func onTopBarTitleTap() {
        // not used
    }
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.Back)
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
        // not used
    }
 
    
    // MARK: - 
    
    private func toggleTopAddController() {
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || addEditPlanItemControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            addEditPlanItemControllerManager?.expand(false)
            
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])

        }
    }
    
    private func sendActionToTopController(action: FLoatingButtonAction) {
        
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        } else if addEditPlanItemControllerManager?.expanded ?? false {
            // here we do dispatching in place as it's relatively simple and don't want to contaminate to many view controllers with floating button code
            // there should be a separate component to do all this but no time now. TODO improve
            
            switch action {
            case .Submit:
                addEditPlanItemControllerManager?.controller?.submit(.Update)
            case .Back, .Add, .Toggle, .Expand: print("PlanViewController.sendActionToTopController: Invalid action: \(action)")
            }
        }
    }
    
    // MARK: - Websocket
    
    func onWebsocketPlanItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<PlanItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    initPlanItems() // TODO update only added?
                case .Update:
                    onPlanItemUpdated(notification.obj)
                case .Delete:
                    removePlanItemUI(notification.obj)
                }
            } else {
                print("Error: PlanViewController.onWebsocketPlanItem: no value")
            }
        } else {
            print("Error: PlanViewController.onWebsocketPlanItem: no userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    // TODO!! update all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                case .Delete:
                    // TODO!! delete all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                print("Error: PlanViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: PlanViewController.onWebsocketProduct: no userInfo")
        }
    }
}