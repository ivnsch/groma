//
//  InventoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 24/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Cocoa

class InventoryViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, InventoriesViewControllerDelegate, InventoryItemCellDelegate {

    @IBOutlet weak var tableView: NSTableView!

    private var inventoryItems: [InventoryItem] = []
    
    private let inventoryItemsProvider = ProviderFactory().inventoryItemsProvider

    @IBOutlet weak var inventoriesContainerView: NSView!
    private var inventoriesViewController: InventoriesViewController?
    private var currentInventory: Inventory? {
        return inventoriesViewController?.selectedInventory
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.initInventoriesViewController()
        
        self.tableView.reloadData()
    }
    
    private func initInventoriesViewController() {
        let inventoriesViewController = InventoriesViewController(nibName: "InventoriesViewController", bundle: nil)!
        inventoriesViewController.view.frame = self.inventoriesContainerView.frame
        inventoriesViewController.delegate = self
        inventoriesContainerView.addSubview(inventoriesViewController.view) // this has to be called from viewDidAppear (or later), otherwise crash because unrecognizer tableview delegate selector
        self.inventoriesViewController = inventoriesViewController
    }
    
    
    private func selectInventory(inventory: Inventory) {
        self.inventoryItemsProvider.inventoryItems(inventory, successHandler{[weak self] inventoryItems in
            self?.inventoryItems = inventoryItems
            self?.tableView.reloadData()
        })
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return self.inventoryItems.count
        
    }
    
    //    func tableView(tableView: NSTableView!, objectValueForTableColumn tableColumn: NSTableColumn!, row: Int) -> AnyObject! {
    //        println("column: \(tableColumn)")
    //        return "foo"
    //    }

    // MARK: - NSTableViewDelegate
    

    
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let cell = tableView.makeViewWithIdentifier("inventoryItem", owner: self) as! InventoryItemCell
        
        cell.delegate = self
        cell.inventoryItem = self.inventoryItems[row]
        
        return cell
    }
    
    // MARK: - InventoriesViewControllerDelegate
    
    func inventorySelected(inventory: Inventory) {
        self.selectInventory(inventory)
    }
}
