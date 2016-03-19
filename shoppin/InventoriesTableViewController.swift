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
}

class InventoriesTableViewController: ExpandableItemsTableViewController, AddEditInventoryControllerDelegate, ExpandableTopViewControllerDelegate {
    
    var topAddEditListControllerManager: ExpandableTopViewController<AddEditInventoryController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Inventories")

        topAddEditListControllerManager = initTopAddEditListControllerManager()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsockeInventory:", name: WSNotificationName.Inventory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsockeInventories:", name: WSNotificationName.Inventories.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        topAddEditListControllerManager?.height = ConnectionProvider.connectedAndLoggedIn ? 140 : 110
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditInventoryController> {
        let top = CGRectGetHeight(topBar.frame)
        return ExpandableTopViewController(top: top, height: ConnectionProvider.connectedAndLoggedIn ? 140 : 110, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventory()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = false
            return controller
        }
    }
    
    override func initModels() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            if let weakSelf = self {
                let authInventories = inventories.filter{InventoryAuthChecker.checkAccess($0, controller: weakSelf)}
                weakSelf.models = authInventories.map{ExpandableTableViewInventoryModel(inventory: $0)}
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
        let lists = (models as! [ExpandableTableViewInventoryModel]).map{$0.inventory}
        
        let orderUpdates = lists.mapEnumerate{index, list in OrderUpdate(uuid: list.uuid, order: index)}
        
        Providers.inventoryProvider.updateInventoriesOrder(orderUpdates, remote: true, successHandler{
            //            self?.models = models // REVIEW remove? this seem not be necessary...
        })
    }
    
    override func onRemoveModel(model: ExpandableTableViewModel) {
        Providers.inventoryProvider.removeInventory((model as! ExpandableTableViewInventoryModel).inventory, remote: true, resultHandler(onSuccess: {
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
        
        listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
            listItemsController.setThemeColor(cell.backgroundColor!)
            listItemsController.inventory = (model as! ExpandableTableViewInventoryModel).inventory
            listItemsController.onExpand(true)
        }
        return listItemsController
    }
    
    override func onAddTap() {
        super.onAddTap()
        SizeLimitChecker.checkInventoriesSizeLimit(models.count, controller: self) {[weak self] in
            if let weakSelf = self {
                let expand = !(weakSelf.topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                weakSelf.topAddEditListControllerManager?.expand(expand)
                weakSelf.setTopBarStateForAddTap(expand)
            }
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    func onExpandableClose() {
        setTopBarState(.NormalFromExpanded)
    }
    
    // MARK: - EditListViewController
    func onInventoryAdded(list: Inventory) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewInventoryModel(inventory: list))
                self?.topAddEditListControllerManager?.expand(false)
                self?.setTopBarState(.NormalFromExpanded)
            }
        }
    }
    
    func onInventoryUpdated(list: Inventory) {
        models.update(ExpandableTableViewInventoryModel(inventory: list))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - Websocket
    
    func onWebsockeInventory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Inventory>> {
            if let notification = info[WSNotificationValue] {
                let inventory = notification.obj
                switch notification.verb {
                case .Add:
                    onInventoryAdded(inventory)
                case .Update:
                    Providers.inventoryProvider.updateInventory(inventory, remote: false, successHandler{[weak self] in
                        self?.onInventoryUpdated(inventory)
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
                case .Update:
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

    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        initModels()
    }
}