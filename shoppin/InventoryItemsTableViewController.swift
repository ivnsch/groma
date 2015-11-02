//
//  InventoryItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryItemsTableViewController: UITableViewController, InventoryItemTableViewCellDelegate {

    private var inventoryItems: [InventoryItem] = []
    @IBOutlet var tableViewFooter: LoadingFooter!

    var sortBy: InventorySortBy? {
        didSet {
            loadInventory()
        }
    }
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready
    
    private var inventory: Inventory?
    
    var tableViewTopInset: CGFloat {
        get {
            return tableView.topInset
        }
        set {
            tableView.topInset = newValue
        }
    }
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
    }
    
    override func viewWillAppear(animated:Bool) {
        self.navigationItem.title = "Inventory"
        
        onViewWillAppear?()
        
        inventoryItems = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    private func loadInventory() {
        Providers.inventoryProvider.firstInventory(successHandler {[weak self] inventory in
            //            self.navigationItem.title = inventory.name
            self?.inventory = inventory
            self?.loadPossibleNextPage()
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.inventoryItems.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("inventoryCell", forIndexPath: indexPath) as! InventoryItemTableViewCell

        let inventoryItem = self.inventoryItems[indexPath.row]
        
        cell.nameLabel.text = inventoryItem.product.name
        cell.quantityLabel.text = String(inventoryItem.quantity)
        
        cell.inventoryItem = inventoryItem
        cell.row = indexPath.row
        cell.delegate = self
        
        cell.cancelDeleteProgress() // some recycled cells were showing red bar on top

        // this was initially a local function but it seems we have to use a closure, see http://stackoverflow.com/a/26237753/930450
        // TODO change quantity / edit inventory items
//        let incrementItem = {(quantity: Int) -> () in
//            //let newQuantity = inventoryItem.quantity + quantity
//            //if (newQuantity >= 0) {
//                inventoryItem.quantityDelta += quantity
//                self.inventoryItemsProvider.updateInventoryItem(inventoryItem)
//                cell.quantityLabel.text = String(inventoryItem.quantity)
//            //}
//        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    // MARK: - InventoryItemTableViewCellDelegate
    
    func onIncrementItemTap(cell: InventoryItemTableViewCell) {
        cell.cancelDeleteProgress()
        self.checkChangeInventoryItemQuantity(cell, delta: 1)
    }
    
    func onDecrementItemTap(cell: InventoryItemTableViewCell) {
        cell.cancelDeleteProgress()        
        self.checkChangeInventoryItemQuantity(cell, delta: -1)
    }
    
    /**
    Unwrap optionals safely
    Note that despite implicitly unwrapped may look suitable here, we prefer working with ? as general approach
    */
    private func checkChangeInventoryItemQuantity(cell: InventoryItemTableViewCell, delta: Int) {
        if let inventoryItem = cell.inventoryItem, row = cell.row {
            changeInventoryItemQuantity(cell, row: row, inventoryItem: inventoryItem, delta: delta)
        } else {
            print("Error: Cell has invalid state, inventory item and row must not be nil at this point")
        }
    }
    
    private func changeInventoryItemQuantity(cell: InventoryItemTableViewCell, row: Int, inventoryItem: InventoryItem, delta: Int) {

        if inventoryItem.quantity + delta >= 0 {
            
            Providers.inventoryItemsProvider.incrementInventoryItem(inventoryItem, delta: delta, successHandler({[weak self] result in

                if let weakSelf = self {
                    
                    weakSelf.updateIncrementUI(inventoryItem, delta: delta, cell: cell, row: row)
                    
                    if inventoryItem.quantity + delta == 0 {
                        cell.startDeleteProgress {
                            
                            weakSelf.tableView.reloadData()

                            // TODO is it necessary to have multiple [weak self] in nested blocks? (we one above in incrementInventoryItem)
                            Providers.inventoryItemsProvider.removeInventoryItem(inventoryItem, weakSelf.successHandler{[weak self] result in
                                
                                if let weakSelf = self {
                                    weakSelf.removeUI(row)
                                }
                            })
                        }
                    }
                }
            }))
        }
    }
    
    private func updateIncrementUI(inventoryItem: InventoryItem, delta: Int, cell: InventoryItemTableViewCell, row: Int) {
        let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
        inventoryItems[row] = incrementedItem
        cell.inventoryItem = incrementedItem
        cell.quantityLabel.text = "\(incrementedItem.quantity)"
    }
    
    private func removeUI(row: Int) {
        tableView.wrapUpdates {[weak self] in
            self?.inventoryItems.removeAtIndex(row)
            self?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Bottom)
        }
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        if let inventory = inventory, sortBy = sortBy {
            
            synced(self) {[weak self] in
                let weakSelf = self!
                
                if !weakSelf.paginator.reachedEnd {
                    
                    if (!weakSelf.loadingPage) {
                        setLoading(true)
                        
                        Providers.inventoryItemsProvider.inventoryItems(weakSelf.paginator.currentPage, inventory: inventory, fetchMode: .Both, sortBy: sortBy, weakSelf.successHandler{inventoryItems in
                            weakSelf.inventoryItems.appendAll(inventoryItems)
                            
                            weakSelf.paginator.update(inventoryItems.count)
                            
                            weakSelf.tableView.reloadData()
                            setLoading(false)
                        })
                    }
                }
            }
            
        } else {
            print("Warn: InventoryItemsTableViewController.loadPossibleNextPage: can't load page, inventory or sortBy not set")
        }
    }
}