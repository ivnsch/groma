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

class ProductWithQuantityGroup: ProductWithQuantity {
    let groupItem: GroupItem
    
    override var product: Product {
        return groupItem.product
    }
    
    override var quantity: Int {
        return groupItem.quantity
    }
    
    func same(rhs: ProductWithQuantityGroup) -> Bool {
        return groupItem.same(rhs.groupItem)
    }
    
    init(groupItem: GroupItem) {
        self.groupItem = groupItem
    }
    override func incrementQuantityCopy(delta: Int) -> ProductWithQuantity {
        let incrementedItem = groupItem.incrementQuantityCopy(delta)
        return ProductWithQuantityGroup(groupItem: incrementedItem)
    }
    
    override func updateQuantityCopy(quantity: Int) -> ProductWithQuantity {
        let udpatedItem = groupItem.copy(quantity: quantity)
        return ProductWithQuantityGroup(groupItem: udpatedItem)
    }
}

class GroupItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    var group: ListItemGroup? {
        didSet {
            if let group = group {
                topBar.title = group.name
            }
        }
    }
    
    weak var expandDelegate: Foo?
    
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    private weak var productsWithQuantityController: ProductsWithQuantityViewController!
    
    private var updatingGroupItem: GroupItem?
    
    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroupItem(_:)), name: WSNotificationName.GroupItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroupItems(_:)), name: WSNotificationName.GroupItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onWebsocketProduct(_:)), name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onWebsocketProductCategory(_:)), name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroup(_:)), name: WSNotificationName.Group.rawValue, object: nil)
    }
    
    deinit {
        QL1("Deinit group items controller")
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
            SizeLimitChecker.checkGroupItemsSizeLimit(productsWithQuantityController.models.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.Add)
                }
            }
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
            
            setDefaultLeftButtons()
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            }
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent()
            
            topBar.setLeftButtonIds([])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
            }
        }
    }
    
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
        topControlTopConstraint.constant = view.frame.height
        productsWithQuantityController?.topMenusHeightConstraint.constant = expand ? 0 : DimensionsManager.topMenuBarHeight
        self.view.layoutIfNeeded()
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let currentGroup = self.group {
            Providers.listItemGroupsProvider.addGroupItems(group, targetGroup: currentGroup, remote: true, resultHandler(onSuccess: {[weak self] groupItemsWithDelta in
                let groupItems = groupItemsWithDelta.map{$0.groupItem}
                self?.addOrUpdateUI(groupItems)
                if let firstGroupItem = groupItemsWithDelta.first {
                    self?.productsWithQuantityController.scrollToItem(ProductWithQuantityGroup(groupItem: firstGroupItem.groupItem))
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
        if let group = group {
            // TODO don't create group item here we don't know if it exists in the group already, if it does the new uuid is not used. Use a prototype class like in list items.
            let groupItem = GroupItem(uuid: NSUUID().UUIDString, quantity: 1, product: product, group: group)
            
            Providers.listItemGroupsProvider.add(groupItem, remote: true, successHandler{[weak self] addedItem in
                self?.productsWithQuantityController?.addOrUpdateUI(ProductWithQuantityGroup(groupItem: addedItem), scrollToCell: true)
            })
        }
    }
    
    private func addOrUpdateUI(items: [GroupItem]) {
        productsWithQuantityController?.addOrUpdateUI(items.map{
            return ProductWithQuantityGroup(groupItem: $0)
        })
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        
        func onEditItem(input: ListItemInput, editingItem: GroupItem) {
            Providers.listItemGroupsProvider.update(input, updatingGroupItem: editingItem, remote: true, resultHandler (onSuccess: {[weak self] (inventoryItem, replaced) in
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
        
        func onAddItem(input: ListItemInput) {
            if let group = group {
                let groupItemInput = GroupItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
                Providers.listItemGroupsProvider.add(groupItemInput, group: group, remote: true, resultHandler (onSuccess: {[weak self] groupItem in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end.
                    self?.reload()
                    self?.closeTopController()
                }, onError: {[weak self] result in
                    self?.reload()
                    self?.closeTopController()
                    self?.defaultErrorHandler()(providerResult: result)
                }))
            } else {
                QL4("Group isn't set, can't add item")
            }
        }
        
        if let editingItem = editingItem as? GroupItem {
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
        reload()
    }
    
    func onRemovedBrand(name: String) {
        reload()
    }
    
    func appendItemUI(item: GroupItem) {
        productsWithQuantityController.appendItemUI(ProductWithQuantityGroup(groupItem: item), scrollToCell: false)
    }
    
    func updateItemUI(item: GroupItem) -> Bool {
        return productsWithQuantityController.updateModelUI({($0 as! ProductWithQuantityGroup).groupItem.same(item)}, updatedModel: ProductWithQuantityGroup(groupItem: item))
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
        if let group = group {
            Providers.listItemGroupsProvider.groupItems(group, sortBy: sortBy, fetchMode: .Both, successHandler{groupItems in
                let productsWithQuantity = groupItems.map{ProductWithQuantityGroup(groupItem: $0)}
                onSuccess(productsWithQuantity)
            })
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func remove(model: ProductWithQuantity, onSuccess: VoidFunction, onError: ProviderResult<Any> -> Void) {
        Providers.listItemGroupsProvider.remove((model as! ProductWithQuantityGroup).groupItem, remote: true, resultHandler(onSuccess: {
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }
    
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: Int -> Void) {
        Providers.listItemGroupsProvider.increment((model as! ProductWithQuantityGroup).groupItem, delta: delta, remote: true, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath) {
        if productsWithQuantityController.editing {
            let groupItem = (model as! ProductWithQuantityGroup).groupItem
            updatingGroupItem = groupItem
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: groupItem))
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: trans("empty_group_line1"), text2: trans("empty_group_line2"), imgName: "empty_page")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
    }
    
    func onTableViewScroll(scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(0, topBar: topBar, scrollView: scrollView)
    }
    
    func isPullToAddEnabled() -> Bool {
        return true
    }
    
    func onPullToAdd() {
        toggleTopAddController(false)
    }
    
    func indexPathOfItem(model: ProductWithQuantityGroup) -> NSIndexPath? {
        let models = productsWithQuantityController.models as! [ProductWithQuantityGroup]
        for i in 0..<models.count {
            if models[i].same(model) {
                return NSIndexPath(forRow: i, inSection: 0)
            }
        }
        return nil
    }
    
    func onEmpty(empty: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.Edit])
        }
    }
    
    // MARK: - Websocket // TODO websocket group items?
    
    func onWebsocketGroupItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<GroupItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    // Update if item is in tableview, if it's not append at the end if we already scrolled until the last page. If we are not in last page and item is not in table view, it means it will appear when we load more pages so we don't have to do anything here for this case.
                    if !updateItemUI(notification.obj) {
                        if productsWithQuantityController.paginator.reachedEnd {
                           appendItemUI(notification.obj)
                        }
                    }
                case .Update:
                    updateItemUI(notification.obj)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let groupItemUuid = notification.obj
                
                switch notification.verb {
                case .Delete:
                    if let model = ((productsWithQuantityController.models as! [ProductWithQuantityGroup]).filter{$0.groupItem.uuid == groupItemUuid}).first {
                        if let indexPath = indexPathOfItem(model) {
                            productsWithQuantityController.removeItemUI(indexPath)
                        } else {
                            QL2("Group item to remove is not in table view: \(groupItemUuid)")
                        }

                    } else {
                        QL3("Received notification to remove group item but it wasn't in table view. Uuid: \(groupItemUuid)")
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
                    if let groupItemModels = productsWithQuantityController?.models as? [ProductWithQuantityGroup] {
                        if let groupItemModel = (groupItemModels.findFirst{$0.groupItem.uuid == incr.itemUuid}) {
                            productsWithQuantityController?.updateIncrementUI(ProductWithQuantityGroup(groupItem: groupItemModel.groupItem), delta: incr.delta)
                            
                        } else {
                            QL3("Didn't find group item, can't increment") // this is not forcibly an error, it can be e.g. that user just removed the item
                        }
                        
                    } else {
                        QL4("Couldn't cast models to [ProductWithQuantityGroup]")
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
    
    
    func onWebsocketGroupItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[GroupItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Add:
                    let groupItems = notification.obj
                    addOrUpdateUI(groupItems)
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("N value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketGroup(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Delete:
                    let groupUuid = notification.obj
                    if let group = group {
                        
                        if group.uuid == groupUuid {
                            AlertPopup.show(title: trans("popup_title_group_deleted"), message: trans("popup_group_was_deleted_in_other_device", group.name), controller: self, onDismiss: {[weak self] in
                                self?.navigationController?.popViewControllerAnimated(true)
                                })
                        } else {
                            QL1("Websocket: Group items controller received a notification to delete a group which is not the one being currently shown")
                        }
                    } else {
                        QL4("Websocket: Can't process delete group notification because there's no group set")
                    }
                default: break
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("No userInfo")
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
