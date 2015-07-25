//
//  InventoriesTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InventoriesTableViewController: UITableViewController {
    
    private let inventoryProvider = ProviderFactory().inventoryProvider
    
    private var inventories: [Inventory]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.inventories?.count ?? 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("inventoryCell", forIndexPath: indexPath) as! InventoryTableViewCell
        
        if let inventories = self.inventories {
            let inventory = inventories[indexPath.row]
            cell.inventoryName.text = inventory.name
        }
        
        return cell
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // in view will appear so when the modal to add/edit inventory is dismissed, the new data is loaded
        self.inventoryProvider.inventories(successHandler{inventories in
            self.inventories = inventories
            self.tableView.reloadData()
        })
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let segueName = segue.identifier
        if segueName == "showInventoryItemsController" {
            if let indexPath = self.tableView.indexPathForSelectedRow, inventories = self.inventories, inventoryItemsController = segue.destinationViewController as? InventoryItemsViewController {
                inventoryItemsController.inventory = inventories[indexPath.row]
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {            
            if let indexPath = self.tableView.indexPathForSelectedRow, inventories = self.inventories {
                self.showAddOrEditListViewController(true, inventoryToEdit: inventories[indexPath.row])
            }
            
        } else {
            self.performSegueWithIdentifier("showInventoryItemsController", sender: self)
        }
    }
    
    private func showAddOrEditListViewController(isEdit: Bool, inventoryToEdit: Inventory? = nil) {
        let editInventoriesViewController = UIStoryboard.editInventoriesViewController()
        editInventoriesViewController.isEdit = isEdit
        if let inventoryToEdit = inventoryToEdit {
            editInventoriesViewController.prefill(inventoryToEdit)
        }
        self.presentViewController(editInventoriesViewController, animated: true, completion: nil)
    }
    
    @IBAction func onAddTap(sender: UIBarButtonItem) {
        self.showAddOrEditListViewController(false)
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true)
    }
}
