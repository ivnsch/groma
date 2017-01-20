//
//  IngredientsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 17/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import ChameleonFramework
import SwiftValidator
import QorumLogs
import RealmSwift
import Providers

class IngredientsController: UIViewController, ProductsWithQuantityViewControllerDelegateNew, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    var recipe: Recipe? {
        didSet {
            if let recipe = recipe {
                topBar.title = recipe.name
            }
        }
    }
    
    weak var expandDelegate: Foo?
    
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    fileprivate weak var productsWithQuantityController: ProductsWithQuantityViewControllerNew!
    
    fileprivate var updatingIngredient: Ingredient?
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()
    
    fileprivate var itemsResult: Results<Ingredient>?
    fileprivate var notificationToken: NotificationToken?
    fileprivate var submittedAddOrEdit: (add: Bool, edit: Bool) = (false, false) // to know if the (this) user submitted add/edit in order to close the top controller when receiving the realm notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewControllerNew()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
    }
    
    deinit {
        QL1("Deinit ingredients controller")
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
        guard let itemsResult = itemsResult else {QL4("No result"); return}

        switch buttonId {
        case .add:
            // TODO!!!!!!!!!!!!!!!! disable all size limit checks
            SizeLimitChecker.checkGroupItemsSizeLimit(itemsResult.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.add)
                }
            }
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
            
            setDefaultLeftButtons()
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            toggleButtonRotator.enabled = true
            topQuickAddControllerManager?.controller?.initContent()
            
            topBar.setLeftButtonIds([])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))])
            }
        }
    }
    
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
        guard let itemsResult = itemsResult else {QL4("No result"); return}

        if itemsResult.isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        // Fix top line looks slightly thicker after animation. Problem: We have to animate to min scale of 0.0001 because 0 doesn't work correctly (iOS bug) so the frame height passed here is not exactly 0, which leaves a little gap when we set it in the constraint
        topControlTopConstraint.constant = view.frame.height
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
        // TODO!!!!!!!!!!!!!!! quick add should now use recipes not groups. Then re-enable this
//        if let currentGroup = self.group {
//            Prov.listItemGroupsProvider.addGroupItems(group, targetGroup: currentGroup, remote: true, resultHandler(onSuccess: {groupItemsWithDelta in
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
    
    func onAddProduct(_ product: QuantifiableProduct) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let recipe = recipe else {QL4("No recipe"); return}
        
        Prov.ingredientProvider.add(product, quantity: 1, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, successHandler{addedItem in
            
//            self.models.insert(ExpandableTableViewRecipeModel(recipe: recipe), at: results.count)
            if addedItem.isNew {
                self.productsWithQuantityController.insert(item: addedItem.ingredient, scrollToRow: true)
            } else {
                if let index = itemsResult.index(of: addedItem.ingredient) { // we could derive "isNew" from this but just to be 100% sure we are consistent with logic of provider
                    self.productsWithQuantityController.update(item: addedItem.ingredient, scrollToRow: index)
                } else {
                    QL4("Illegal state: Item is not new (it's an update) but was not found in results")
                }
            }
            
        })
        
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let recipe = recipe else {QL4("No recipe"); return}
        

        func onEditItem(_ input: IngredientInput, editingItem: Ingredient) {
            submittedAddOrEdit.edit = true
            Prov.ingredientProvider.update(editingItem, input: input, ingredients: itemsResult, notificationToken: notificationToken, successHandler{(inventoryItem, replaced) in
                print("replaced: \(replaced)") // TODO!!!!!!!!!!!!!!!!! do something with this?
            })
        }
        
        func onAddItem(_ input: IngredientInput) {
            submittedAddOrEdit.add = true
            
            Prov.ingredientProvider.add(input, recipe: recipe, ingredients: itemsResult, notificationToken: notificationToken, resultHandler (onSuccess: {groupItem in
            }, onError: {[weak self] result in
                self?.closeTopController()
                self?.defaultErrorHandler()(result)
            }))
        }
        
        let input = IngredientInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand, unit: input.storeProductInput.unit, baseQuantity: input.storeProductInput.baseQuantity)

        if let editingItem = editingItem as? Ingredient {
            onEditItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddItem(input)
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
        Prov.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
        productsWithQuantityController.load()
    }
    
    func onRemovedBrand(_ name: String) {
        productsWithQuantityController.load()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "productsWithQuantityControllerSegue" {
            productsWithQuantityController = segue.destination as? ProductsWithQuantityViewControllerNew
            productsWithQuantityController?.delegate = self
        }
    }
    
    
    // MARK: - ProductsWithQuantityViewControllerDelegateNew
    
    // TODO use realm correctly - lazy loading instead of mapping to models?
    func loadModels(sortBy: InventorySortBy, onSuccess: @escaping () -> Void) {
        
        guard let recipe = recipe else {QL4("No recipe"); return}
        
        Prov.ingredientProvider.ingredients(recipe: recipe, sortBy: sortBy, successHandler {[weak self] ingredients in guard let weakSelf = self else {return}
            
            weakSelf.itemsResult = ingredients
            
            weakSelf.notificationToken = weakSelf.itemsResult?.addNotificationBlock {[weak self] changes in guard let weakSelf = self else {return}
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    QL1("initial")
//                    weakSelf.productsWithQuantityController.reload()
//                    
                    onSuccess() // TODO! productsWithQuantityController should load also lazily
                    
                    
                case .update(_, let deletions, let insertions, let modifications):
                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                    
                    onSuccess() // TODO! productsWithQuantityController should load also lazily
                    
                    
                    
                    weakSelf.productsWithQuantityController.tableView.beginUpdates()
                    
                    //                weakSelf.productsWithQuantityController.models = recipe.ingredients.toArray() // TODO! productsWithQuantityController should load also lazily
                    
                    weakSelf.productsWithQuantityController.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.productsWithQuantityController.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.productsWithQuantityController.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.productsWithQuantityController.tableView.endUpdates()
                    
                    weakSelf.productsWithQuantityController.updateEmptyUI()
                    
                    if !modifications.isEmpty && weakSelf.submittedAddOrEdit.edit == true { // close only if it's an update (of current user) (explicit update, not increment which is internally also an update) (for add user may want to add multiple products)
                        weakSelf.topQuickAddControllerManager?.expand(false)
                        weakSelf.topQuickAddControllerManager?.controller?.onClose()
                    }
                    weakSelf.submittedAddOrEdit = (false, false) // now that we have processed the notification, reset flags
                    
                    if let firstInsertion = insertions.first { // when add, scroll to added item
                        weakSelf.productsWithQuantityController.tableView.scrollToRow(at: IndexPath(row: firstInsertion, section: 0), at: .top, animated: true)
                    }
                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
        })
        
        //                weakSelf.productsWithQuantityController.models = weakSelf.results?.toArray() ?? [] // TODO!! use generic Results in productsWithQuantityController to not have to map to array
        

    }
    
    var itemsCount: Int {
        return itemsResult?.count ?? 0
    }
    
    func itemForRow(row: Int) -> ProductWithQuantity2? {
        return itemsResult?[row]
    }
    
    func remove(_ model: ProductWithQuantity2, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let itemsResult = itemsResult else {QL4("No result"); return}

        Prov.ingredientProvider.delete(model as! Ingredient, ingredients: itemsResult, notificationToken: notificationToken, resultHandler(onSuccess: {
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }
    
    func increment(_ model: ProductWithQuantity2, delta: Int, onSuccess: @escaping (Int) -> Void) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        guard let ingredientsRealm = itemsResult.realm else {QL4("No realm"); return}
        
        Prov.ingredientProvider.increment(model as! Ingredient, quantity: delta, notificationToken: notificationToken, realm: ingredientsRealm, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(_ index: Int) {
        guard let itemsResult = itemsResult else {QL4("No result"); return}

        if productsWithQuantityController.isEditing {
            let ingredient = itemsResult[index]
            updatingIngredient = ingredient
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: ingredient))
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: trans("empty_group_line1"), text2: trans("empty_group_line2"), imgName: "empty_page")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
    }
    
    func onTableViewScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    func isPullToAddEnabled() -> Bool {
        return true
    }
    
    func onPullToAdd() {
        toggleTopAddController(false)
    }
    
    func indexPathOfItem(_ model: ProductWithQuantity2) -> IndexPath? {
        guard let itemsResult = itemsResult else {QL4("No result"); return nil}

        for i in 0..<itemsResult.count {
            if productsWithQuantityController.same(itemsResult[i], model) {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
    }
    
    func onEmpty(_ empty: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    func same(lhs: ProductWithQuantity2, rhs: ProductWithQuantity2) -> Bool {
        return (lhs as! Ingredient).same(rhs as! Ingredient)
    }
}
