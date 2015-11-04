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
    
    var navigationItemTextColor: UIColor?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()
        
        if let navigationItemTextColor = navigationItemTextColor {
            // seems there's no way to change back button text color at nav controller level so we do it statically and rever in viewWillDisappear
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: navigationItemTextColor], forState: .Normal)
            UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: navigationItemTextColor]
            navigationController?.navigationBar.translucent = false
        }
        navigationController?.setNavigationBarHidden(false, animated: true)

        onUIReady?()
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: Theme.navigationBarTextColor]
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
    
    // MARK: - ListItemsTableViewDelegate

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
    
    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        listItemsTableViewController.markOpen(true, indexPath: indexPath)
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // do nothing
    }
    
    // MARK: -
    
    func startSideMenuDrag() {
        listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func setItemUndone(listItem: ListItem) {
        
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
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