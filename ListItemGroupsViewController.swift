//
//  ListItemGroupsViewController.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ListItemGroupsViewControllerDelegate {
    func onGroupsAdded()
}

class ListItemGroupsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ListItemGroupCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private var groups: [ListItemGroupWithQuantity] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var delegate: ListItemGroupsViewControllerDelegate?
    
    @IBOutlet weak var editGroupButton: UIBarButtonItem!

    private var selectedGroup: ListItemGroup? // for segue
    
    var list: List?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Providers.listItemGroupsProvider.groups(successHandler{[weak self] groups in
            self?.groups = groups.map{ListItemGroupWithQuantity(group: $0, quantity: 0)}
        })
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "addSegue" {
            let controller = segue.destinationViewController as! AddEditListItemGroupViewController
            controller.list = list
            
        } else if segue.identifier == "editSegue" {
            let controller = segue.destinationViewController as! AddEditListItemGroupViewController
            controller.list = list
            if let group = selectedGroup {
                controller.onViewWillAppear = {
                    controller.group = group // ensure set group after outlets are initialised
                }
                
            } else {
                print("Invalid state: trying to edit group without a group")
            }
        }
    }

    @IBAction func onAddToListTap(sender: UIButton) {
        
        if let list = list {
            
            let groupItems = groups.flatMap {groupWithQuantity in
                return groupWithQuantity.group.items.map {groupItem in
                    groupItem.copy(quantity: groupItem.quantity * groupWithQuantity.quantity) // if I have a 3x a group with 3 apples, I have a total of 9 apples
                }
            }

            Providers.listItemsProvider.add(groupItems, list: list, successHandler {[weak self] addedListItems in
                self?.delegate?.onGroupsAdded()
                self?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            print("Error: Invalid state: no current list in ListItemGroupsViewController")
        }
    }
    
    @IBAction func onCancelTap(sender: UIButton) {
        parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onEditGroupTap(sender: UIBarButtonItem) {
        editing = true
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("groupCell", forIndexPath: indexPath) as! ListItemGroupCell
        cell.group = groups[indexPath.row]
        cell.delegate = self
        cell.indexPath = indexPath
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return editing
    }
    
    // MARK: - UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let group = groups[indexPath.row].group
        selectedGroup = group
        performSegueWithIdentifier("editSegue", sender: self)
    }
    
    // MARK: - ListItemGroupCellDelegate

    func onDecrementItemTap(cell: ListItemGroupCell, indexPath: NSIndexPath) {
        groups[indexPath.row].quantity--
    }
    
    func onIncrementItemTap(cell: ListItemGroupCell, indexPath: NSIndexPath) {
        groups[indexPath.row].quantity++
    }
}