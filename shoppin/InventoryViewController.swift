//
//  InventoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoryViewController: UITableViewController {

    private var inventoryItems: [InventoryItem] = []

    private let inventoryProvider = ProviderFactory().inventoryProvider
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadInventoryItems()
        
        self.tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
    }
    
    override func viewWillAppear(animated:Bool) {
        self.loadInventoryItems()
    }
    
    func loadInventoryItems() {
        self.inventoryProvider.inventory(successHandler{[weak self] inventoryItems in
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
        let cell = tableView.dequeueReusableCellWithIdentifier("inventoryCell", forIndexPath: indexPath) as! InventoryTableViewCell

        let inventoryItem = self.inventoryItems[indexPath.row]
        
        cell.nameLabel.text = inventoryItem.product.name
        cell.quantityLabel.text = String(inventoryItem.quantity)

        // this was initially a local function but it seems we have to use a closure, see http://stackoverflow.com/a/26237753/930450
        let incrementItem = {(quantity: Int) -> () in
            let newQuantity = inventoryItem.quantity + quantity
            if (newQuantity >= 0) {
                inventoryItem.quantity += quantity
                self.inventoryProvider.updateInventoryItem(inventoryItem)
                cell.quantityLabel.text = String(inventoryItem.quantity)
            }
        }
        
        cell.onPlusTap = {
            incrementItem(1)
        }
        
        cell.onMinusTap = {
            incrementItem(-1)
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
}
