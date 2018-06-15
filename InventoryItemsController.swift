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

import RealmSwift
import Providers

// TODO why this doesn't extent ItemsController? don't remember if it's a specific reason or just lack of time
class InventoryItemsController: UIViewController, ProductsWithQuantityViewControllerDelegateNew, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {

    fileprivate var inventoryItemsResult: Results<InventoryItem>? {
        didSet {
            productsWithQuantityController.reload()
            productsWithQuantityController.updateEmptyUI()
        }
    }
    fileprivate var realmData: RealmData?
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    var isEmpty: Bool {
        return inventoryItemsResult?.isEmpty ?? true
    }
    
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

    fileprivate var productsWithQuantityController: ProductsWithQuantityViewControllerNew!
    fileprivate var tableView: UITableView {
        return productsWithQuantityController.tableView
    }
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewControllerNew()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self // NOTE: set before of triggering view load (call viewDidLoad - since this accesses delegate)
        _ = productsWithQuantityController.view // trigger view/outlets load - otherwise `var tableView` here crahes

        initTitleLabel()
        
        topBar.delegate = self
    }
    
    deinit {
        logger.v("Deinit inventory items")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        // add the embedded controller's view
        if productsWithQuantityController.view.superview == nil {
            productsWithQuantityController.view.translatesAutoresizingMaskIntoConstraints = false
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
    
    func initTopQuickAddControllerManager(_ tableView: UITableView) -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .product
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    func onExpand(_ expanding: Bool) {
        if !expanding {
            productsWithQuantityController?.setEmptyUI(true, animated: false)
            topQuickAddControllerManager?.controller?.removeFromParentViewControllerWithView()            
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
            // Clear memory cache when we leave controller. This is not really necessary but just "in case". The memory cache is there to smooth things *inside* an inventory, Basically quick adding/incrementing.
            Prov.inventoryItemsProvider.invalidateMemCache()
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
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)), endTransform: CGAffineTransform.identity)])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        onViewWillAppear?()
        onViewWillAppear = nil

        // This has to be after onViewWillAppear so it gets the updated navbar frame height! (which is set in positionTitleLabelLeft...)
        topQuickAddControllerManager = initTopQuickAddControllerManager(tableView)
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
            logger.e("Outdated implementation - to add products to inventory we now have to fetch store product (to get the price)")
//            if let inventory = inventory {
//                Prov.inventoryItemsProvider.countInventoryItems(inventory, successHandler {[weak self] count in
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
        default: logger.e("Not handled: \(buttonId)")
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
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)), endTransform: CGAffineTransform.identity)])
            }

        } else { // if there's no top controller open, open the quick add controller
            
            func open() {
                topQuickAddControllerManager?.expand(true)
                toggleButtonRotator.enabled = false
                topQuickAddControllerManager?.controller?.initContent()
                
                topBar.setLeftButtonIds([])
                
                if rotateTopBarButton {
                    topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))])
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
            MyPopupHelper.showPopup(parent: self, type: .info, message: trans("popup_add_items_directly_inventory"), okText: trans("popup_button_got_it"), onOk: {
                PreferencesManager.savePreference(PreferencesManagerKey.showedAddDirectlyToInventoryHelp, value: true)
                onContinue()
            })
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
        if inventoryItemsResult?.isEmpty ?? true {
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
        // Outdated
//        if let inventory = inventory {
//            Prov.inventoryItemsProvider.addToInventory(inventory, group: group, remote: true, resultHandler(onSuccess: {inventoryItemsWithDelta in
//
//            }, onError: {[weak self] result in guard let weakSelf = self else {return}
//                switch result.status {
//                case .isEmpty:
//                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
//                default:
//                    self?.defaultErrorHandler()(result)
//                }
//            }))
//        }
    }
    
    internal func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], recipeData: RecipeData, quickAddController: QuickAddViewController) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
         fatalError("Not supported") // It doesn't make sense to add recipes to the inventory
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
        fatalError("Not supported") // It doesn't make sense to add recipes to the inventory
    }
    
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, note: String?, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        if let inventory = inventory {
            Prov.inventoryItemsProvider.addToInventory(inventory, product: product, quantity: quantity, remote: true, realmData: realmData, successHandler{[weak self] addedItem in guard let weakSelf = self else {return}
                
                onAddToProvider(QuickAddAddProductResult(isNewItem: addedItem.isNew))
                
                guard let itemIndex = inventoryItemsResult.index(of: addedItem.inventoryItem) else {
                    logger.e("Illegal state: Just added/updated item but didn't find it in results")
                    return
                }
                
                let finalItemIndex = weakSelf.productsWithQuantityController.explanationManager.showExplanation ? itemIndex + 1 : itemIndex
                let indexPath = IndexPath(row: finalItemIndex, section: 0)

                if addedItem.isNew {
                    self?.productsWithQuantityController.placeHolderItem = (indexPath: indexPath, item: addedItem.inventoryItem)
                    self?.tableView.insertRows(at: [indexPath], with: Theme.defaultRowAnimation)
                    self?.productsWithQuantityController.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    
                } else { // update
                    self?.update(item: addedItem.inventoryItem, scrollToRow: indexPath.row)
                }
                
                self?.productsWithQuantityController.updateEmptyUI()
            })
        }
    }
    
    func onAddItem(_ item: Item) {
        // Do nothing - No Item quick add in this controller
    }
    
    
    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs) {
        // Do nothing - No ingredients in this controller
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}

        func onEditListItem(_ input: ListItemInput, editingItem: InventoryItem) {

            let inventoryItemInput = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand, baseQuantity: input.storeProductInput.baseQuantity, secondBaseQuantity: input.storeProductInput.secondBaseQuantity, unit: input.storeProductInput.unit, edible: input.edible)
            
            Prov.inventoryItemsProvider.updateInventoryItem(inventoryItemInput, updatingInventoryItem: editingItem, remote: true, realmData: realmData, resultHandler (onSuccess: {[weak self] updateResult in
                if updateResult.replaced {
                    self?.tableView.reloadData()
                } else {
                    self?.update(item: updateResult.inventoryItem, scrollToRow: nil)
                }
                
                self?.closeTopController()
                
            }, onError: {[weak self] result in
                self?.defaultErrorHandler()(result)
            }))
        }
        
        func onAddInventoryItem(_ input: ListItemInput) {
            if let inventory = inventory {
                let input = InventoryItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand, baseQuantity: input.storeProductInput.baseQuantity, secondBaseQuantity: input.storeProductInput.secondBaseQuantity, unit: input.storeProductInput.unit, edible: input.edible)
                
                Prov.inventoryItemsProvider.addToInventory(inventory, itemInput: input, remote: true, realmData: realmData, resultHandler (onSuccess: {addedItem in
                    
                    if addedItem.isNew {
                        self.insert(item: addedItem.inventoryItem, scrollToRow: true)
                        self.productsWithQuantityController.updateEmptyUI()
                        
                    } else {
                        if let index = inventoryItemsResult.index(of: addedItem.inventoryItem) { // we could derive "isNew" from this but just to be 100% sure we are consistent with logic of provider
                            self.update(item: addedItem.inventoryItem, scrollToRow: index)
                        } else {
                            logger.e("Illegal state: Item is not new (it's an update) but was not found in results")
                        }
                    }
                    
                }, onError: {[weak self] result in
                    self?.closeTopController()
                    self?.defaultErrorHandler()(result)
                }))
            } else {
                logger.e("Inventory isn't set, can't add item")
            }
        }
        
        if let editingItem = editingItem as? InventoryItem {
            onEditListItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddInventoryItem(input)
            } else {
                logger.e("Cast didn't work: \(String(describing: editingItem))")
            }
        }
    }
    
    func onSubmitAddEditItem2(_ input: ListItemInput, editingItem: Any?, onFinish: ((QuickAddItem, Bool) -> Void)?) {
        guard let realmData = realmData else {logger.e("No realm data"); return}

        Prov.productProvider.mergeOrCreateProduct(prototype: input.toProductPrototype(), updateCategory: false, updateItem: false, realmData: realmData, successHandler {(quantifiableProduct: QuantifiableProduct, isNew: Bool) in
            let quickAddItem = QuickAddProduct(quantifiableProduct.product, quantifiableProduct: quantifiableProduct)
            onFinish?(quickAddItem, isNew)
        })
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
            TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))
        ])
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Prov.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
    }
    
    func onRemovedBrand(_ name: String) {
    }
    
    func onFinishAddCellAnimation(addedItem: AnyObject) {
        productsWithQuantityController.placeHolderItem = nil
        productsWithQuantityController.tableView.reloadData()
    }
    
    fileprivate func findIndexPathForQuantifiableProduct(quantifiableProduct: QuantifiableProduct) -> IndexPath? {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return nil}
        for (index, item) in inventoryItemsResult.enumerated() {
            if item.product.same(quantifiableProduct) {
                return IndexPath(row: productsWithQuantityController.explanationManager.showExplanation ? index + 1 : index, section: 0)
            }
        }
        return nil
    }
    
    var offsetForAddCellAnimation: CGFloat {
//        return 2 // This table view doesn't have headers, so we theoretically shouldn't need offsetForAddCellAnimation here (it should be 0) but for some reason there are little jumps and this fixes it
        return 0 // It seems this was actually not necessary, review and offsetForAddCellAnimation altogether if it's not
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "productsWithQuantityControllerSegue" {
            productsWithQuantityController = segue.destination as? ProductsWithQuantityViewControllerNew
            productsWithQuantityController?.delegate = self
        }
    }
    
    // MARK: - ProductsWithQuantityViewControllerDelegate
    
    func loadModels(sortBy: InventorySortBy, onSuccess: @escaping () -> Void) {
        
        if let inventory = inventory {
            // .MemOnly fetch mode prevents following - when we add items to the inventory and switch to inventory very quickly, the db has not finished writing the items yet! and the load request reads the items from db before the write finishes so if we pass fetchMode .Both, first the mem cache returns the correct items but then the call - to the db - returns still the old items. So we pass mem cache which has the correct state, ignoring the db result.
            Prov.inventoryItemsProvider.inventoryItems(inventory: inventory, fetchMode: .memOnly, sortBy: sortBy, successHandler{[weak self] inventoryItems in guard let weakSelf = self else {return}
                
                weakSelf.inventoryItemsResult = inventoryItems
                guard let realm = inventoryItems.realm else {logger.e("No realm. Will not init notification token"); return}
        
                weakSelf.realmData?.invalidateTokens()

                let notificationToken = inventoryItems.observe { changes in
                    
                    switch changes {
                    case .initial:
                        //                        // Results are now populated and can be accessed without blocking the UI
                        //                        self.viewController.didUpdateList(reload: true)
                        logger.v("initial")
                        
                    case .update(_, let deletions, let insertions, let modifications):
                        logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                        
                        weakSelf.productsWithQuantityController.tableView.beginUpdates()
                        weakSelf.productsWithQuantityController.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                        weakSelf.productsWithQuantityController.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                        weakSelf.productsWithQuantityController.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                        weakSelf.productsWithQuantityController.tableView.endUpdates()
                        
                        weakSelf.productsWithQuantityController.updateEmptyUI()
                        
                    case .error(let error):
                        // An error occurred while opening the Realm file on the background worker thread
                        fatalError(String(describing: error))
                    }
                }
                
                weakSelf.realmData = RealmData(realm: realm, token: notificationToken)
                
                onSuccess()

            })
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func itemForRow(row: Int) -> ProductWithQuantity2? {
        return inventoryItemsResult?[row]
    }
    
    var itemsCount: Int {
        return inventoryItemsResult?.count ?? 0
    }
    
    func same(lhs: ProductWithQuantity2, rhs: ProductWithQuantity2) -> Bool {
        return (lhs as! InventoryItem).same(rhs as! InventoryItem)
    }
    
    func remove(_ model: ProductWithQuantity2, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        guard let inventory = inventory else {logger.e("No inventory"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}
        guard let indexPath = indexPathOfItem(model) else {logger.e("No index path"); return}
        
        Prov.inventoryItemsProvider.removeInventoryItem((model as! InventoryItem).uuid, inventoryUuid: inventory.uuid, remote: true, realmData: realmData, resultHandler(onSuccess: {[weak self] in
            
            self?.tableView.deleteRows(at: [indexPath], with: Theme.defaultRowAnimation)
            self?.productsWithQuantityController.updateEmptyUI()
            
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }
    
    func onLoadedModels(_ models: [ProductWithQuantity2]) {
        // TODO is this necessary?
    }

    
    func increment(_ model: ProductWithQuantity2, delta: Float, onSuccess: @escaping (Float) -> Void) {
        guard let realmData = realmData else {logger.e("No realm data"); return}

        Prov.inventoryItemsProvider.incrementInventoryItem(model as! InventoryItem, delta: delta, remote: true, realmData: realmData, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
            // TODO!!!!!!!!!!!!! review that increments in ProductsWithQuantityViewControllerNew change the quantity in the cell correctly? such that no updates are necessary here
        }))
    }
    
    func onModelSelected(_ index: Int) {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return}
        
        if productsWithQuantityController.isEditing {
            
            let inventoryItem = inventoryItemsResult[index]
            
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: inventoryItem))
            
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))
            ])
        }
    }

    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: trans("empty_inventory_line1"), text2: trans("empty_inventory_line2"), imgName: "empty_page")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
    }

    
    func onEmpty(_ empty: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    func onTableViewScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    func indexPathOfItem(_ model: ProductWithQuantity2) -> IndexPath? {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return nil}

        for i in 0..<inventoryItemsResult.count {
            if productsWithQuantityController.same(inventoryItemsResult[i], model) {
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

    // MARK: - private

    // Inserts item in table view, considering the current sortBy
    func insert(item: InventoryItem, scrollToRow: Bool) {
        guard let sortBy = productsWithQuantityController.sortBy else {logger.e("No sortby, can't insert!"); return}
        guard let indexPath = findIndexPathForNewItem(item, sortBy: sortBy.value) else {
            logger.v("No index path for: \(item), appending"); return;
        }
        logger.v("Found index path: \(indexPath) for: \(item.product.product.item.name)")
        tableView.insertRows(at: [indexPath], with: .top)
        
        productsWithQuantityController.updateEmptyUI()
        
        if scrollToRow {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // TODO!!!!!!!!!!!!!!!! replace findIndexPathForNewItem in ingredients with this
    /// NOTE: assumes that the item is already in inventoryItemsResult
    fileprivate func findIndexPathForNewItem(_ ingredient: InventoryItem, sortBy: InventorySortBy) -> IndexPath? {
        guard let inventoryItemsResult = inventoryItemsResult else {logger.e("No result"); return nil}
        for (index, item) in inventoryItemsResult.enumerated() {
            if item.same(ingredient) {
                return IndexPath(row: productsWithQuantityController.explanationManager.showExplanation ? index + 1 : index, section: 0)
            }
        }
        return nil
    }
    
    fileprivate func findFirstItem(_ f: (InventoryItem) -> Bool) -> (index: Int, model: InventoryItem)? {
        for itemIndex in 0..<itemsCount {
            guard let item = itemForRow(row: itemIndex) as? InventoryItem else {logger.e("Illegal state: no item for index: \(itemIndex) or wrong type"); return nil}
            if f(item) {
                return (itemIndex, item)
            }
        }
        return nil
    }
    
    func update(item: InventoryItem, scrollToRow index: Int?) {
        tableView.reloadData() // update with quantity change is tricky, since the sorting (by quantity) can cause the item to change positions. So we just reload the tableview
        
        if let index = index {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
}
