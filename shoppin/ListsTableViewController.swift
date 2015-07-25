//
//  ListsViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ListsTableViewController: UITableViewController {

    private let listItemsProvider = ProviderFactory().listItemProvider

    private var lists: [List]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelectionDuringEditing = true
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lists?.count ?? 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! ListTableViewCell
    
        if let lists = self.lists {
            let list = lists[indexPath.row]
            cell.listName.text = list.name
        }
        
        return cell
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // in view will appear so when the modal to add/edit list is dismissed, the new data is loaded
        self.listItemsProvider.lists(successHandler{lists in
            self.lists = lists
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
        if segueName == "showListItemsController" {
            if let indexPath = self.tableView.indexPathForSelectedRow, lists = self.lists, listItemsController = segue.destinationViewController as? ViewController {
                listItemsController.currentList = lists[indexPath.row]
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {            
            if let indexPath = self.tableView.indexPathForSelectedRow, lists = self.lists {
                self.showAddOrEditListViewController(true, listToEdit: lists[indexPath.row])
            }
            
        } else {
            self.performSegueWithIdentifier("showListItemsController", sender: self)
        }
    }
    
    private func showAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) {
        let editListViewController = UIStoryboard.editListsViewController()
        editListViewController.isEdit = isEdit
        if let listToEdit = listToEdit {
            editListViewController.prefill(listToEdit)
        }
        self.presentViewController(editListViewController, animated: true, completion: nil)
    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        self.showAddOrEditListViewController(false)
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true)
    }
}
