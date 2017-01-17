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

    fileprivate var inventoriesResult: Results<DBInventory>?
    fileprivate var notificationToken: NotificationToken?
    
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
        Prov.inventoryProvider.inventoriesRealm(true, successHandler{[weak self] inventories in guard let weakSelf = self else {return}
                
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
                    
                    weakSelf.models = weakSelf.inventoriesResult!.map{ExpandableTableViewInventoryModelRealm(inventory: $0)}
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
            
            let authInventories = inventories.filter{InventoryAuthChecker.checkAccess($0)} // TODO
            weakSelf.models = authInventories.map{ExpandableTableViewInventoryModelRealm(inventory: $0)}
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
    
    override func onReorderedModels(from: Int, to: Int) {
        let inventories = (models as! [ExpandableTableViewInventoryModelRealm]).map{$0.inventory}
        
        let reorderedInventories = inventories.mapEnumerate{index, inventory in inventory.copy(order: index)}
        let orderUpdates = reorderedInventories.map{inventory in OrderUpdate(uuid: inventory.uuid, order: inventory.order)}
        
        models = reorderedInventories.map{ExpandableTableViewInventoryModelRealm(inventory: $0)}
        
        let withoutNotifying = notificationToken.map{[$0]} ?? []
        
        Prov.inventoryProvider.updateInventoriesOrder(orderUpdates, withoutNotifying: [], realm: nil, remote: false, successHandler {
        })
        
        // For now in the foreground. When in bg get either wrong thread error or "only notifications for the Realm being modified can be skipped" error (instantiating a new realm in bg)
        // TODO!!!!!!!!!!!!!!!!!!!!!!!! do this in Providers
//        if let realm = inventoriesResult?.realm {
//            try! realm.write(withoutNotifying: withoutNotifying) {_ in
//                for orderUpdate in orderUpdates {
//                    realm.create(DBInventory.self, value: DBInventory.createOrderUpdateDict(orderUpdate, dirty: false), update: true)
//                }
//            }
//        }
    }
    
    override func canRemoveModel(_ model: ExpandableTableViewModel, can: @escaping (Bool) -> Void) {
//        _ = (model as! ExpandableTableViewInventoryModelRealm).inventory
        ConfirmationPopup.show(title: trans("popup_title_warning"), message: trans("popup_remove_inventory_warning"), okTitle: trans("popup_button_remove"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {
                can(true)
            }, onCancel: {
                can(false)
            })
    }
    
    
    
    override func onRemoveModel(_ model: ExpandableTableViewModel, index: Int) {
        let inventory = (model as! ExpandableTableViewInventoryModelRealm).inventory

        Prov.inventoryProvider.removeInventory(inventory, remote: true, resultHandler(onSuccess: {_ in
            }, onError: {[weak self] result in
                self?.initModels()
                self?.defaultErrorHandler()(result)
            }
        ))
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
    
    fileprivate func debugItems() {
        if QorumLogs.minimumLogLevelShown < 2 {
            print("Inventories:")
            (models as! [ExpandableTableViewInventoryModelRealm]).forEach{print("\($0.inventory.debugDescription)")}
        }
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
        Prov.inventoryProvider.addInventory(inventory, remote: true, resultHandler(onSuccess: {
            // do nothing - is handled in realm notification handler
            }, onErrorAdditional: {[weak self] result in
                self?.onInventoryAddOrUpdateError(inventory)
            }
        ))
    }
    
    func onUpdateInventory(_ inventory: DBInventory) {
        Prov.inventoryProvider.updateInventory(inventory, remote: true, resultHandler(onSuccess: {
            // do nothing - is handled in realm notification handler
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
}
