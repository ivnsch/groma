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
}

class GroupItemsController: UIViewController, ProductsWithQuantityViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate, AddEditListItemViewControllerDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var topBar: ListTopBarView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    private var topAddEditListItemControllerManager: ExpandableTopViewController<AddEditListItemViewController>?
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    var group: ListItemGroup? {
        didSet {
            if let group = group {
                topBar.title = group.name
            }
        }
    }
    
    var expandDelegate: Foo?
    
    private var titleLabel: UILabel?
    
    var onViewWillAppear: VoidFunction?
    
    private var productsWithQuantityController: ProductsWithQuantityViewController!
    
    private var updatingGroupItem: GroupItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        productsWithQuantityController = UIStoryboard.productsWithQuantityViewController()
        addChildViewController(productsWithQuantityController)
        productsWithQuantityController.delegate = self
        
        initTitleLabel()
        
        topBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketGroupItem:", name: WSNotificationName.GroupItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketGroup:", name: WSNotificationName.Group.rawValue, object: nil)
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
                topAddEditListItemControllerManager = initAddEditGroupItemsControllerManager(tableView)
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
    
    private func initAddEditGroupItemsControllerManager(tableView: UITableView) -> ExpandableTopViewController<AddEditListItemViewController> {
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
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand, store: store) {
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, store: String) {
        if let groupItem = updatingGroupItem {
            if let price = priceText.floatValue, quantity = Int(quantityText) {
                let updatedCategory = groupItem.product.category.copy(name: category, color: categoryColor)
                let updatedProduct = groupItem.product.copy(name: name, price: price, category: updatedCategory, baseQuantity: baseQuantity, unit: unit, brand: brand, store: store)
                let updatedGroupItem = groupItem.copy(quantity: quantity, product: updatedProduct)
                Providers.listItemGroupsProvider.update(updatedGroupItem, remote: true, successHandler{[weak self] in
                    self?.onGroupItemUpdated(true)
                })
            }
        } else {
            print("Warn: GroupItemsController.onUpdateTap: No group: \(group) or updatingGroupItem: \(updatingGroupItem)")
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
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, store: String, successHandler: VoidFunction? = nil) {
        
        if let group = group {
            
            if let price = priceText.floatValue, quantity = Int(quantityText) {
                
                let input = GroupItemInput(name: name, quantity: quantity, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit, brand: brand, store: store)
                
                Providers.listItemGroupsProvider.add(input, group: group, remote: true, self.successHandler{[weak self] groupItem in
                    self?.onGroupItemAdded(true)
                })
            }
            
        } else {
            print("Error: InventoryItemsViewController.submitInputs: No inventory")
        }
    }
    
    func onGroupItemUpdated(tryCloseTop: Bool) {
        // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
        reload()
//        topAddEditListItemControllerManager?.controller?.clear()
        if tryCloseTop {
            topAddEditListItemControllerManager?.expand(false)
            topBarOnCloseExpandable()
        }
    }
    
    private func reload() {
        productsWithQuantityController?.clearAndLoadFirstPage()
    }
    
    func onGroupItemAdded(tryCloseTop: Bool) {
        // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
        reload()
        if tryCloseTop {
            toggleTopAddController()
        }
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
            SizeLimitChecker.checkGroupItemsSizeLimit(productsWithQuantityController.models.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.Add)
                }
            }
        case .Submit:
            if topQuickAddControllerManager?.expanded ?? false {
                sendActionToTopController(.Submit)
            } else if topAddEditListItemControllerManager?.expanded ?? false {
                topAddEditListItemControllerManager?.controller?.submit(.Update)
            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            toggleEditing()
        }
    }
    
    private func toggleTopAddController() {
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || topAddEditListItemControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            topAddEditListItemControllerManager?.expand(false)
            
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
        } else if topAddEditListItemControllerManager?.expanded ?? false {
            // here we do dispatching in place as it's relatively simple and don't want to contaminate to many view controllers with floating button code
            // there should be a separate component to do all this but no time now. TODO improve
            
            switch action {
            case .Submit:
                topAddEditListItemControllerManager?.controller?.submit(.Update)
            case .Back, .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(topAddEditListItemControllerManager?.controller) instance")
            }
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
        Providers.listItemGroupsProvider.addGroupItems(group, remote: true, successHandler{[weak self] groupItems in
            self?.productsWithQuantityController?.addOrIncrementUI(groupItems.map{ProductWithQuantityGroup(groupItem: $0)})
        })
    }
    
    func onAddProduct(product: Product) {
        if let group = group {
            let groupItem = GroupItem(uuid: NSUUID().UUIDString, quantity: 1, product: product, group: group)
            
            Providers.listItemGroupsProvider.add(groupItem, remote: true, successHandler{[weak self] result in
                self?.productsWithQuantityController?.addOrIncrementUI(ProductWithQuantityGroup(groupItem: groupItem))
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
        if let group = group {
            Providers.listItemGroupsProvider.groupItems(group, successHandler{groupItems in
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
    
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: VoidFunction) {
        Providers.listItemGroupsProvider.increment((model as! ProductWithQuantityGroup).groupItem, delta: delta, remote: true, successHandler({result in
            onSuccess()
        }))
    }
    
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath) {
        if productsWithQuantityController.editing {
            let groupItem = (model as! ProductWithQuantityGroup).groupItem
            updatingGroupItem = groupItem
            topAddEditListItemControllerManager?.expand(true)
            topAddEditListItemControllerManager?.controller?.updatingItem = AddEditItem(item: groupItem)
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    func emptyViewData() -> (text: String, text2: String, imgName: String) {
        return (text: "You group is empty", text2: "Tap to add items", imgName: "empty_shelf")
    }
    
    func onEmptyViewTap() {
        toggleTopAddController()
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
    

    
    // MARK: - Websocket // TODO websocket group items?
    
    func onWebsocketGroupItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<GroupItem>> {
            if let notification = info[WSNotificationValue] {
//                let groupItem = notification.obj
                switch notification.verb {
                case .Add:
                    onGroupItemAdded(false)
                case .Update:
                    onGroupItemUpdated(false)
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
    
    func onWebsocketGroup(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let groupUuid = notification.obj
                if let group = group {
                    
                    if group.uuid == groupUuid {
                        AlertPopup.show(title: "Group deleted", message: "The group \(group.name) was deleted from another device. Returning to groups.", controller: self, onDismiss: {[weak self] in
                            self?.navigationController?.popViewControllerAnimated(true)
                        })
                    } else {
                        QL1("Websocket: Group items controller received a notification to delete a group which is not the one being currently shown")
                    }
                } else {
                    QL4("Websocket: Can't process delete group notification because there's no group set")
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
