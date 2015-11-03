//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class DoneViewController: UIViewController, ListItemsTableViewDelegate {

    private var listItemsTableViewController: ListItemsTableViewController!
    
    var list: List? {
        didSet { // TODO check if there's a timing problem when we implement memory cache, this may be called before it's displayed (so we see no listitems)?
            if let list = self.list {
                self.initWithList(list)
            }
        }
    }
    
    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        onUIReady?()
    }

    private func initWithList(list: List) {
        
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{listItems in
            let doneListItems = listItems.filter{$0.status == .Done}
            self.listItemsTableViewController.setListItems(doneListItems)
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
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        self.listItemsTableViewController.style = .Gray

        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)

        self.listItemsTableViewController.listItemsTableViewDelegate = self
        
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
//        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        
//        self.listItemsTableViewController.tableViewShiftDown(64)
    }
    
    // MARK: - ListItemsTableViewDelegate

    func onListItemClear(tableViewListItem: TableViewListItem, onFinish: VoidFunction) {
        if let list = self.list {
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status: .Todo) {[weak self] result in
                if result.success {
                    self!.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
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
    
    private func sendAllItemToStash(onFinish: VoidFunction) {
        if let list = self.list {
            Providers.listItemsProvider.switchStatus(self.listItemsTableViewController.items, list: list, status: .Stash) {[weak self] result in
                if result.success {
                    self?.listItemsTableViewController.setListItems([])
                    onFinish()
                }
            }
        }
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // do nothing
    }
    
    // MARK: -
    
    func startSideMenuDrag() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func setItemUndone(listItem: ListItem) {

    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    @IBAction func onAddToInventoryTap(sender: UIBarButtonItem) {
        addAllItemsToInventory()
    }
    
    private func addAllItemsToInventory() {
        
        let onHasInventory: (Inventory) -> () = {[weak self] inventory in
            
            let inventoryItems = self!.listItemsTableViewController.items.map{
                InventoryItemWithHistoryEntry(inventoryItem: InventoryItem(quantity: $0.quantity, quantityDelta: $0.quantity, product: $0.product, inventory: inventory), historyItemUuid: NSUUID().UUIDString, addedDate: NSDate(), user: ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail")) // TODO how do we handle shared users internally (database etc) when user is offline
            }

            Providers.inventoryItemsProvider.addToInventory(inventory, items: inventoryItems, self!.successHandler{result in
                self?.sendAllItemToStash {
                    self?.close()
                }
            })
        }
        
        // WARN for now we assume user has always only one inventory. Note that general setup (database, server etc) supports multiple inventories though.
        self.progressVisible(true)
        Providers.inventoryProvider.inventories(successHandler{[weak self] inventories in
            if let inventory = inventories.first { // TODO list associated inventory
                onHasInventory(inventory)
                
            } else { // user has no inventories - create first one. Note if offline there can be inventories in server - there has to be a sync when user comes online/signs up
                let mySharedUser = ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail") // TODO how do we handle shared users internally (database etc) when user is offline
                
                let inventoryInput = Inventory(uuid: NSUUID().UUIDString, name: "Home", users: [mySharedUser])
                Providers.inventoryProvider.addInventory(inventoryInput, self!.successHandler{notused in
                    
                    // just a hack because we need "full" shared user to create inventory based on inventory input
                    // but full shared user is deprecated and will be removed soon, because client doesn't need anything besides email (and provider, in the future)
                    // so for now we create full shared user where these attributes are empty
                    let sharedUsers = inventoryInput.users.map{SharedUser(email: $0.email)}
                    
                    onHasInventory(Inventory(uuid: inventoryInput.uuid, name: inventoryInput.name, users: sharedUsers))
                })
            }
        })
    }
}