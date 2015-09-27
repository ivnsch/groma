//
//  InventoryItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryItemsViewController: UITableViewController, InventoryItemTableViewCellDelegate {

    private var inventoryItems: [InventoryItem] = []

    private let inventoryProvider = ProviderFactory().inventoryProvider
    private let inventoryItemsProvider = ProviderFactory().inventoryItemsProvider
    
    private var inventory: Inventory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
    }
    
    override func viewWillAppear(animated:Bool) {
        self.navigationItem.title = "Inventory"
        
        inventoryProvider.firstInventory(successHandler {[weak self] inventory in
//            self.navigationItem.title = inventory.name
            self?.inventory = inventory
            self?.loadInventoryItems(inventory)
        })
    }
    
    private func loadInventoryItems(inventory: Inventory) {
        self.inventoryItemsProvider.inventoryItems(inventory, successHandler{[weak self] inventoryItems in
            self?.inventoryItems = inventoryItems
            self?.tableView.reloadData()
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
        self.checkChangeInventoryItemQuantity(cell, delta: 1)
    }
    
    func onDecrementItemTap(cell: InventoryItemTableViewCell) {
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
            
            inventoryItemsProvider.incrementInventoryItem(inventoryItem, delta: delta, successHandler({[weak self] result in
                let incrementedItem = inventoryItem.copy(quantity: inventoryItem.quantity + delta)
                self?.inventoryItems[row] = incrementedItem
                cell.quantityLabel.text = "\(incrementedItem)"
                self?.tableView.reloadData()
            }))
        }
    }
}