//
//  ListsViewController.swift
//  shoppin
//
//  Created by ischuetz on 20/07/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class ListsTableViewController: UITableViewController, EditListViewControllerDelegate {

    private let listItemsProvider = ProviderFactory().listItemProvider

    private var lists: [List]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelectionDuringEditing = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.listItemsProvider.lists(successHandler{lists in
            if (self.lists.map{$0 != lists} ?? true) { // if current list is nil or the provider list is different
                self.lists = lists
                self.tableView.reloadData()
            }
        })
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
                let list = lists[indexPath.row] // having this outside of the onViewWillAppear appears to have fixed an inexplicable bad access in the currentList assignement line
                listItemsController.onViewWillAppear = {
                    listItemsController.currentList = list
                }
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {            
            if let indexPath = self.tableView.indexPathForSelectedRow, lists = self.lists {
                self.showAddOrEditListViewController(true, listToEdit: lists[indexPath.row])
            }
            
        } else {
            triggerListItemsControllerSegue()
        }
    }
    
    private func triggerListItemsControllerSegue() {
        self.performSegueWithIdentifier("showListItemsController", sender: self)
    }
    
    private func createAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) -> EditListViewController {
        let editListViewController = UIStoryboard.editListsViewController()
        editListViewController.isEdit = isEdit
        if let listToEdit = listToEdit {
            editListViewController.listToEdit = listToEdit
        }
        editListViewController.delegate = self
        return editListViewController
    }
    
    private func showAddOrEditListViewController(isEdit: Bool, listToEdit: List? = nil) {
        let editListViewController = createAddOrEditListViewController(isEdit, listToEdit: listToEdit)
        presentViewController(editListViewController, animated: true, completion: nil)
    }

    @IBAction func onAddTap(sender: UIBarButtonItem) {
        self.showAddOrEditListViewController(false)
    }
    
    @IBAction func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true) 
    }
    
    
    // MARK: - EditListViewController
    
    func onListAdded(list: List) {
        if var lists = self.lists {
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: lists.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.lists!.append(list)
                
                self?.dismissViewControllerAnimated(true) {
                    self?.tableView.selectRowAtIndexPath(NSIndexPath(forRow: lists.count, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.None) // This is used for visuals and because prepareForSegue uses selected index path to retrieve list to pass to controller
                    self?.triggerListItemsControllerSegue()
                }
            }
        }
    }
    
    
    func onListUpdated(list: List) {
        lists?.update(list)
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
}
