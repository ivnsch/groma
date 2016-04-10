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
import QorumLogs

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

class InventoryItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
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

    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
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
                topQuickAddControllerManager = initTopQuickAddControllerManager(tableView)
                
            } else {
                print("Error: InventoryItemsViewController.viewDidLoad no tableview in tableViewController")
            }
            
        }
    }

    func setThemeColor(color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.whiteColor()
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
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .PlanItem
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
        topBar.positionTitleLabelLeft(expanding, animated: true, withDot: true, heightConstraint: topBarHeightConstraint)
    }
    
    func onExpandableClose() {
        topBarOnCloseExpandable()
        topQuickAddControllerManager?.controller?.onClose()        
    }
    
    private func topBarOnCloseExpandable() {
        topBar.setLeftButtonIds([.Edit])
//        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
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
    
    func onInventoryItemUpdated() {
        // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
        reload()
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
        topBarOnCloseExpandable()
    }

    private func reload() {
        productsWithQuantityController?.clearAndLoadFirstPage()
        //        addEditInventoryItemControllerManager?.controller?.clear()

    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        // not used
    }
    
    func onTopBarTitleTap() {
        onExpand(false)
        topQuickAddControllerManager?.controller?.onClose()
        expandDelegate?.setExpanded(false)
    }
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Add:
            QL4("Outdated implementation - to add products to inventory we now have to fetch store product (to get the price)")
//            if let inventory = inventory {
//                Providers.inventoryItemsProvider.countInventoryItems(inventory, successHandler {[weak self] count in
//                    if let weakSelf = self {
//                        SizeLimitChecker.checkInventoryItemsSizeLimit(weakSelf.productsWithQuantityController.models.count, controller: weakSelf) {
//                            self?.sendActionToTopController(.Add)
//                        }
//                    }
//                })
//            } else {
//                print("InventoryItemsController.onTopBarButtonTap: No inventory")
//            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            toggleEditing()
        default: QL4("Not handled: \(buttonId)")
        }
    }
    
    private func toggleTopAddController(rotateTopBarButton: Bool = true) {
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            topQuickAddControllerManager?.controller?.onClose()
            
            topBar.setLeftButtonIds([.Edit])
            
            if rotateTopBarButton {
//                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            
            func open() {
                topQuickAddControllerManager?.expand(true)
                topQuickAddControllerManager?.controller?.initContent()
                
                topBar.setLeftButtonIds([])
                
                if rotateTopBarButton {
//                    topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
                }
            }
            
            let alreadyShowedPopup: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.showedAddDirectlyToInventoryHelp) ?? false
            if alreadyShowedPopup {
                open()
            } else {
                AlertPopup.show(title: "Info", message: "Inventory items added here will be added to your history and stats, like when tapping 'buy' in the cart.", controller: self, okMsg: "Got it!") {
                    PreferencesManager.savePreference(PreferencesManagerKey.showedAddDirectlyToInventoryHelp, value: true)
                    open()
                }
            }
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
//            topBar.setRightButtonIds([.ToggleOpen])
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
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        QL4("Outdated implementation, needs now store product")
//        if let inventory = inventory {
//            Providers.listItemGroupsProvider.groupItems(group, successHandler {[weak self] groupItems in
//                if let weakSelf = self {
//                    let inventoryItemsInput = groupItems.map{ProductWithQuantityInput(product: $0.product, quantity: $0.quantity)}
//                    Providers.inventoryItemsProvider.addToInventory(inventory, itemInputs: inventoryItemsInput, remote: true, weakSelf.successHandler{[weak self] inventoryItems in
//                        self?.productsWithQuantityController?.addOrIncrementUI(inventoryItems.map{ProductWithQuantityInv(inventoryItem: $0.inventoryItem)})
//                    })
//                }
//            })
//        }
    }
    
    func onAddProduct(product: Product) {
        QL4("Outdated implementation, needs now store product")
//        if let inventory = inventory {
//            let productInput = ProductWithQuantityInput(product: product, quantity: 1)
//            Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: productInput, remote: true, successHandler{[weak self] addedIem in
//                self?.productsWithQuantityController?.addOrIncrementUI(ProductWithQuantityInv(inventoryItem: addedIem.inventoryItem))
//            })
//        }
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        QL4("Outdated implementation, needs now store product")
        
//        func onEditListItem(input: ListItemInput, editingItem: InventoryItem) {
//            let updatedCategory = editingItem.product.category.copy(name: input.section, color: input.sectionColor)
//            let updatedProduct = editingItem.product.copy(name: input.name, category: updatedCategory, brand: input.brand)
//            // TODO! calculate quantity delta correctly?
//            let updatedInventoryItem = editingItem.copy(quantity: input.quantity, quantityDelta: input.quantity, product: updatedProduct)
//            Providers.inventoryItemsProvider.updateInventoryItem(updatedInventoryItem, remote: true, successHandler {[weak self] in
//                self?.onInventoryItemUpdated()
//            })
//        }
//        
//        func onAddListItem(input: ListItemInput) {
//            if let inventory = inventory {
//                let input = InventoryItemInput(name: input.name, quantity: input.quantity, price: input.price, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
//                
//                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, self.successHandler{[weak self] (inventoryItemWithHistoryEntry: InventoryItemWithHistoryEntry) in
//                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
//                    self?.reload()
//                    
//                    self?.toggleTopAddController()
//                })
//            } else {
//                QL4("Inventory isn't set, can't add item")
//            }
//        }
//        
//        if let editingItem = editingItem as? InventoryItem {
//            onEditListItem(input, editingItem: editingItem)
//        } else {
//            if editingItem == nil {
//                onAddListItem(input)
//            } else {
//                QL4("Cast didn't work: \(editingItem)")
//            }
//        }
    }
    
    func onQuickListOpen() {
//        topBar.setBackVisible(false)
//        topBar.setLeftButtonModels([])
//        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
    }
    
    func onAddProductOpen() {
//        topBar.setBackVisible(false)
//        topBar.setLeftButtonModels([])
//        topBar.setRightButtonModels([
//            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//        ])
    }
    
    func onAddGroupOpen() {
//        topBar.setBackVisible(false)
//        topBar.setLeftButtonModels([])
//        topBar.setRightButtonModels([
//            TopBarButtonModel(buttonId: .Add),
//            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//        ])
    }
    
    func onAddGroupItemsOpen() {
//        topBar.setBackVisible(true)
//        topBar.setLeftButtonModels([])
//        topBar.setRightButtonModels([
//            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//        ])
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
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

        func increment() {
            Providers.inventoryItemsProvider.incrementInventoryItem((model as! ProductWithQuantityInv).inventoryItem, delta: delta, successHandler({result in
                onSuccess()
            }))
        }
        
        let alreadyShowedPopup: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.showedIncrementInventoryItemHelp) ?? false
        if alreadyShowedPopup {
            increment()
            
        } else {
            if delta > 0 { // positive increment - show info
                AlertPopup.show(title: "Info", message: "Incrementing inventory items does NOT affect history and stats.", controller: self, okMsg: "Got it!") {[weak self] in guard let weakSelf = self else {return}
                    PreferencesManager.savePreference(PreferencesManagerKey.showedIncrementInventoryItemHelp, value: true)
                    Providers.inventoryItemsProvider.incrementInventoryItem((model as! ProductWithQuantityInv).inventoryItem, delta: delta, weakSelf.successHandler({result in
                        increment()
                    }))
                }
            } else {
                increment()
            }
        }
    }
    
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath) {
        if productsWithQuantityController.editing {
            let inventoryItem = (model as! ProductWithQuantityInv).inventoryItem

            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: inventoryItem))
            
//            topBar.setRightButtonModels([
//                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
//            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: "You inventory is empty", text2: "To add items, tap on 'buy' in the cart.", imgName: "empty_shelf")
    }
    
    func onEmptyViewTap() {
//        toggleTopAddController()
    }
    
    func onTableViewScroll(scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    func indexPathOfItem(model: ProductWithQuantityInv) -> NSIndexPath? {
        let models = productsWithQuantityController.models as! [ProductWithQuantityInv]
        for i in 0..<models.count {
            if models[i].same(model) {
                return NSIndexPath(forRow: i, inSection: 0)
            }
        }
        return nil
    }
    
    func isPullToAddEnabled() -> Bool {
        return false
    }
    
    func onPullToAdd() {
        toggleTopAddController(false)
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
                    
                default: break
                    
                }
            } else {
                print("Error: ViewController.onWebsocketInventory: no userInfo")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {

                case .Delete:
                    let inventoryUuid = notification.obj
                    if let inventory = inventory {
                        
                        if inventory.uuid == inventoryUuid {
                            AlertPopup.show(title: "Inventory deleted", message: "The inventory \(inventory.name) was deleted from another device. Returning to inventories.", controller: self, onDismiss: {[weak self] in
                                self?.navigationController?.popViewControllerAnimated(true)
                            })
                        } else {
                            QL1("Websocket: Inventory items controller received a notification to delete an inventory which is not the one being currently shown")
                        }
                    } else {
                        QL4("Websocket: Can't process delete inventory notification because there's no inventory set")
                    }
                    
                default: print("Error: InventoryItemsViewController.onWebsocketInventory: not implemented: \(notification.verb)")
                    
                }
            } else {
                print("Error: ViewController.onWebsocketInventory: no userInfo")
            }
        }
    }
    
    func onWebsocketInventoryItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ItemIncrement>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Add:
                    let incr = notification.obj
                    if let inventoryItemModels = productsWithQuantityController?.models as? [ProductWithQuantityInv] {
                        if let inventoryItemModel = (inventoryItemModels.findFirst{$0.inventoryItem.uuid == incr.itemUuid}) {
                            productsWithQuantityController?.updateIncrementUI(ProductWithQuantityInv(inventoryItem: inventoryItemModel.inventoryItem), delta: incr.delta)
                            
                        } else {
                            QL3("Didn't find inventory item, can't increment") // this is not forcibly an error, it can be e.g. that user just removed the item
                        }
                        
                        
                    } else {
                        QL4("Couldn't cast models to [ProductWithQuantityInv]")
                    }

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
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<[InventoryItem]>> {
            
            if let notification = info[WSNotificationValue] {
                
                switch notification.verb {
                case .Add:
//                    let inventoryItems = notification.obj
                    reload()
                    
                    // TODO? increment is covered in onWebsocketInventoryItems, but user can e.g. change name (update of product in this case, but still triggered from inventory...)
                    
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryItem: not implemented: \(notification.verb)")
                }
                
            } else {
                print("Error: InventoryItemsViewController.onWebsocketUpdateListItem: no value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<InventoryItem>> {
            
            if let notification = info[WSNotificationValue] {
                
                switch notification.verb {
                case .Update:
//                    let inventoryItem = notification.obj
                    reload()
                    
                    // TODO? increment is covered in onWebsocketInventoryItems, but user can e.g. change name (update of product in this case, but still triggered from inventory...)
                    
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryItem: not implemented: \(notification.verb)")
                }
                
            } else {
                print("Error: InventoryItemsViewController.onWebsocketUpdateListItem: no value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let inventoryItemUuid = notification.obj
                
                switch notification.verb {
                case .Delete:
                    if let model = ((productsWithQuantityController.models as! [ProductWithQuantityInv]).filter{$0.inventoryItem.uuid == inventoryItemUuid}).first {
                        if let indexPath = indexPathOfItem(model) {
                            productsWithQuantityController.removeItemUI(indexPath)
                        } else {
                            QL2("Group item to remove is not in table view: \(inventoryItemUuid)")
                        }
                    } else {
                        QL3("Received notification to remove inventory item but it wasn't in table view. Uuid: \(inventoryItemUuid)")
                    }
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<ItemIncrement>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Increment:
                    let incr = notification.obj
                    if let inventoryItemModels = productsWithQuantityController?.models as? [ProductWithQuantityInv] {
                        if let inventoryItemModel = (inventoryItemModels.findFirst{$0.inventoryItem.uuid == incr.itemUuid}) {
                            productsWithQuantityController?.updateIncrementUI(ProductWithQuantityInv(inventoryItem: inventoryItemModel.inventoryItem), delta: incr.delta)
                            
                        } else {
                            QL3("Didn't find inventory item, can't increment") // this is not forcibly an error, it can be e.g. that user just removed the item
                        }

                    } else {
                        QL4("Couldn't cast models to [ProductWithQuantityInv]")
                    }
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
            }
        } else {
            QL4("No userInfo")
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
                    reload()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    reload()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProductCategory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    reload()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    reload()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        reload()
    }
}
