//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController, ListItemsTableViewDelegate, CartMenuDelegate {

    private var listItemsTableViewController: ListItemsTableViewController!

    private let listItemsProvider = ProviderFactory().listItemProvider
    private let inventoryProvider = ProviderFactory().inventoryProvider
    private let inventoryItemsProvider = ProviderFactory().inventoryItemsProvider
    
    @IBOutlet weak var cartMenu: CartMenuView!
    
    var list: List?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        
        FrozenEffect.apply(self.cartMenu)
        
        self.cartMenu.delegate = self
        
        if let list = self.list {
            initWithList(list)
        } else {
            print("Error: Invalid state: no list for done view controller!")
        }
    }

    private func initWithList(list: List) {
        
        self.listItemsProvider.listItems(list, successHandler{listItems in
            let doneListItems = listItems.filter{$0.done}
            self.listItemsTableViewController.setListItems(doneListItems)
        })
        // FIXME note that list's listItems are not set, so we don't use this, maybe just remove this variable, or set it
//        let donelistItems = list.listItems.filter{$0.done}
//        self.listItemsTableViewController.setListItems(donelistItems)
    }
    
    @IBAction func onCloseTap(sender: UIButton) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        self.listItemsTableViewController.style = .Gray

        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)

        self.listItemsTableViewController.listItemsTableViewDelegate = self
        
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        
        self.listItemsTableViewController.tableViewShiftDown(64)
    }
    
    func onListItemClear(tableViewListItem:TableViewListItem) {
        self.setItemUndone(tableViewListItem.listItem)
    }

    func startSideMenuDrag() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        let topInset = self.cartMenu.frame.height
        let bottomInset = self.tabBarController?.tabBar.frame.height
        self.listItemsTableViewController.tableViewInset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0)
    }
    
    private func setItemUndone(listItem: ListItem) {
        listItem.done = false
        
        self.listItemsProvider.update(listItem, {[weak self] `try` in
            
            if `try`.success ?? false {
                
                self!.listItemsTableViewController.removeListItem(listItem, animation: UITableViewRowAnimation.Bottom)
            }
        })
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
        self.listItemsProvider.updateDone(listItems, {[weak self] `try` in
            
            self!.listItemsTableViewController.setListItems([])
        })
    }
    
    func onAddToInventoryTap() {
        
        let onHasInventory: (Inventory) -> () = {[weak self] inventory in
            
            let inventoryItems = self!.listItemsTableViewController.items.map{InventoryItem(quantity: $0.quantity, product: $0.product, inventory: inventory)}

            self!.inventoryItemsProvider.addToInventory(inventory, items: inventoryItems, self!.successHandler{result in
                self!.setAllItemsUndone()
            })
        }
        
        // WARN for now we assume user has always only one inventory. Note that general setup (database, server etc) supports multiple inventories though.
        self.progressVisible(true)
        self.inventoryProvider.inventories(successHandler{[weak self] inventories in
            if let inventory = inventories.first {
                onHasInventory(inventory)
                
            } else { // user has no inventories - create first one. Note if offline there can be inventories in server - there has to be a sync when user comes online/signs up
                let myEmail = PreferencesManager.loadPreference(PreferencesManagerKey.email) ?? "unknown@e.mail" // TODO how do we handle shared users internally (database etc) when user is offline
                
                let inventoryInput = InventoryInput(uuid: NSUUID().UUIDString, name: "Home", users: [SharedUserInput(email: myEmail)])
                self!.inventoryProvider.addInventory(inventoryInput, self!.successHandler{notused in
                    
                    // just a hack because we need "full" shared user to create inventory based on inventory input
                    // but full shared user is deprecated and will be removed soon, because client doesn't need anything besides email (and provider, in the future)
                    // so for now we create full shared user where these attributes are empty
                    let sharedUsers = inventoryInput.users.map{SharedUser(email: $0.email, uuid: "", firstName: "", lastName: "")}
                    
                    onHasInventory(Inventory(uuid: inventoryInput.uuid, name: inventoryInput.name, users: sharedUsers))
                })
            }
        })
    }
}