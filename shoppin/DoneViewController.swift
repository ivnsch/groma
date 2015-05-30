//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController, ListItemsTableViewDelegate, ItemsObserver, SideMenuObserver, CartMenuDelegate {

    private var listItemsTableViewController:ListItemsTableViewController!

    private let listItemsProvider = ProviderFactory().listItemProvider
    private let inventoryProvider = ProviderFactory().inventoryProvider
    
    var itemsNotificator:ItemsNotificator?

    @IBOutlet weak var cartMenu: CartMenuView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        self.initList()
        
        FrozenEffect.apply(self.cartMenu)
        
        self.cartMenu.delegate = self
    }
    
    private func initList() {
        
        var list:List
        if let listId:String = PreferencesManager.loadPreference(PreferencesManagerKey.listId) {
            list = self.listItemsProvider.list(listId)!
            
        } else {
            list = self.createList(Constants.defaultListIdentifier)
            PreferencesManager.savePreference(PreferencesManagerKey.listId, value: NSString(string: Constants.defaultListIdentifier))
        }
        
        let listItems:[ListItem] = self.listItemsProvider.listItems(list)
        
        let donelistItems = listItems.filter{$0.done}
        self.listItemsTableViewController.setListItems(donelistItems)
    }
    
    private func createList(name:String) -> List {
        let list = List(id: NSUUID().UUIDString, name: name)
        let savedList = self.listItemsProvider.add(list)
        return savedList!
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
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        let topInset = self.cartMenu.frame.height
        let bottomInset = self.tabBarController?.tabBar.frame.height
        self.listItemsTableViewController.tableViewInset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0)
    }
    
    private func setItemUndone(listItem:ListItem) {
        listItem.done = false
        
        self.listItemsProvider.update(listItem)
        self.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
        
        itemsNotificator?.notifyItemUpdated(listItem, sender: self)
    }
    
    func itemsChanged() {
        self.initList()
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    func onListItemSelected(tableViewListItem: TableViewListItem) {
        //do nothing
    }
    
    private func setAllItemsUndone() {
        let listItems = self.listItemsTableViewController.items
        for item in listItems {
            item.done = false
        }
        self.listItemsProvider.updateDone(listItems)
        self.listItemsTableViewController.setListItems([])
        
        itemsNotificator?.notifyItemsUpdated(self)
    }
    
    func onAddToInventoryTap() {
        let inventoryItems = self.listItemsTableViewController.items.map{InventoryItem(product: $0.product, quantity: $0.quantity)}
        self.inventoryProvider.addToInventory(inventoryItems)
        
        self.setAllItemsUndone()
    }
}