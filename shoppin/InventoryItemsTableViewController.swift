//
//  InventoryItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol InventoryItemsTableViewControllerDelegate {
    func onInventoryItemSelected(inventoryItem: InventoryItem, indexPath: NSIndexPath)
    func onLoadedInventoryItems(inventoryItems: [InventoryItem]) // passes all inventory items currently in controller, after load (not only loaded page)
}

class InventoryItemsTableViewController: UITableViewController, InventoryItemTableViewCellDelegate {

    private(set) var inventoryItems: [InventoryItem] = []
    @IBOutlet var tableViewFooter: LoadingFooter!

    var sortBy: InventorySortBy?
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready
    
    var inventory: Inventory? {
        didSet {
            clearAndLoadFirstPage()
        }
    }
    
    var tableViewTopInset: CGFloat {
        get {
            return tableView.topInset
        }
        set {
            tableView.topInset = newValue
        }
    }
    
    var delegate: InventoryItemsTableViewControllerDelegate?
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    func clearAndLoadFirstPage() {
        inventoryItems = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        tableView.allowsSelectionDuringEditing = true
    }
    
    override func viewWillAppear(animated:Bool) {
        onViewWillAppear?()
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
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
         
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            let planItem = inventoryItems[indexPath.row]
            tableView.wrapUpdates {[weak self] in
                self?.inventoryItems.remove(planItem)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            }
            Providers.inventoryItemsProvider.removeInventoryItem(planItem, remote: true, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.inventory = self?.inventory // trigger reset and reload
                self?.defaultErrorHandler()(providerResult: result)
            }))
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let inventoryItem = inventoryItems[indexPath.row]
        delegate?.onInventoryItemSelected(inventoryItem, indexPath: indexPath)
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
                            Providers.inventoryItemsProvider.removeInventoryItem(inventoryItem, remote: true, weakSelf.successHandler{[weak self] result in
                                
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

    func updateIncrementUI(inventoryItem: InventoryItem, delta: Int) {
        if let (index, item) = (inventoryItems.enumerate().filter{$0.element.same(inventoryItem)}.first), cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? InventoryItemTableViewCell {
                updateIncrementUI(item, delta: delta, cell: cell, row: index)
            } else {
                print("Warn: InventoryItemsTableViewController.updateIncrementUI: Couldn't retrieve cell for index: \(index)")
            }
        } else {
            print("Warn: InventoryItemsTableViewController.updateIncrementUI: Didn't find inventoryItem: \(inventoryItem)")
        }
    }
    
    private func updateIncrementUI(inventoryItem: InventoryItem, delta: Int, cell: InventoryItemTableViewCell, row: Int) {
        let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
        inventoryItems[row] = incrementedItem
        cell.inventoryItem = incrementedItem
        cell.quantityLabel.text = "\(incrementedItem.quantity)"
    }
    
    func remove(inventoryItem: InventoryItem) {
        if let (index, _) = (inventoryItems.enumerate().filter{$0.element.same(inventoryItem)}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: \(inventoryItem)")
        }
    }
    
    func remove(inventoryItemInventoryUuid: String, inventoryItemProductUuid: String) {
        if let (index, _) = (inventoryItems.enumerate().filter{$0.element.inventory.uuid == inventoryItemInventoryUuid && $0.element.product.uuid == inventoryItemProductUuid}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: inventoryItemInventoryUuid: \(inventoryItemInventoryUuid), inventoryItemProductUuid: \(inventoryItemProductUuid)")
        }
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
                            
                            weakSelf.delegate?.onLoadedInventoryItems(weakSelf.inventoryItems)
                            
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