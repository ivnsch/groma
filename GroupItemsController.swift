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

class GroupItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    var group: ProductGroup? {
        didSet {
            if let group = group {
                topBar.title = group.name
            }
        }
    }
    
    weak var expandDelegate: Foo?
    
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    fileprivate weak var productsWithQuantityController: ProductsWithQuantityViewController!
    
    fileprivate var updatingGroupItem: GroupItem?
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    fileprivate var results: Results<GroupItem>?
    fileprivate var notificationToken: NotificationToken?
    fileprivate var submittedAddOrEdit: (add: Bool, edit: Bool) = (false, false) // to know if the (this) user submitted add/edit in order to close the top controller when receiving the realm notification
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
    }
    
    deinit {
        logger.v("Deinit group items controller")
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
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] _ in
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
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)), endTransform: CGAffineTransform.identity)])
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
            SizeLimitChecker.checkGroupItemsSizeLimit(productsWithQuantityController.models.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.add)
                }
            }
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
            
            setDefaultLeftButtons()
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)), endTransform: CGAffineTransform.identity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            toggleButtonRotator.enabled = true
            topQuickAddControllerManager?.controller?.initContent()
            
            topBar.setLeftButtonIds([])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))])
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
        if productsWithQuantityController.models.isEmpty {
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
        if let currentGroup = self.group {
            Prov.listItemGroupsProvider.addGroupItems(group, targetGroup: currentGroup, remote: true, resultHandler(onSuccess: {groupItemsWithDelta in
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
    
    internal func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
        fatalError("Not supported") // It doesn't make sense to add recipes to groups
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        // TODO!!!!!!!!!!!!!!!!! disable recipes from quick add
        fatalError("Not supported") // It doesn't make sense to add recipes to groups
    }
    
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, note: String?, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        if let group = group {
            // TODO don't create group item here we don't know if it exists in the group already, if it does the new uuid is not used. Use a prototype class like in list items.
            let groupItem = GroupItem(uuid: UUID().uuidString, quantity: quantity, product: product, group: group)
            
            Prov.listItemGroupsProvider.add(groupItem, remote: true, successHandler{addedItem in
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
        
        func onEditItem(_ input: ListItemInput, editingItem: GroupItem) {
            submittedAddOrEdit.edit = true
            Prov.listItemGroupsProvider.update(input, updatingGroupItem: editingItem, remote: true, resultHandler (onSuccess: {(inventoryItem, replaced) in
            }, onError: {[weak self] result in
                self?.defaultErrorHandler()(result)
            }))
        }
        
        func onAddItem(_ input: ListItemInput) {
            if let group = group {
                let groupItemInput = GroupItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
                submittedAddOrEdit.add = true
                Prov.listItemGroupsProvider.add(groupItemInput, group: group, remote: true, resultHandler (onSuccess: {groupItem in
                }, onError: {[weak self] result in
                    self?.closeTopController()
                    self?.defaultErrorHandler()(result)
                }))
            } else {
                logger.e("Group isn't set, can't add item")
            }
        }
        
        if let editingItem = editingItem as? GroupItem {
            onEditItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddItem(input)
            } else {
                logger.e("Cast didn't work: \(String(describing: editingItem))")
            }
        }
    }
    
    func onSubmitAddEditItem2(_ input: ListItemInput, editingItem: Any?, onFinish: ((QuickAddItem, Bool) -> Void)?) {
        logger.e("Not implemented")
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
        productsWithQuantityController.load()
    }
    
    func onRemovedBrand(_ name: String) {
        productsWithQuantityController.load()
    }
    
    func onFinishAddCellAnimation(addedItem: AnyObject) {
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
        if let group = group {
            Prov.listItemGroupsProvider.groupItems(group, sortBy: sortBy, fetchMode: .both, successHandler{[weak self] groupItems in guard let weakSelf = self else {return}
                
                weakSelf.results = groupItems
                onSuccess(groupItems.toArray()) // TODO! productsWithQuantityController should load also lazily
                
//                weakSelf.productsWithQuantityController.models = weakSelf.results?.toArray() ?? [] // TODO!! use generic Results in productsWithQuantityController to not have to map to array
                
                weakSelf.notificationToken = weakSelf.results?.observe { changes in
                    switch changes {
                    case .initial:
                        //                        // Results are now populated and can be accessed without blocking the UI
                        //                        self.viewController.didUpdateList(reload: true)
                        logger.v("initial")
                        
                    case .update(_, let deletions, let insertions, let modifications):
                        logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                        
                        weakSelf.productsWithQuantityController.tableView.beginUpdates()
                        
                        weakSelf.productsWithQuantityController.models = groupItems.toArray() // TODO! productsWithQuantityController should load also lazily
                        
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
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func remove(_ model: ProductWithQuantity2, index: Int, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        Prov.listItemGroupsProvider.remove(model as! GroupItem, remote: true, resultHandler(onSuccess: {
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }
    
    func increment(_ model: ProductWithQuantity2, delta: Float, onSuccess: @escaping (Float) -> Void) {
        Prov.listItemGroupsProvider.increment(model as! GroupItem, delta: delta, remote: true, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(_ model: ProductWithQuantity2, indexPath: IndexPath) {
        if productsWithQuantityController.isEditing {
            let groupItem = model as! GroupItem
            updatingGroupItem = groupItem
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: groupItem))
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(Double.pi / 4)))
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
        for i in 0..<productsWithQuantityController.models.count {
            if productsWithQuantityController.same(productsWithQuantityController.models[i], model) {
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
}
