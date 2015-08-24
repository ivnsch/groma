//
//  InventoriesViewController.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

protocol InventoriesViewControllerDelegate: class {
    func inventorySelected(inventory: Inventory)
}

class InventoriesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, InventoryCellDelegate {
    
    @IBOutlet weak var tableView: NSTableView!
    
    private let inventoryItemsProvider = ProviderFactory().inventoryItemsProvider
    private let inventoriesProvider = ProviderFactory().inventoryProvider
    
    private var selectables: [Selectable<Inventory>] = []
    
    weak var delegate: InventoriesViewControllerDelegate?
    
    private(set) var selectedInventory: Inventory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tableView.headerView = nil
    }
    
    @IBAction func addInventoryTapped(sender: NSButton) {
        let addListController = AddListController()
        addListController.addTappedFunc = {listInput in
            self.addList(listInput)
            addListController.close()
        }
        addListController.show()
    }
    
    override func viewDidAppear() {
        self.loadInventories() // note we have to do this in viewDidAppear (or later) otherwise crash because tableview delegate seems not to be fully initialised yet. Related with being created in other view controller.
        if let firstList = self.selectables.first?.model {
            self.selectInventory(firstList)
            self.selectTableViewRow(firstList)
        }
        
        // temporary workaround for recreation of icloud folder
        let seconds = 3.0
        let delay = seconds * Double(NSEC_PER_SEC)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.loadInventories()
        })
    }
    
    private func addList(inventoryInput: EditListInput) {
        // TODO handle when user doesn't have account! if I add list without internet, then there's no account data and no possibility to share users
        // so in this case we add to local database with dummy user (?) that represents myself and hide share users from the user (or "you need an account to use this")
        // when user opens account with lists like that, somehow we replace the dummy value with the email (client and server)
        // or maybe we can just use *always* a dummy identifier for myself. A general purpose string like "myself"
        // For the user is not important to see their own email address, only to know this is myself. This is probably a bad idea for the databse in the server though.
        let inventory = Inventory(uuid: NSUUID().UUIDString, name: inventoryInput.name, users: [ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail")])
        
        self.inventoriesProvider.addInventory(inventory, successHandler{[weak self] in
            self?.loadInventories() // we modified list - reload everything
            self?.selectTableViewRow(inventory)
            return
            })
    }
    
    private func selectTableViewRow(inventory: Inventory) {
        if let rowIndex = (selectables.map{$0.model}).indexOf(inventory) {
            self.tableView.selectRowIndexes(NSIndexSet(index: rowIndex), byExtendingSelection: false)
        } else {
            print("Warning: trying to select a list that is not in the tableview")
        }
    }
    
    private func restoreSelectionAfterReloadData() {
        if let selectedList = self.selectedInventory {
            self.selectTableViewRow(selectedList)
        }
    }
    
    private func loadInventories() {
        self.inventoriesProvider.inventories(successHandler{[weak self] inventories in
            self?.selectables = inventories.map{Selectable(model: $0)}
            self?.tableView.reloadData()
        })
    }
    
    private func selectInventory(inventory: Inventory) {
        self.selectedInventory = inventory
        self.selectTableViewRow(inventory) // this makes sense when selecting programmatically and is redundant when we come from selecting in table view (ok).
        
        self.delegate?.inventorySelected(inventory)
    }
    
    private func removeInventory(inventory: Inventory) {
        // TODO!
//        self.inventoriesProvider.remove(inventory, successHandler{[weak self] in
//            self?.loadInventories()
//            self?.restoreSelectionAfterReloadData()
//            })
    }
    
    private func removeInventoryWithConfirm(inventory: Inventory) {
        DialogUtils.confirmAlert(okTitle: "Yes", title: "Remove inventory: \(inventory.name)\nAre you sure?", msg: "This will also delete all the items in the inventory", okAction: {
            self.removeInventory(inventory)
        })
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.selectables.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("inventoryCell", owner:self) as! InventoryCell
        let selectable = self.selectables[row]
        cell.inventory = selectable.model
        cell.delegate = self
        return cell
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let row = self.tableView.selectedRow
        if row >= 0 {
            let selectedInventory = self.selectables[row].model
            self.selectInventory(selectedInventory)
        }
    }
    
    // MARK: - InventoryCellDelegate
    
    func removeInventoryTapped(cell: InventoryCell) {
        if let list = cell.inventory {
            self.removeInventoryWithConfirm(list)
            
        } else {
            print("Error - cell without list tapped")
        }
    }
}