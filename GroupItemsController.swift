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
    
    func same(_ rhs: ProductWithQuantityGroup) -> Bool {
        return groupItem.same(rhs.groupItem)
    }
    
    init(groupItem: GroupItem) {
        self.groupItem = groupItem
    }
    override func incrementQuantityCopy(_ delta: Int) -> ProductWithQuantity {
        let incrementedItem = groupItem.incrementQuantityCopy(delta)
        return ProductWithQuantityGroup(groupItem: incrementedItem)
    }
    
    override func updateQuantityCopy(_ quantity: Int) -> ProductWithQuantity {
        let udpatedItem = groupItem.copy(quantity: quantity)
        return ProductWithQuantityGroup(groupItem: udpatedItem)
    }
}

class GroupItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
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
    
    fileprivate weak var productsWithQuantityController: ProductsWithQuantityViewController!
    
    fileprivate var updatingGroupItem: GroupItem?
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroupItem(_:)), name: NSNotification.Name(rawValue: WSNotificationName.GroupItem.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroupItems(_:)), name: NSNotification.Name(rawValue: WSNotificationName.GroupItems.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onWebsocketProduct(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Product.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onWebsocketProductCategory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProductCategory.rawValue), object: nil)        
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupItemsController.onWebsocketGroup(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Group.rawValue), object: nil)
    }
    
    deinit {
        QL1("Deinit group items controller")
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
    
    fileprivate func reload() {
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
    
    func onAddGroup(_ group: ListItemGroup, onFinish: VoidFunction?) {
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
                case .isEmpty:
                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
                default:
                    self?.defaultErrorHandler()(result)
                }
            }))
        }
    }
    
    func onAddProduct(_ product: Product) {
        if let group = group {
            // TODO don't create group item here we don't know if it exists in the group already, if it does the new uuid is not used. Use a prototype class like in list items.
            let groupItem = GroupItem(uuid: UUID().uuidString, quantity: 1, product: product, group: group)
            
            Providers.listItemGroupsProvider.add(groupItem, remote: true, successHandler{[weak self] addedItem in
                self?.productsWithQuantityController?.addOrUpdateUI(ProductWithQuantityGroup(groupItem: addedItem), scrollToCell: true)
            })
        }
    }
    
    fileprivate func addOrUpdateUI(_ items: [GroupItem]) {
        productsWithQuantityController?.addOrUpdateUI(items.map{
            return ProductWithQuantityGroup(groupItem: $0)
        })
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
        func onEditItem(_ input: ListItemInput, editingItem: GroupItem) {
            Providers.listItemGroupsProvider.update(input, updatingGroupItem: editingItem, remote: true, resultHandler (onSuccess: {[weak self] (inventoryItem, replaced) in
                if replaced { // if an item was replaced (means: a previous item with same unique as the updated item already existed and was removed from the inventory) reload items to get rid of it.
                    self?.reload()
                } else {
                    _ = self?.updateItemUI(inventoryItem)
                }
                self?.closeTopController()
            }, onError: {[weak self] result in
                self?.reload()
                self?.defaultErrorHandler()(result)
            }))
        }
        
        func onAddItem(_ input: ListItemInput) {
            if let group = group {
                let groupItemInput = GroupItemInput(name: input.name, quantity: input.quantity, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
                Providers.listItemGroupsProvider.add(groupItemInput, group: group, remote: true, resultHandler (onSuccess: {[weak self] groupItem in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end.
                    self?.reload()
                    self?.closeTopController()
                }, onError: {[weak self] result in
                    self?.reload()
                    self?.closeTopController()
                    self?.defaultErrorHandler()(result)
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
        reload()
    }
    
    func onRemovedBrand(_ name: String) {
        reload()
    }
    
    func appendItemUI(_ item: GroupItem) {
        productsWithQuantityController.appendItemUI(ProductWithQuantityGroup(groupItem: item), scrollToCell: false)
    }
    
    func updateItemUI(_ item: GroupItem) -> Bool {
        return productsWithQuantityController.updateModelUI({($0 as! ProductWithQuantityGroup).groupItem.same(item)}, updatedModel: ProductWithQuantityGroup(groupItem: item))
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "productsWithQuantityControllerSegue" {
            productsWithQuantityController = segue.destination as? ProductsWithQuantityViewController
            productsWithQuantityController?.delegate = self
        }
    }
    
    // MARK: - ProductsWithQuantityViewControllerDelegate
    
    func loadModels(_ page: NSRange, sortBy: InventorySortBy, onSuccess: @escaping ([ProductWithQuantity]) -> Void) {
        if let group = group {
            Providers.listItemGroupsProvider.groupItems(group, sortBy: sortBy, fetchMode: .both, successHandler{groupItems in
                let productsWithQuantity = groupItems.map{ProductWithQuantityGroup(groupItem: $0)}
                onSuccess(productsWithQuantity)
            })
        } else {
            print("Error: InventoryItemsController.loadModels: no inventory")
        }
    }
    
    func remove(_ model: ProductWithQuantity, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void) {
        Providers.listItemGroupsProvider.remove((model as! ProductWithQuantityGroup).groupItem, remote: true, resultHandler(onSuccess: {
            onSuccess()
        }, onError: {result in
            onError(result)
        }))
    }
    
    func increment(_ model: ProductWithQuantity, delta: Int, onSuccess: @escaping (Int) -> Void) {
        Providers.listItemGroupsProvider.increment((model as! ProductWithQuantityGroup).groupItem, delta: delta, remote: true, successHandler({updatedQuantity in
            onSuccess(updatedQuantity)
        }))
    }
    
    func onModelSelected(_ model: ProductWithQuantity, indexPath: IndexPath) {
        if productsWithQuantityController.isEditing {
            let groupItem = (model as! ProductWithQuantityGroup).groupItem
            updatingGroupItem = groupItem
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: groupItem))
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
    
    func indexPathOfItem(_ model: ProductWithQuantityGroup) -> IndexPath? {
        let models = productsWithQuantityController.models as! [ProductWithQuantityGroup]
        for i in 0..<models.count {
            if models[i].same(model) {
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
    
    // MARK: - Websocket // TODO websocket group items?
    
    func onWebsocketGroupItem(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<GroupItem>> {
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
                    _ = updateItemUI(notification.obj)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let groupItemUuid = notification.obj
                
                switch notification.verb {
                case .Delete:
                    if let model = ((productsWithQuantityController.models as! [ProductWithQuantityGroup]).filter{$0.groupItem.uuid == groupItemUuid}).first {
                        if let indexPath = indexPathOfItem(model) {
                            _ = productsWithQuantityController.removeItemUI(indexPath)
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
            
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ItemIncrement>> {
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
    
    
    func onWebsocketGroupItems(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<[GroupItem]>> {
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
    
    func onWebsocketGroup(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Delete:
                    let groupUuid = notification.obj
                    if let group = group {
                        
                        if group.uuid == groupUuid {
                            AlertPopup.show(title: trans("popup_title_group_deleted"), message: trans("popup_group_was_deleted_in_other_device", group.name), controller: self, onDismiss: {[weak self] in
                                _ = self?.navigationController?.popViewController(animated: true)
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
    
    func onWebsocketProduct(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    reload()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onWebsocketProductCategory(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    reload()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
        // TODO notification - note has the sender name
        reload()
    }
}
