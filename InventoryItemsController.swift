//
//  GroupItemsController.swift
//  shoppin
//
//  Created by ischuetz on 03/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwiftValidator


class ProductWithQuantityInv: ProductWithQuantity {
    let inventoryItem: InventoryItem
    
    override var product: Product {
        return inventoryItem.product
    }
    
    override var quantity: Int {
        return inventoryItem.quantity
    }
    
    init(inventoryItem: InventoryItem) {
        self.inventoryItem = inventoryItem
    }
    override func incrementQuantityCopy(delta: Int) -> ProductWithQuantity {
        let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
        return ProductWithQuantityInv(inventoryItem: incrementedItem)
    }
}

class InventoryItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, AddEditListItemViewControllerDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    private var addEditInventoryItemControllerManager: ExpandableTopViewController<AddEditListItemViewController>?
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    var inventory: Inventory? {
        didSet {
            if let inventory = inventory {
                topBar.title = inventory.name
            }
        }
    }
    
    var expandDelegate: Foo?
    
    private var titleLabel: UILabel?

    var onViewWillAppear: VoidFunction?
    
    private var productsWithQuantityController: ProductsWithQuantityViewController!

    private var updatingInventoryItem: InventoryItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventory:", name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryItems:", name: WSNotificationName.InventoryItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryItem:", name: WSNotificationName.InventoryItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryWithHistoryAfterSave:", name: WSNotificationName.InventoryItemsWithHistoryAfterSave.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    override func viewDidLayoutSubviews() {
        // add the embedded controller's view
        if productsWithQuantityController.view.superview == nil {
            containerView.addSubview(productsWithQuantityController.view)
            productsWithQuantityController.view.fillSuperview()
            
            if let tableView = productsWithQuantityController?.tableView {
                addEditInventoryItemControllerManager = initAddEditInventoryItemsManager(tableView)
                topQuickAddControllerManager = initTopQuickAddControllerManager(tableView)
                
            } else {
                print("Error: InventoryItemsViewController.viewDidLoad no tableview in tableViewController")
            }
            
        }
    }

    func setThemeColor(color: UIColor) {
        // TODO complete theme, like in list items?
        topBar.backgroundColor = color
        //        view.backgroundColor = UIColor.whiteColor()
        
        let colorArray = NSArray(ofColorsWithColorScheme: ColorScheme.Complementary, with: color, flatScheme: true)
        view.backgroundColor = colorArray[0] as? UIColor // as? to silence warning
        //        listItemsTableViewController.view.backgroundColor = colorArray[0] as? UIColor // as? to silence warning
        //        listItemsTableViewController.headerBGColor = colorArray[1] as? UIColor // as? to silence warning
        
        let compl = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
        
        // adjust nav controller for cart & stash (in this controller we use a custom view).
        navigationController?.setColors(color, textColor: compl)
        
        titleLabel?.textColor = compl
        
        //        expandButtonModel.bgColor = (colorArray[4] as! UIColor).lightenByPercentage(0.5)
        //        expandButtonModel.pathColor = UIColor(contrastingBlackOrWhiteColorOn: expandButtonModel.bgColor, isFlat: true)
        
        topBar.fgColor = compl
        
        //        emptyListViewImg.tintColor = compl
        //        emptyListViewLabel1.textColor = compl
        //        emptyListViewLabel2.textColor = compl
    }
    
    
    private func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.whiteColor()
        topBar.addSubview(label)
        titleLabel = label
    }
    
    private func initTopQuickAddControllerManager(tableView: UITableView) -> ExpandableTopViewController<QuickAddViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: 290, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
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
    
    func onExpand(expanding: Bool) {
        if !expanding {
            productsWithQuantityController?.emptyView.hidden = true
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
            // Clear memory cache when we leave controller. This is not really necessary but just "in case". The memory cache is there to smooth things *inside* an inventory, Basically quick adding/incrementing.
            Providers.inventoryItemsProvider.invalidateMemCache()
        }
        topBar.layoutIfNeeded() // FIXME weird effect and don't we need this in view controller
        topBar.positionTitleLabelLeft(expanding, animated: true)
    }
    
    func onExpandableClose() {
        topBarOnCloseExpandable()
    }
    
    private func topBarOnCloseExpandable() {
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    private func initAddEditInventoryItemsManager(tableView: UITableView) -> ExpandableTopViewController<AddEditListItemViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<AddEditListItemViewController> =  ExpandableTopViewController(top: top, height: 240, animateTableViewInset: false, parentViewController: self, tableView: tableView) {
            let controller = UIStoryboard.addEditListItemViewController()
            controller.delegate = self
            controller.onViewDidLoad = {
                controller.modus = .GroupItem
            }
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        onViewWillAppear?()
        onViewWillAppear = nil
    }

    
    private func toggleEditing() {
        if let productsWithQuantityController = productsWithQuantityController {
            let editing = !productsWithQuantityController.editing // toggle
            productsWithQuantityController.setEditing(editing, animated: true)
        } else {
            print("Warn: InventoryItemsViewController.toggleEditing edit tap but no tableViewController")
        }
    }
    
    // MARK: - AddEditListItemViewControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand) {
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        
        if let updatingInventoryItem = updatingInventoryItem {
            if let price = priceText.floatValue, quantity = Int(quantityText) {
                let updatedCategory = updatingInventoryItem.product.category.copy(name: category)
                let updatedProduct = updatingInventoryItem.product.copy(name: name, price: price, category: updatedCategory, brand: brand)
                // TODO! calculate quantity delta correctly?
                let updatedInventoryItem = updatingInventoryItem.copy(quantity: quantity, quantityDelta: quantity, product: updatedProduct)
                Providers.inventoryItemsProvider.updateInventoryItem(updatedInventoryItem, remote: true, successHandler {[weak self] in
                    self?.onInventoryItemUpdated()
                })
            }
        } else {
            print("Warn: InventoryItemsController.onUpdateTap: No updatingGroupItem")
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestionsContainingText(text, successHandler{suggestions in
            handler(suggestions)
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, successHandler: VoidFunction? = nil) {
        
        if let inventory = inventory {
            
            if let price = priceText.floatValue, quantity = Int(quantityText) {
                
                let input = InventoryItemInput(name: name, quantity: quantity, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit, brand: brand)
                
                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, self.successHandler{[weak self] (inventoryItemWithHistoryEntry: InventoryItemWithHistoryEntry) in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
                    
                    self?.productsWithQuantityController?.clearAndLoadFirstPage()
                    
                    self?.toggleTopAddController()
                })
            }
            
        } else {
            print("Error: InventoryItemsViewController.submitInputs: No inventory")
        }
    }
    
    
    func onInventoryItemUpdated() {
        // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
        productsWithQuantityController?.clearAndLoadFirstPage()
//        addEditInventoryItemControllerManager?.controller?.clear()
        addEditInventoryItemControllerManager?.expand(false)
        topBarOnCloseExpandable()
    }

    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        // not used
    }
    
    func onTopBarTitleTap() {
        onExpand(false)
        expandDelegate?.setExpanded(false)
    }
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Add:
            sendActionToTopController(.Add)
        case .Submit:
            if topQuickAddControllerManager?.expanded ?? false {
                sendActionToTopController(.Submit)
            } else if addEditInventoryItemControllerManager?.expanded ?? false {
                addEditInventoryItemControllerManager?.controller?.submit(.Update)
            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            toggleEditing()
        }
    }
    
    private func toggleTopAddController() {
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || addEditInventoryItemControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            addEditInventoryItemControllerManager?.expand(false)
            
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
        }
    }
    
    // TODO remove floating button things, we don't use floating button here
    private func sendActionToTopController(action: FLoatingButtonAction) {
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        }
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
        if center {
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonIds([.ToggleOpen])
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = view.frame.height
        self.view.layoutIfNeeded()
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let inventory = inventory {
            let inventoryItems: [InventoryItemWithHistoryEntry] = group.items.map {item in
                let inventoryItem = InventoryItemWithHistoryEntry(inventoryItem: InventoryItem(quantity: item.quantity, quantityDelta: item.quantity, product: item.product, inventory: inventory), historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail")) // TODO remove the offline dummy email? to add inventory shared user is not needed (the server uses the logged in user).
                return inventoryItem
            }
            Providers.inventoryItemsProvider.addToInventory(inventoryItems, remote: true, successHandler{[weak self] result in
                self?.productsWithQuantityController?.addOrIncrementUI(inventoryItems.map{ProductWithQuantityInv(inventoryItem: $0.inventoryItem)})
            })
        }
    }
    
    
    func onAddProduct(product: Product) {
        if let inventory = inventory {
            let inventoryItem = InventoryItemWithHistoryEntry(inventoryItem: InventoryItem(quantity: 1, quantityDelta: 1, product: product, inventory: inventory), historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail")) // TODO remove the offline dummy email? to add inventory shared user is not needed (the server uses the logged in user).
            Providers.inventoryItemsProvider.addToInventory([inventoryItem], remote: true, successHandler{[weak self] result in
                self?.productsWithQuantityController?.addOrIncrementUI(ProductWithQuantityInv(inventoryItem: inventoryItem.inventoryItem))
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
    
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "productsWithQuantityControllerSegue" {
            productsWithQuantityController = segue.destinationViewController as? ProductsWithQuantityViewController
            productsWithQuantityController?.delegate = self
        }
    }
    
    // MARK: - ProductsWithQuantityViewControllerDelegate
    
    func loadModels(page: NSRange, sortBy: InventorySortBy, onSuccess: [ProductWithQuantity] -> Void) {
        if let inventory = inventory {
            // .MemOnly fetch mode prevents following - when we add items to the inventory and switch to inventory very quickly, the db has not finished writing the items yet! and the load request reads the items from db before the write finishes so if we pass fetchMode .Both, first the mem cache returns the correct items but then the call - to the db - returns still the old items. So we pass mem cache which has the correct state, ignoring the db result.
            Providers.inventoryItemsProvider.inventoryItems(page, inventory: inventory, fetchMode: .MemOnly, sortBy: sortBy, successHandler{inventoryItems in
                let productsWithQuantity = inventoryItems.map{ProductWithQuantityInv(inventoryItem: $0)}
                onSuccess(productsWithQuantity)
            })
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func onLoadedModels(models: [ProductWithQuantity]) {
        // TODO is this necessary?
    }
    
    func remove(model: ProductWithQuantity, onSuccess: VoidFunction, onError: ProviderResult<Any> -> Void) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.removeInventoryItem(model.product.uuid, inventoryUuid: inventory.uuid, remote: true, resultHandler(onSuccess: {
                onSuccess()
                }, onError: {result in
                    onError(result)
            }))
        } else {
            print("Error: InventoryItemsController.remove: no inventory")
        }
    }
    
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: VoidFunction) {
        Providers.inventoryItemsProvider.incrementInventoryItem((model as! ProductWithQuantityInv).inventoryItem, delta: delta, successHandler({result in
            onSuccess()
        }))
    }
    
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath) {
        if productsWithQuantityController.editing {
            let inventoryItem = (model as! ProductWithQuantityInv).inventoryItem
            updatingInventoryItem = inventoryItem
            addEditInventoryItemControllerManager?.expand(true)
            addEditInventoryItemControllerManager?.controller?.updatingItem = AddEditItem(item: inventoryItem)
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: "You inventory is empty", text2: "Mark cart items as \"bought\" or tap to add directly", imgName: "empty_shelf")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
    }
    
    // MARK: - Websocket
    
    func onWebsocketInventory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Inventory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    //                case .Add: // we only use 1 inventory currently
                case .Update:
                    // TODO review this carefully, if we update the inventory here but the provider saving fails currently nothing happens
                    // and changes the user do to this not saved inventory get lost
                    // Ideally in the future we trigger also notifications when saving fails, such that the controllers revert their changes (and maybe show non-modal small error notification)
                    // added following temporary uuid check just to help avoiding issues here (should not happen though!)
                    if let inventory = inventory {
                        if notification.obj.uuid == inventory.uuid {
                            self.inventory = notification.obj
                        } else {
                            print("Error: Invalid state: we should not get updates for an inventory with a different uuid than our inventory")
                        }
                    } else {
                        print("Info: Received a websocket inventory update before inventory is loaded. Doing nothing.")
                    }
                    
                    //                case .Delete: // we only use 1 inventory currently and it can't be deleted
                    //                    removeProductUI(notification.obj)
                default: print("Error: InventoryItemsViewController.onWebsocketInventory: not implemented: \(notification.verb)")
                    
                }
            } else {
                print("Error: ViewController.onWebsocketInventory: no userInfo")
            }
        }
    }
    
    func onWebsocketInventoryItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<InventoryItemIncrement>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Add:
                    let incr = notification.obj
                    Providers.inventoryItemsProvider.incrementInventoryItem(incr, remote: false, successHandler{[weak self] inventoryItem in
                        self?.productsWithQuantityController?.updateIncrementUI(ProductWithQuantityInv(inventoryItem: inventoryItem), delta: incr.delta)
                    })
                default: print("Error: ViewController.onWebsocketInventoryItems: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: ViewController.onWebsocketInventoryItems: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketInventoryItems: no userInfo")
        }
    }
    
    func onWebsocketInventoryItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Any>> {
            
            if let notification = info[WSNotificationValue] {
                
                switch notification.verb {
                case .Update:
                    if let inventoryItem = notification.obj as? InventoryItem {
                        Providers.inventoryItemsProvider.updateInventoryItem(inventoryItem, remote: false, successHandler {[weak self] in
                            self?.onInventoryItemUpdated()
                        })
                    } else {
                        print("Error: InventoryItemsViewController.onWebsocketInventoryItem: not expected type in: \(notification.verb): \(notification.obj)")
                    }
                    
                    // TODO? increment is covered in onWebsocketInventoryItems, but user can e.g. change name (update of product in this case, but still triggered from inventory...)
                    
                case .Delete:
                    if let inventoryItemId = notification.obj as? InventoryItemId {
                        Providers.inventoryItemsProvider.removeInventoryItem(inventoryItemId.productUuid, inventoryUuid: inventoryItemId.inventoryUuid, remote: true, successHandler{[weak self] result in
                            self?.productsWithQuantityController?.remove(inventoryItemId.inventoryUuid, inventoryItemProductUuid: inventoryItemId.productUuid)
                        })
                    } else {
                        print("Error: InventoryItemsViewController.onWebsocketInventoryItem: not expected type in: \(notification.verb): \(notification.obj)")
                    }
                    
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryItem: not implemented: \(notification.verb)")
                }
                
            } else {
                print("Error: InventoryItemsViewController.onWebsocketUpdateListItem: no value")
            }
            
        } else {
            print("Error: InventoryItemsViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketInventoryWithHistoryAfterSave(note: NSNotification) {
        
        // TODO!! (not only websocket related) InventoryItemWithHistoryEntry has only history item uuid, this is also sent like this to the server. Should we not send the item instead of only the uuid. At the very last this should be the case here with websocket since when we receive history item from another user/device we definitely don't have it yet so this uuid references nothing
        if let info = note.userInfo as? Dictionary<String, WSEmptyNotification> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    onInventoryItemUpdated()
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
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
                print("Error: InventoryItemsViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: InventoryItemsViewController.onWebsocketProduct: no userInfo")
        }
    }

}
