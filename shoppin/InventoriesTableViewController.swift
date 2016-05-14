//
//  InventoriesTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class ExpandableTableViewInventoryModel: ExpandableTableViewModel {
    
    let inventory: Inventory
    
    init (inventory: Inventory) {
        self.inventory = inventory
    }
    
    override var name: String {
        return inventory.name
    }
    
    override var bgColor: UIColor {
        return inventory.bgColor
    }
    
    override var users: [SharedUser] {
        return inventory.users
    }
    
    override func same(rhs: ExpandableTableViewModel) -> Bool {
        return inventory.same((rhs as! ExpandableTableViewInventoryModel).inventory)
    }
    
    override var debugDescription: String {
        return inventory.debugDescription
    }
}

class InventoriesTableViewController: ExpandableItemsTableViewController, AddEditInventoryControllerDelegate, ExpandableTopViewControllerDelegate {
    
    var topAddEditListControllerManager: ExpandableTopViewController<AddEditInventoryController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Inventories")

        topAddEditListControllerManager = initTopAddEditListControllerManager()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoriesTableViewController.onWebsockeInventory(_:)), name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoriesTableViewController.onWebsockeInventories(_:)), name: WSNotificationName.Inventories.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoriesTableViewController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InventoriesTableViewController.onInventoryInvitationAccepted(_:)), name: Notification.InventoryInvitationAccepted.rawValue, object: nil)
    }
    
    deinit {
        QL1("Deinit inventories controller")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditInventoryController> {
        let top = CGRectGetHeight(topBar.frame)
        let expandableTopViewController: ExpandableTopViewController<AddEditInventoryController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventory()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = false
            return controller
        }
        
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    override func initModels() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            if let weakSelf = self {
                let authInventories = inventories.filter{InventoryAuthChecker.checkAccess($0)}
                weakSelf.models = authInventories.map{ExpandableTableViewInventoryModel(inventory: $0)}
                weakSelf.debugItems()
            }
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        super.onSelectCellInEditMode(model)
        topAddEditListControllerManager?.expand(true)        
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewInventoryModel).inventory
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func onReorderedModels() {
        let inventories = (models as! [ExpandableTableViewInventoryModel]).map{$0.inventory}
        
        let reorderedInventories = inventories.mapEnumerate{index, inventory in inventory.copy(order: index)}
        let orderUpdates = reorderedInventories.map{inventory in OrderUpdate(uuid: inventory.uuid, order: inventory.order)}
        
        models = reorderedInventories.map{ExpandableTableViewInventoryModel(inventory: $0)}
        
        Providers.inventoryProvider.updateInventoriesOrder(orderUpdates, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.initModels()
            }
        ))
    }
    
    override func canRemoveModel(model: ExpandableTableViewModel, can: Bool -> Void) {
        let inventory = (model as! ExpandableTableViewInventoryModel).inventory
        ConfirmationPopup.show(title: "Warning", message: "Removing the inventory '\(inventory.name)' will remove also all the history items, stats and lists associated with it.", okTitle: "Remove", cancelTitle: "Cancel", controller: self, onOk: {
                can(true)
            }, onCancel: {
                can(false)
            })
    }
    
    override func onRemoveModel(model: ExpandableTableViewModel) {
        let inventory = (model as! ExpandableTableViewInventoryModel).inventory
        Providers.inventoryProvider.removeInventory(inventory, remote: true, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.initModels()
                self?.defaultErrorHandler()(providerResult: result)
            }
        ))
    }
    
    override func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.inventoryItemsViewController()
        
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, inventory has to be set first for topbar dot to be positioned correctly right of the title
            listItemsController?.inventory = (model as! ExpandableTableViewInventoryModel).inventory
            listItemsController?.setThemeColor(weakCell.backgroundColor!)
            listItemsController?.onExpand(true)
        }
        
        listItemsController.onViewDidAppear = {[weak listItemsController] in
            listItemsController?.onExpand(true)
        }
        
        return listItemsController
    }
    
    override func animationsComplete(wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }
    
    override func onAddTap(rotateTopBarButton: Bool = true) {
        super.onAddTap()
        SizeLimitChecker.checkInventoriesSizeLimit(models.count, controller: self) {[weak self] in
            if let weakSelf = self {
                let expand = !(weakSelf.topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                weakSelf.topAddEditListControllerManager?.expand(expand)
                if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
                    weakSelf.setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
                }
            }
        }
    }
    
    private func debugItems() {
        if QorumLogs.minimumLogLevelShown < 2 {
            print("Inventories:")
            (models as! [ExpandableTableViewInventoryModel]).forEach{print("\($0.inventory.shortDebugDescription)")}
        }
    }

    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.NormalFromExpanded)
    }
    
    // MARK: - AddEditInventoryControllerDelegate
    
    func onAddInventory(inventory: Inventory) {
        Providers.inventoryProvider.addInventory(inventory, remote: true, resultHandler(onSuccess: {[weak self] in
            self?.addInventoryUI(inventory)
            }, onErrorAdditional: {[weak self] result in
                self?.onInventoryAddOrUpdateError(inventory)
            }
        ))
    }
    
    func onUpdateInventory(inventory: Inventory) {
        Providers.inventoryProvider.updateInventory(inventory, remote: true, resultHandler(onSuccess: {[weak self] in
            self?.updateInventoryUI(inventory)
            }, onErrorAdditional: {[weak self] result in
                self?.onInventoryAddOrUpdateError(inventory)
            }
        ))
    }
    
    private func addInventoryUI(inventory: Inventory) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewInventoryModel(inventory: inventory))
                self?.topAddEditListControllerManager?.expand(false)
                self?.setTopBarState(.NormalFromExpanded)
            }
        }
    }
    
    private func updateInventoryUI(inventory: Inventory) {
        models.update(ExpandableTableViewInventoryModel(inventory: inventory))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
        setTopBarState(.NormalFromExpanded)
    }
    
    private func onInventoryAddOrUpdateError(inventory: Inventory) {
        initModels()
        // If the user quickly after adding the inventory opened its inventory items controller, close it.
        for childViewController in childViewControllers {
            if let inventoryItemsController = childViewController as? InventoryItemsController {
                if (inventoryItemsController.inventory.map{$0.same(inventory)}) ?? false {
                    inventoryItemsController.back()
                }
            }
        }
    }
    
    // MARK: - Websocket
    
    func onWebsockeInventory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Inventory>> {
            if let notification = info[WSNotificationValue] {
                let inventory = notification.obj
                switch notification.verb {
                case .Add:
                    addInventoryUI(inventory)
                case .Update:
                    Providers.inventoryProvider.updateInventory(inventory, remote: false, successHandler{[weak self] in
                        self?.updateInventoryUI(inventory)
                    })
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let inventoryUuid = notification.obj
                switch notification.verb {
                case .Delete:
                    if let model = ((models as! [ExpandableTableViewInventoryModel]).filter{$0.inventory.uuid == inventoryUuid}).first {
                        removeModel(model)
                    } else {
                        QL3("Received notification to remove list but it wasn't in table view. Uuid: \(inventoryUuid)")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("userInfo not there or couldn't be casted: \(note.userInfo)")
        }
    }

    func onWebsockeInventories(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[RemoteOrderUpdate]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Order:
                    initModels()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("userInfo not there or couldn't be casted: \(note.userInfo)")
        }
    }

    func onInventoryInvitationAccepted(note: NSNotification) {
        initModels()
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        initModels()
    }
}