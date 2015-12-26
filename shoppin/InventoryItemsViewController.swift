//
//  InventoryItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 01/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import SwiftValidator
import ChameleonFramework

class InventoryItemsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, AddEditInventoryItemControllerDelegate, InventoryItemsTableViewControllerDelegate, ExpandableTopViewControllerDelegate, AddEditListItemViewControllerDelegate, ListTopBarViewDelegate, QuickAddDelegate {

    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var emptyInventoryView: UIView!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!

    private var sortByPopup: CMPopTipView?
    
    private var tableViewController: InventoryItemsTableViewController?

    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    var onViewWillAppear: VoidFunction?

    @IBOutlet weak var topBar: ListTopBarView!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!

    private var addEditInventoryItemControllerManager: ExpandableTopViewController<AddEditInventoryItemController>?
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?

    // Warn: Setting this before prepareForSegue for tableViewController has no effect
    var inventory: Inventory? {
        didSet {
            tableViewController?.inventory = inventory
            if let inventory = inventory {
                topBar.title = inventory.name
            }
        }
    }
    
    var expandDelegate: Foo?

    private var titleLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let tableView = tableViewController?.tableView {
            addEditInventoryItemControllerManager = initAddEditInventoryItemsManager(tableView)
            
        } else {
            print("Error: InventoryItemsViewController.viewDidLoad no tableview in tableViewController")
        }

        initTitleLabel()

        topBar.delegate = self

        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyInventoryViewTap:"))
        emptyInventoryView.addGestureRecognizer(tapRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventory:", name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryItems:", name: WSNotificationName.InventoryItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryItem:", name: WSNotificationName.InventoryItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryWithHistoryAfterSave:", name: WSNotificationName.InventoryItemsWithHistoryAfterSave.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
            emptyInventoryView.hidden = true
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
        }
        topBar.layoutIfNeeded() // FIXME weird effect and don't we need this in view controller
        topBar.positionTitleLabelLeft(expanding, animated: true)
    }

    func onExpandableClose() {
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    func onEmptyInventoryViewTap(sender: UITapGestureRecognizer) {
        // TODO
    }
    
    private func updateEmptyInventoryView() {
        if let inventoryItems = tableViewController?.inventoryItems {
            emptyInventoryView.setHiddenAnimated(!inventoryItems.isEmpty)
        }
    }
    
    private func initAddEditInventoryItemsManager(tableView: UITableView) -> ExpandableTopViewController<AddEditInventoryItemController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<AddEditInventoryItemController> = ExpandableTopViewController(top: top, height: 180, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventoryItem()
            controller.delegate = self
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
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy(sortByOption.value)
        sortByButton.setTitle(sortByOption.key, forState: .Normal)
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    private func sortBy(sortBy: InventorySortBy) {
        tableViewController?.sortBy = sortBy
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedInventoryItemsTableViewSegue" {
            tableViewController = segue.destinationViewController as? InventoryItemsTableViewController
            tableViewController?.delegate = self
            topQuickAddControllerManager = initTopQuickAddControllerManager(tableViewController!.tableView)
        }
    }
    
    @IBAction func onSortByTap(sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sortByButton, inView: view, animated: true)
        }
    }
    
    @IBAction func onEditTap(sender: UIButton) {
        toggleEditing()
    }
    
    private func toggleEditing() {
        if let tableViewController = tableViewController {
            tableViewController.setEditing(!tableViewController.editing, animated: true)
            editButton.title = tableViewController.editing ? "Done" : "Edit"
            if !tableViewController.editing {
                topBar.setRightButtonIds([])
            }
        } else {
            print("Warn: InventoryItemsViewController.onEditTap edit tap but no tableViewController")
        }
    }
    
    // MARK: - AddEditListItemViewControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit) {
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        // Not used - update is currently a different controller / delegate
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, successHandler: VoidFunction? = nil) {
        
        if let inventory = inventory {

            if let price = priceText.floatValue, quantity = Int(quantityText) {
                
                let input = InventoryItemInput(name: name, quantity: quantity, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit)
                
                Providers.inventoryItemsProvider.addToInventory(inventory, itemInput: input, self.successHandler{[weak self] (inventoryItemWithHistoryEntry: InventoryItemWithHistoryEntry) in
                    // we have pagination so we can't just append at the end of table view. For now simply cause a reload and start at first page. The new item will appear when user scrolls to the end. TODO nicer solution
                    self?.tableViewController?.clearAndLoadFirstPage()
                    self?.toggleTopAddController()
                })
            }
            
        } else {
            print("Error: InventoryItemsViewController.submitInputs: No inventory")
        }
    }
    
    
    // MARK: - AddEditInventoryItemControllerDelegate
    
    
    func onSubmit(name: String, category: String, price: Float, quantity: Int, editingInventoryItem: InventoryItem?) {
        if let editingInventoryItem = editingInventoryItem {
            let updatedCategory = editingInventoryItem.product.category.copy(name: category)
            let updatedProduct = editingInventoryItem.product.copy(name: name, price: price, category: updatedCategory)
            // TODO! calculate quantity delta correctly?
            let updatedInventoryItem = editingInventoryItem.copy(quantity: quantity, quantityDelta: quantity, product: updatedProduct)
            Providers.inventoryItemsProvider.updateInventoryItem(updatedInventoryItem, remote: true, successHandler {[weak self] in
                self?.onInventoryItemUpdated()
            })
            
        } else {
            
            print("Not supported: Adding directly to inventory")

        }
    }
    
    func onInventoryItemUpdated() {
        // we have pagination so we don't know if the item is visible atm. For now simply cause a reload and start at first page. TODO nicer solution
        tableViewController?.clearAndLoadFirstPage()
        addEditInventoryItemControllerManager?.controller?.clear()
        addEditInventoryItemControllerManager?.expand(false)
        topBar.setRightButtonIds([])
    }
    
    func onCancelTap() {
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
                addEditInventoryItemControllerManager?.controller?.submit()
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
    
    private func sendActionToTopController(action: FLoatingButtonAction) {
        
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        } else if addEditInventoryItemControllerManager?.expanded ?? false {
            // here we do dispatching in place as it's relatively simple and don't want to contaminate to many view controllers with floating button code
            // there should be a separate component to do all this but no time now. TODO improve
            
            switch action {
            case .Submit:
                addEditInventoryItemControllerManager?.controller?.submit()
            case .Back, .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(addEditInventoryItemControllerManager?.controller) instance")
            }
        }
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
        if center {
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonIds([.ToggleOpen])
        }
    }
    
    // MARK: - InventoryItemsTableViewControllerDelegate
    
    func onInventoryItemSelected(inventoryItem: InventoryItem, indexPath: NSIndexPath) {
        if tableViewController?.editing ?? false {
            addEditInventoryItemControllerManager?.expand(true)
            addEditInventoryItemControllerManager?.controller?.editingInventoryItem = inventoryItem
            topBar.setRightButtonIds([.Submit])
        }
    }
    
    func onLoadedInventoryItems(inventoryItems: [InventoryItem]) {
        updateEmptyInventoryView()
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
                self?.tableViewController?.addOrIncrementUI(inventoryItems.map{$0.inventoryItem})
            })
        }
    }
    
    
    func onAddProduct(product: Product) {
        if let inventory = inventory {
            let inventoryItem = InventoryItemWithHistoryEntry(inventoryItem: InventoryItem(quantity: 1, quantityDelta: 1, product: product, inventory: inventory), historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail")) // TODO remove the offline dummy email? to add inventory shared user is not needed (the server uses the logged in user).
            Providers.inventoryItemsProvider.addToInventory([inventoryItem], remote: true, successHandler{[weak self] result in
                self?.tableViewController?.addOrIncrementUI(inventoryItem.inventoryItem)
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
                        self?.tableViewController?.updateIncrementUI(inventoryItem, delta: incr.delta)
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
                            self?.tableViewController?.remove(inventoryItemId.inventoryUuid, inventoryItemProductUuid: inventoryItemId.productUuid)
                            self?.updateEmptyInventoryView()
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