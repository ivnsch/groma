//
//  InventoriesTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

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

class InventoriesTableViewController: ExpandableItemsTableViewController, AddEditInventoryControllerDelegate {
    
    var topAddEditListControllerManager: ExpandableTopViewController<AddEditInventoryController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Inventories")
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsockeInventory:", name: WSNotificationName.List.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditInventoryController> {
        let top = CGRectGetHeight(topBar.frame)
        return ExpandableTopViewController(top: top, height: 250, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventory()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = true
            return controller
        }
    }
    
    override func initModels() {
        Providers.inventoryProvider.inventories(successHandler{inventories in
            let models: [ExpandableTableViewModel] = inventories.map{ExpandableTableViewInventoryModel(inventory: $0)}
            if self.models != models { // if current list is nil or the provider list is different
                self.models = models
                self.tableView.reloadData()
            }
        })
    }
    
    private func initNavBarRightButtons(actions: [UIBarButtonSystemItem]) {
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                self.addButton = button
                buttons.append(button)
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            case .Cancel:
                let button = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancelTap:")
                buttons.append(button)
            default: break
            }
        }
        
        topBar.items?.first?.rightBarButtonItems = buttons
    }
    
    override func onCancelTap(sender: UIBarButtonItem) {
        super.onCancelTap(sender)
        topAddEditListControllerManager?.expand(false)
    }
    
    override func onSubmitTap(sender: UIBarButtonItem) {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewInventoryModel).inventory
        topAddEditListControllerManager?.expand(true)
    }
    
    override func onReorderedModels() {
        let lists = (models as! [ExpandableTableViewInventoryModel]).map{$0.inventory}
        
        let updatedLists = lists.mapEnumerate{index, list in list.copy(order: index)}
        
        Providers.inventoryProvider.updateInventories(updatedLists, remote: true, successHandler{//change
            //            self?.models = models // REVIEW remove? this seem not be necessary...
        })
    }
    
    override func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.inventoryItemsViewController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
            listItemsController.setThemeColor(cell.backgroundColor!)
            listItemsController.inventory = (model as! ExpandableTableViewInventoryModel).inventory //change
            listItemsController.onExpand(true)
        }
        
        return listItemsController
    }
    
    override func onAddTap() {
        topAddEditListControllerManager?.expand(!(topAddEditListControllerManager?.expanded ?? true)) // toggle - if for some reason variable isn't set, set expanded false (!true)
    }
    
    override func closeTopViewController() {
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - EditListViewController
    //change
    func onInventoryAdded(list: Inventory) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewInventoryModel(inventory: list))
                self?.topAddEditListControllerManager?.expand(false)
                self?.initNavBarRightButtons([.Add])
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
                    Providers.inventoryProvider.addInventory(inventory, remote: false, successHandler {[weak self] in
                        self?.onInventoryAdded(inventory)
                    })
                    
                case .Update:
                    Providers.inventoryProvider.updateInventory(inventory, remote: false, successHandler{[weak self] in
                        self?.onInventoryUpdated(inventory)
                    })
                    
                case .Delete:
                    Providers.inventoryProvider.removeInventory(inventory, remote: false, successHandler{[weak self] in
                        self?.removeModel(ExpandableTableViewInventoryModel(inventory: inventory))
                    })
                }
            } else {
                print("Error: ViewController.onWebsocketList: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketList: no userInfo")
        }
    }
}