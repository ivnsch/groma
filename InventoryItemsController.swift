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
import RealmSwift

class InventoryItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {
    
    fileprivate var inventoryItemsResult: Results<InventoryItem>?
    fileprivate var notificationToken: NotificationToken?
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    var inventory: DBInventory? {
        didSet {
            if let inventory = inventory {
                topBar.title = inventory.name
            }
        }
    }
    
    weak var expandDelegate: Foo?

    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?

    fileprivate var productsWithQuantityController: ProductsWithQuantityViewController!

    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
    }
    
    deinit {
        QL1("Deinit inventory items")
        NotificationCenter.default.removeObserver(self)
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

    func setThemeColor(_ color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.white
    }
    
    fileprivate func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.white
        topBar.addSubview(label)
    }
    
    fileprivate func initTopQuickAddControllerManager(_ tableView: UITableView) -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .planItem
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    func onExpand(_ expanding: Bool) {
        if !expanding {
            productsWithQuantityController?.emptyView.isHidden = true
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
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()        
    }
    
    fileprivate func topBarOnCloseExpandable() {
        setDefaultLeftButtons()
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        onViewWillAppear?()
        onViewWillAppear = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        toggleButtonRotator.reset(productsWithQuantityController.tableView, topBar: topBar)

        onViewDidAppear?()
        onViewDidAppear = nil
    }
    
    fileprivate func toggleEditing() {
        if let productsWithQuantityController = productsWithQuantityController {
            let editing = !productsWithQuantityController.isEditing // toggle
            productsWithQuantityController.setEditing(editing, animated: true)
        } else {
            print("Warn: InventoryItemsViewController.toggleEditing edit tap but no tableViewController")
        }
    }
    
    func closeTopController() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        topBarOnCloseExpandable()
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
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .add:
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
        case .toggleOpen:
            toggleTopAddController()
        case .edit:
            toggleEditing()
        default: QL4("Not handled: \(buttonId)")
        }
    }
    
    fileprivate func toggleTopAddController(_ rotateTopBarButton: Bool = true) {
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            toggleButtonRotator.enabled = true
            topQuickAddControllerManager?.controller?.onClose()
            
            topBar.setLeftButtonIds([.edit])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            
            func open() {
                topQuickAddControllerManager?.expand(true)
                toggleButtonRotator.enabled = false
                topQuickAddControllerManager?.controller?.initContent()
                
                topBar.setLeftButtonIds([])
                
                if rotateTopBarButton {
                    topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))])
                }
            }
            
            checkShowAddToInventoryExplanationPopup {
                open()
            }
        }
    }
    
    fileprivate func checkShowAddToInventoryExplanationPopup(_ onContinue: @escaping VoidFunction) {
        
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
    fileprivate func sendActionToTopController(_ action: FLoatingButtonAction) {
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        }
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
        if center {
            setDefaultLeftButtons()
            topBar.setRightButtonIds([.toggleOpen])
        }
    }
    
    func setDefaultLeftButtons() {
        if productsWithQuantityController.models.isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        // Fix top line looks slightly thicker after animation. Problem: We have to animate to min scale of 0.0001 because 0 doesn't work correctly (iOS bug) so the frame height passed here is not exactly 0, which leaves a little gap when we set it in the constraint
        topControlTopConstraint.constant = view.frame.height < 0.1 ? 0 : view.frame.height
        
        productsWithQuantityController?.topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        self.view.layoutIfNeeded()
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.addToInventory(inventory, group: group, remote: true, resultHandler(onSuccess: {[weak self] inventoryItemsWithDelta in

            }, onError: {[weak self] result in guard let weakSelf = self else {return}
                switch result.status {
                case .isEmpty:
                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
                default:
                    self?.defaultErrorHandler()(result)
                }
            }))
        }
    }
    
    func onAddProduct(_ product: Product) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.addToInventory(inventory, product: product, quantity: 1, remote: true, successHandler{[weak self] addedItemWithDelta in
            })
        }
    }

    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
        func onEditListItem(_ input: ListItemInput, editingItem: InventoryItem) {

            let inventoryItemInput = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
            
            Providers.inventoryItemsProvider.updateInventoryItem(inventoryItemInput, updatingInventoryItem: editingItem, remote: true, resultHandler (onSuccess: {[weak self]  (inventoryItem, replaced) in

            }, onError: {[weak self] result in
                self?.defaultErrorHandler()(result)
            }))
        }
        
        func onAddInventoryItem(_ input: ListItemInput) {
            if let inventory = inventory {
                let input = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
                
                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, remote: true, resultHandler (onSuccess: {[weak self] groupItem in
                }, onError: {[weak self] result in
                    self?.closeTopController()
                    self?.defaultErrorHandler()(result)
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
            TopBarButtonModel(buttonId: .add),
            TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
        ])
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Providers.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
    }
    
    func onRemovedBrand(_ name: String) {
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "productsWithQuantityControllerSegue" {
            productsWithQuantityController = segue.destination as? ProductsWithQuantityViewController
            productsWithQuantityController?.delegate = self
        }
    }
    
    // MARK: - ProductsWithQuantityViewControllerDelegate
    
    func loadModels(_ page: NSRange?, sortBy: InventorySortBy, onSuccess: @escaping ([ProductWithQuantity2]) -> Void) {
        if let inventory = inventory {
            // .MemOnly fetch mode prevents following - when we add items to the inventory and switch to inventory very quickly, the db has not finished writing the items yet! and the load request reads the items from db before the write finishes so if we pass fetchMode .Both, first the mem cache returns the correct items but then the call - to the db - returns still the old items. So we pass mem cache which has the correct state, ignoring the db result.
            Providers.inventoryItemsProvider.inventoryItems(inventory: inventory, fetchMode: .memOnly, sortBy: sortBy, successHandler{[weak self] inventoryItems in guard let weakSelf = self else {return}
                
                weakSelf.inventoryItemsResult = inventoryItems
                onSuccess(inventoryItems.toArray()) // TODO! productsWithQuantityController should load also lazily

                weakSelf.notificationToken = weakSelf.inventoryItemsResult?.addNotificationBlock { changes in
                    
                    switch changes {
                    case .initial:
                        //                        // Results are now populated and can be accessed without blocking the UI
                        //                        self.viewController.didUpdateList(reload: true)
                        QL1("initial")
                        
                    case .update(_, let deletions, let insertions, let modifications):
                        QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                        
                        weakSelf.productsWithQuantityController.tableView.beginUpdates()
                    
                        weakSelf.productsWithQuantityController.models = inventoryItems.toArray() // TODO! productsWithQuantityController should load also lazily
                        
                        weakSelf.productsWithQuantityController.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                        weakSelf.productsWithQuantityController.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                        weakSelf.productsWithQuantityController.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                        weakSelf.productsWithQuantityController.tableView.endUpdates()
                        
                        weakSelf.productsWithQuantityController.updateEmptyUI()
                        
                        // TODO close only when receiving own notification, not from someone else (possible?)
                        if !modifications.isEmpty { // close only if it's an update (for add user may want to add multiple products)
                            weakSelf.topQuickAddControllerManager?.expand(false)
                            weakSelf.topQuickAddControllerManager?.controller?.onClose()
                        }
                        
                        if let firstInsertion = insertions.first { // when add, scroll to added item
                            weakSelf.productsWithQuantityController.tableView.scrollToRow(at: IndexPath(row: firstInsertion, section: 0), at: .top, animated: true)
                        }

                    case .error(let error):
                        // An error occurred while opening the Realm file on the background worker thread
                        fatalError(String(describing: error))
                    }
                }
            })
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func onLoadedModels(_ models: [ProductWithQuantity2]) {
        // TODO is this necessary?
    }
    
    func remove(_ model: ProductWithQuantity2, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        if let inventory = inventory {
            Providers.inventoryItemsProvider.removeInventoryItem((model as! InventoryItem).uuid, inventoryUuid: inventory.uuid, remote: true, resultHandler(onSuccess: {
                onSuccess()
            }, onError: {result in
                onError(result)
            }))
        } else {
            print("Error: InventoryItemsController.remove: no inventory")
        }
    }
    
    func increment(_ model: ProductWithQuantity2, delta: Int, onSuccess: @escaping (Int) -> Void) {
        Providers.inventoryItemsProvider.incrementInventoryItem(model as! InventoryItem, delta: delta, remote: true, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(_ model: ProductWithQuantity2, indexPath: IndexPath) {
        if productsWithQuantityController.isEditing {
            let inventoryItem = model as! InventoryItem

            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: inventoryItem))
            
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: trans("empty_inventory_line1"), text2: trans("empty_inventory_line2"), imgName: "empty_page")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
    }
    
    func onTableViewScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    func indexPathOfItem(_ model: ProductWithQuantity2) -> IndexPath? {
        for i in 0..<productsWithQuantityController.models.count {
            if productsWithQuantityController.same(productsWithQuantityController.models[i], model) {
                return IndexPath(row: i, section: 0)
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
    
    func onEmpty(_ empty: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
}
