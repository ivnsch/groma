//
//  StashViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// content copied from done view controller (except stash item status) - commented code probably outdated. TODO cleanup
class StashViewController: UIViewController, ListItemsTableViewDelegate {
    
    private var listItemsTableViewController: ListItemsTableViewController!
    
    var list: List? {
        didSet { // TODO check if there's a timing problem when we implement memory cache, this may be called before it's displayed (so we see no listitems)?
            if let list = list {
                initWithList(list)
            }
        }
    }
    
    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()
     
        navigationController?.setNavigationBarHidden(false, animated: true)

        onUIReady?()
    }
    
    private func initWithList(list: List) {
        
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{[weak self] listItems in
            let listItems = listItems.filter{$0.status == .Stash}
            self?.listItemsTableViewController.setListItems(listItems)
        })
        // FIXME note that list's listItems are not set, so we don't use this, maybe just remove this variable, or set it
        //        let donelistItems = list.listItems.filter{$0.done}
        //        self.listItemsTableViewController.setListItems(donelistItems)
    }
    
    @IBAction func onCloseTap(sender: UIButton) {
        close()
    }
    
    private func close() {
        listItemsTableViewController.clearPendingSwipeItemIfAny {
            presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    private func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        listItemsTableViewController.style = .Gray
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.listItemsTableViewDelegate = self
        
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
        //        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        //        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        
        //        self.listItemsTableViewController.tableViewShiftDown(64)
    }
    
    func onListItemClear(tableViewListItem: TableViewListItem, onFinish: VoidFunction) {
        if let list = list {
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status: .Todo) {[weak self] result in
                if result.success {
                    self?.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
                }
                onFinish()
            }
        } else {
            onFinish()
        }
    }
    
    func startSideMenuDrag() {
        listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func setItemUndone(listItem: ListItem) {
        
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        listItemsTableViewController.markOpen(true, indexPath: indexPath)
    }
    
    private func resetAllItems() {
        if let list = list {
            Providers.listItemsProvider.switchStatus(listItemsTableViewController.items, list: list, status: .Todo) {[weak self] result in
                if result.success {
                    self?.listItemsTableViewController.setListItems([])
                    self?.close()
                }
            }
        }
    }
    
    @IBAction func onResetTap(sender: UIBarButtonItem) {
        resetAllItems()
    }
}