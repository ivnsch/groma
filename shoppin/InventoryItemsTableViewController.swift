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

    var sortBy: InventorySortBy? = .Count
    
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

    // TODO review this method why pass delta separately? why need to pass inventory item from tableview instead of parameter inventory item?
    func updateIncrementUI(inventoryItem: InventoryItem, delta: Int) {
        if let (index, item, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: delta, cell: cellMaybe, row: index)
        } else {
            print("Warn: InventoryItemsTableViewController.updateIncrementUI: Didn't find inventoryItem: \(inventoryItem)")
        }
    }
    
    // Finds tableview related data of inventory item, if it's in tableview, otherwise returns nil
    private func inventoryItemTableViewData(inventoryItem: InventoryItem) -> (index: Int, item: InventoryItem, cell: InventoryItemTableViewCell?)? { // note item -> the item currently in tableview TODO why do we need to return this if it's "same" as parameter inventoryItem
        if let (index, item) = (inventoryItems.enumerate().filter{$0.element.same(inventoryItem)}.first) {
            
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                if let cell = cell as? InventoryItemTableViewCell {
                    return (index, item, cell)
                    
                } else {
                    print("Error: InventoryItemsTableViewController.inventoryItemTableViewData: Cell cast failed: \(index)")
                    return nil
                }
            } else { // cell is nil (not visible)
                return (index, item, nil)
            }

        } else { // inventory item is not there
            return nil
        }
    }
    
    private func findIndexPathForNewItem(inventoryItem: InventoryItem) -> NSIndexPath? {
        
        func findRow(isAfter: InventoryItem -> Bool) -> NSIndexPath {
            let row: Int = {
                if let firstBiggerItemTuple = (inventoryItems.enumerate().filter{isAfter($0.element)}).first {
                    return firstBiggerItemTuple.index // insert in above the first biggest item
                } else {
                    return inventoryItems.count // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()
            return NSIndexPath(forRow: row, inSection: 0)
        }
        
        if let sortBy = sortBy {
            switch sortBy {
            case .Count:
                return findRow({$0.quantity > inventoryItem.quantity})
            case .Alphabetic:
                return findRow({$0.product.name > inventoryItem.product.name})
            }
        } else {
            print("Warn: InventoryItemsTableViewController.findIndexPathForNewItem: sortBy is not set")
            return nil
        }
    }
    
    func addOrIncrementUI(inventoryItems: [InventoryItem]) {
        for inventoryItem in inventoryItems {
            addOrIncrementUI(inventoryItem)
        }
    }
    
    private func tryIncrementItem(inventoryItem: InventoryItem) -> Bool {
        if let (index, item, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: inventoryItem.quantity, cell: cellMaybe, row: index)
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
            return true
        } else {
            return false
        }
    }
    
    func addOrIncrementUI(inventoryItem: InventoryItem) {
        if !tryIncrementItem(inventoryItem) {
            // Warning: this adds the inventory item at the end of the current page - this may look a bit buggy and if user scrolls down the item may be "repeated", but for now don't have a better solution,
            // the alternative which is loading all the pages until we are in the page where the position of the item is correct (according to current sorting criteria) is inefficient as well as difficult to implement
            // a compromise is to choose a big enough page size where most users will have smaller inventories, so this can't happen
            tableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    if let indexPathToInsert = weakSelf.findIndexPathForNewItem(inventoryItem)  { // note: before append
                        weakSelf.inventoryItems.insert(inventoryItem, atIndex: indexPathToInsert.row)
                        weakSelf.tableView.insertRowsAtIndexPaths([indexPathToInsert], withRowAnimation: .Top)
                    } else {
                        print("Error: InventoryItemsTableViewController.addOrIncrementUI: No indexPathToInsert")
                    }
                }
            }
        }
    }
    
    private func updateIncrementUI(inventoryItem: InventoryItem, delta: Int, cell: InventoryItemTableViewCell?, row: Int) {
        let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
        inventoryItems[row] = incrementedItem
        if let cell = cell {
            cell.inventoryItem = incrementedItem
            cell.quantityLabel.text = "\(incrementedItem.quantity)"
        }
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