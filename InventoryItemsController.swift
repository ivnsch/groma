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
    
    override func updateQuantityCopy(quantity: Int) -> ProductWithQuantity {
        let udpatedItem = inventoryItem.copy(quantity: quantity)
        return ProductWithQuantityInv(inventoryItem: udpatedItem)
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
    
    weak var expandDelegate: Foo?

    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?

    private var productsWithQuantityController: ProductsWithQuantityViewController!

    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketInventory(_:)), name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketInventoryItems(_:)), name: WSNotificationName.InventoryItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketInventoryItem(_:)), name: WSNotificationName.InventoryItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketListItem(_:)), name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketProduct(_:)), name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onWebsocketProductCategory(_:)), name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoryItemsController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
    }
    
    deinit {
        QL1("Deinit inventory items")
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
            topQuickAddControllerManager?.controller?.removeFromParentViewControllerWithView()            
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
        setDefaultLeftButtons()
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        onViewWillAppear?()
        onViewWillAppear = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        toggleButtonRotator.reset(productsWithQuantityController.tableView, topBar: topBar)

        onViewDidAppear?()
        onViewDidAppear = nil
    }
    
    private func toggleEditing() {
        if let productsWithQuantityController = productsWithQuantityController {
            let editing = !productsWithQuantityController.editing // toggle
            productsWithQuantityController.setEditing(editing, animated: true)
        } else {
            print("Warn: InventoryItemsViewController.toggleEditing edit tap but no tableViewController")
        }
    }
    
    func closeTopController() {
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
        back()
    }
    
    func back() {
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
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            
            func open() {
                topQuickAddControllerManager?.expand(true)
                topQuickAddControllerManager?.controller?.initContent()
                
                topBar.setLeftButtonIds([])
                
                if rotateTopBarButton {
                    topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
                }
            }
            
            checkShowAddToInventoryExplanationPopup {
                open()
            }
        }
    }
    
    private func checkShowAddToInventoryExplanationPopup(onContinue: VoidFunction) {
        
        let alreadyShowedPopup: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.showedAddDirectlyToInventoryHelp) ?? false
        if alreadyShowedPopup {
            onContinue()
        } else {
            AlertPopup.show(title: trans("popup_title_info"), message: trans("popup_add_items_directly_inventory"), controller: self, okMsg: trans("popup_button_got_it")) {
                PreferencesManager.savePreference(PreferencesManagerKey.showedAddDirectlyToInventoryHelp, value: true)
                onContinue()
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
            setDefaultLeftButtons()
            topBar.setRightButtonIds([.ToggleOpen])
        }
    }
    
    func setDefaultLeftButtons() {
        if productsWithQuantityController.models.isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.Edit])
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        // Fix top line looks slightly thicker after animation. Problem: We have to animate to min scale of 0.0001 because 0 doesn't work correctly (iOS bug) so the frame height passed here is not exactly 0, which leaves a little gap when we set it in the constraint
        topControlTopConstraint.constant = view.frame.height < 0.1 ? 0 : view.frame.height
        
        productsWithQuantityController?.topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        self.view.layoutIfNeeded()
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.addToInventory(inventory, group: group, remote: true, resultHandler(onSuccess: {[weak self] inventoryItemsWithDelta in
                let inventoryItems = inventoryItemsWithDelta.map{$0.inventoryItem}
                self?.addOrUpdateUI(inventoryItems)
                if let firstInventoryItem = inventoryItemsWithDelta.first {
                    self?.productsWithQuantityController.scrollToItem(ProductWithQuantityInv(inventoryItem: firstInventoryItem.inventoryItem))
                } else {
                    QL3("Shouldn't be here without list items")
                }
            }, onError: {[weak self] result in guard let weakSelf = self else {return}
                switch result.status {
                case .IsEmpty:
                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
                default:
                    self?.defaultErrorHandler()(providerResult: result)
                }
            }))
        }
    }
    
    func onAddProduct(product: Product) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.addToInventory(inventory, product: product, quantity: 1, remote: true, successHandler{[weak self] addedItemWithDelta in
                let addedItem = addedItemWithDelta.inventoryItem
                self?.productsWithQuantityController?.addOrUpdateUI(ProductWithQuantityInv(inventoryItem: addedItem), scrollToCell: true)
            })
        }
    }
    
    private func addOrUpdateUI(items: [InventoryItem]) {
        productsWithQuantityController?.addOrUpdateUI(items.map{
            return ProductWithQuantityInv(inventoryItem: $0)
        })
    }
    
    func updateItemUI(item: InventoryItem) {
        productsWithQuantityController.updateModelUI({($0 as! ProductWithQuantityInv).inventoryItem.same(item)}, updatedModel: ProductWithQuantityInv(inventoryItem: item))
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        
        func onEditListItem(input: ListItemInput, editingItem: InventoryItem) {

            let inventoryItemInput = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
            
            Providers.inventoryItemsProvider.updateInventoryItem(inventoryItemInput, updatingInventoryItem: editingItem, remote: true, resultHandler (onSuccess: {[weak self]  (inventoryItem, replaced) in
                if replaced { // if an item was replaced (means: a previous item with same unique as the updated item already existed and was removed from the inventory) reload items to get rid of it.
                    self?.reload()
                } else {
                    self?.updateItemUI(inventoryItem)
                }
                self?.closeTopController()
            }, onError: {[weak self] result in
                self?.reload()
                self?.defaultErrorHandler()(providerResult: result)
            }))
        }
        
        func onAddInventoryItem(input: ListItemInput) {
            if let inventory = inventory {
                let input = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
                
                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, remote: true, resultHandler (onSuccess: {[weak self] groupItem in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end.
                    self?.reload()
                    self?.closeTopController()
                }, onError: {[weak self] result in
                    self?.reload()
                    self?.closeTopController()
                    self?.defaultErrorHandler()(providerResult: result)
                }))
            } else {
                QL4("Inventory isn't set, can't add item")
            }
        }
        
        if let editingItem = editingItem as? InventoryItem {
            onEditListItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddInventoryItem(input)
            } else {
                QL4("Cast didn't work: \(editingItem)")
            }
        }
    }
    
    func onQuickListOpen() {
    }
    
    func onAddProductOpen() {
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Add),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void) {
        Providers.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(name: String) {
    }
    
    func onRemovedBrand(name: String) {
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
            Providers.inventoryItemsProvider.removeInventoryItem((model as! ProductWithQuantityInv).inventoryItem.uuid, inventoryUuid: inventory.uuid, remote: true, resultHandler(onSuccess: {
                onSuccess()
                }, onError: {result in
                    onError(result)
            }))
        } else {
            print("Error: InventoryItemsController.remove: no inventory")
        }
    }
    
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: Int -> Void) {
        Providers.inventoryItemsProvider.incrementInventoryItem((model as! ProductWithQuantityInv).inventoryItem, delta: delta, remote: true, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath) {
        if productsWithQuantityController.editing {
            let inventoryItem = (model as! ProductWithQuantityInv).inventoryItem

            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: inventoryItem))
            
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: trans("empty_inventory_line1"), text2: trans("empty_inventory_line2"), imgName: "empty_page")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
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
        return true
    }
    
    func onPullToAdd() {
        toggleTopAddController(false)
    }
    
    func onEmpty(empty: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.Edit])
        }
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
                            AlertPopup.show(title: trans("popup_title_inventory_deleted"), message: trans("popup_inventory_was_deleted_in_other_device", inventory.name), controller: self, onDismiss: {[weak self] in
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
            
        // User added/incremented inventory items using the quick add (product or group)
        // Note that we do an update instead of an increment, the reason is simply that the server object doesn't have delta information to do the increment. The only situation where update can cause problems is if we are incrementing the same items when the notification arrives, some of our increments may be overwritten. Not critical. Update has on the other side the advantage that if a message gets lost, when we receive the next the quantity is correctly updated.
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<[InventoryItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Add:
                    let inventoryItems = notification.obj
                    addOrUpdateUI(inventoryItems)
                    
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
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<InventoryItem>> {
            
            if let notification = info[WSNotificationValue] {
                
                switch notification.verb {
                case .Update:
                    updateItemUI(notification.obj)
                    
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
    
    func onWebsocketListItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteBuyCartResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .BuyCart:
                    reload()
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
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
                case .DeleteWithBrand:
                    // we can improve this by at least checking if there's a product that references this brand in the list, for now just reload
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
