//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController, ListItemsTableViewDelegate, ItemsObserver {

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
    }
    
    func onListItemDoubleTap(listItem: ListItem, indexPath: NSIndexPath) {
        self.setItemUndone(listItem, indexPath: indexPath)
    }
    
    private func setItemUndone(listItem:ListItem, indexPath: NSIndexPath) {
        listItem.done = false
        
        self.listItemsProvider.update(listItem)
        self.listItemsTableViewController.removeListItem(listItem, indexPath: indexPath)
        
        itemsNotificator?.notifyItemUpdated(listItem, sender: self)
    }
    
    func itemsChanged() {
        self.initItems()
    }
    
    private func initItems() {
        let items = listItemsProvider.listItems().filter{$0.done}
        self.listItemsTableViewController.setListItems(items)
    }
}