//
//  InventoriesTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import RealmSwift
import Providers

class ExpandableTableViewInventoryModelRealm: ExpandableTableViewModel {
    
    let inventory: DBInventory
    
    init (inventory: DBInventory) {
        self.inventory = inventory
    }
    
    override var name: String {
        return inventory.name
    }
    
    override var bgColor: UIColor {
        return inventory.bgColor()
    }
    
    override var users: [DBSharedUser] {
        return inventory.users.toArray()
    }
    
    override func same(_ rhs: ExpandableTableViewModel) -> Bool {
        return inventory.same((rhs as! ExpandableTableViewInventoryModelRealm).inventory)
    }
    
    override var debugDescription: String {
        return inventory.debugDescription
    }
}

class InventoriesTableViewController: ExpandableItemsTableViewController, AddEditInventoryControllerDelegate, ExpandableTopViewControllerDelegate {
    
    var topAddEditListControllerManager: ExpandableTopViewController<AddEditInventoryController>?

    fileprivate var inventoriesResult: RealmSwift.List<DBInventory>? {
        didSet {
            tableView.reloadData()
            updateEmptyUI()
        }
    }
    fileprivate var notificationToken: NotificationToken?
    
    override var emptyViewLabels: (label1: String, label2: String) {
        return (label1: trans("empty_inventories_line1"), label2: trans("empty_inventories_line2"))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_inventories"))

        topAddEditListControllerManager = initTopAddEditListControllerManager()
    }
    
    deinit {
        QL1("Deinit inventories controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditInventoryController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditInventoryController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditInventory()
            controller.delegate = self
            controller.currentListsCount = self?.inventoriesResult?.count ?? {
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
        Prov.inventoryProvider.inventories(true, successHandler{[weak self] inventories in guard let weakSelf = self else {return}
                
            weakSelf.inventoriesResult = inventories
            
            self?.notificationToken = inventories.addNotificationBlock { changes in
                switch changes {
                case .initial:
//                        // Results are now populated and can be accessed without blocking the UI
//                        self.viewController.didUpdateList(reload: true)
                    QL1("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                    
                    weakSelf.tableView.beginUpdates()
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()

                    // TODO close only when receiving own notification, not from someone else (possible?)
                    weakSelf.topAddEditListControllerManager?.expand(false)
                    weakSelf.setTopBarState(.normalFromExpanded)
                    
                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
            
//            let authInventories = inventories.filter{InventoryAuthChecker.checkAccess($0)} // TODO ? (no multi user right now so letting open)
        })
    }
    
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(_ model: ExpandableTableViewModel, index: Int) {
        super.onSelectCellInEditMode(model, index: index)
        topAddEditListControllerManager?.expand(true)        
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewInventoryModelRealm).inventory
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func canRemoveModel(_ model: ExpandableTableViewModel, can: @escaping (Bool) -> Void) {
//        _ = (model as! ExpandableTableViewInventoryModelRealm).inventory
        ConfirmationPopup.show(title: trans("popup_title_warning"), message: trans("popup_remove_inventory_warning"), okTitle: trans("popup_button_remove"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {
                can(true)
            }, onCancel: {
                can(false)
            })
    }
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.inventoryItemsViewController()
        
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, inventory has to be set first for topbar dot to be positioned correctly right of the title
            
            listItemsController?.inventory = (model as! ExpandableTableViewInventoryModelRealm).inventory
            
            listItemsController?.setThemeColor(weakCell.backgroundColor!)
            listItemsController?.onExpand(true)
        }
        
        listItemsController.onViewDidAppear = {[weak listItemsController] in
            listItemsController?.onExpand(true)
        }
        
        return listItemsController
    }
    
    override func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }
    
    override func onAddTap(_ rotateTopBarButton: Bool = true) {
        super.onAddTap()
//        SizeLimitChecker.checkInventoriesSizeLimit(models.count, controller: self) {[weak self] in
//            if let weakSelf = self {
                let expand = !(topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                topAddEditListControllerManager?.expand(expand)
                if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
                    setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
                }
//            }
//        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.normalFromExpanded)
    }
    
    // MARK: - AddEditInventoryControllerDelegate
    
    func onAddInventory(_ inventory: DBInventory) {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}

        Prov.inventoryProvider.add(inventory, inventories: inventoriesResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            
            self?.tableView.insertRows(at: [IndexPath(row: inventoriesResult.count - 1, section: 0)], with: .top) // Note -1 as at this point the new item is already inserted in results
            
            self?.topAddEditListControllerManager?.expand(false)
            self?.setTopBarState(.normalFromExpanded)
            self?.updateEmptyUI()
            
        }, onErrorAdditional: {[weak self] result in
            self?.onInventoryAddOrUpdateError(inventory)
            }
        ))
    }
    
    func onUpdateInventory(_ inventory: DBInventory, inventoryInput: InventoryInput) {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        
        Prov.inventoryProvider.update(inventory, input: inventoryInput, inventories: inventoriesResult, notificationToken: notificationToken, resultHandler(onSuccess: {
            
            var row: Int?
            for (index, item) in inventoriesResult.enumerated() {
                if item.uuid == inventory.uuid {
                    row = index
                }
            }
            
            if let row = row {
                self.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            } else {
                QL4("Invalid state: can't find list: \(inventory)")
            }
            
            
        }, onErrorAdditional: {[weak self] result in
            self?.onInventoryAddOrUpdateError(inventory)
            }
        ))
    }
    
    fileprivate func onInventoryAddOrUpdateError(_ inventory: DBInventory) {
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
    
    // New
    
    override func loadModels(onSuccess: @escaping () -> Void) {
        // TODO!!!!!!!!!!!!! on success. Is also this method actually necessary?
        initModels()
    }
    
    override func itemForRow(row: Int) -> ExpandableTableViewModel? {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return nil}
        
        return ExpandableTableViewInventoryModelRealm(inventory: inventoriesResult[row])
    }
    
    override var itemsCount: Int? {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return nil}
        
        return inventoriesResult.count
    }
    
    override func deleteItem(index: Int) {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}
        
        Prov.inventoryProvider.delete(index: index, inventories: inventoriesResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            self?.updateEmptyUI()
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
    
    override func moveItem(from: Int, to: Int) {
        guard let inventoriesResult = inventoriesResult else {QL4("No result"); return}
        guard let notificationToken = notificationToken else {QL4("No notification token"); return}

        Prov.inventoryProvider.move(from: from, to: to, inventories: inventoriesResult, notificationToken: notificationToken, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
}
