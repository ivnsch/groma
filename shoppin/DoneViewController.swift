//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController, ListItemsTableViewDelegate, ItemsObserver, SideMenuObserver {

    private var listItemsTableViewController:ListItemsTableViewController!

    private let listItemsProvider = ProviderFactory().listItemProvider

    var itemsNotificator:ItemsNotificator?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        self.initItems()
    }

    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        self.listItemsTableViewController.style = .Gray

        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        
        self.listItemsTableViewController.listItemsTableViewDelegate = self
        
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
    }
    
    func onListItemClear(tableViewListItem:TableViewListItem) {
        self.setItemUndone(tableViewListItem.listItem)
    }
    
    func changedSlideOutState(slideOutState: SlideOutState) {
    }

    func startSideMenuDrag() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func setItemUndone(listItem:ListItem) {
        listItem.done = false
        
        self.listItemsProvider.update(listItem)
        self.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
        
        itemsNotificator?.notifyItemUpdated(listItem, sender: self)
    }
    
    func itemsChanged() {
        self.initItems()
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func initItems() {
        let items = listItemsProvider.listItems().filter{$0.done}
        self.listItemsTableViewController.setListItems(items)
    }
}