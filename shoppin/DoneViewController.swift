//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

protocol CartViewControllerDelegate {
    func onEmptyCartTap()
}

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
    
    var navigationItemTextColor: UIColor?
    
    var backgroundColor: UIColor? {
        didSet {
            if let backgroundColor = backgroundColor {
                view.backgroundColor = backgroundColor
                listItemsTableViewController.tableView.backgroundColor = backgroundColor
                let contrasting = UIColor(contrastingBlackOrWhiteColorOn: backgroundColor, isFlat: true)
                emptyCartLabel.textColor = contrasting
                emptyCartStashLabel.textColor = contrasting
            }
        }
    }

    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyCartLabel: UILabel!
    @IBOutlet weak var emptyCartStashLabel: UILabel!
    
    var delegate: CartViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        
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
        listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    private func initWithList(list: List) {
        
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{[weak self] listItems in
            
            if let weakSelf = self {
                let doneListItems = listItems.filter{$0.status == .Done}
                weakSelf.listItemsTableViewController.setListItems(doneListItems)
                self?.updateEmptyView()
            }
        })
        // FIXME note that list's listItems are not set, so we don't use this, maybe just remove this variable, or set it
//        let donelistItems = list.listItems.filter{$0.done}
//        self.listItemsTableViewController.setListItems(donelistItems)
    }
    
    private func updateEmptyView() {
        if let list = self.list {
            let cartEmpty = listItemsTableViewController.sections.isEmpty
            
            emptyView.hidden = !cartEmpty
            emptyCartStashLabel.hidden = true
            UIView.animateWithDuration(0.3) {[weak self] in
                self?.emptyView.alpha = cartEmpty ? 1 : 0 // note alpha starts with 0 (storyboard)
            }
            
            if cartEmpty {
                Providers.listItemsProvider.listItemCount(.Stash, list: list, successHandler {[weak self] count in
                    self?.emptyCartStashLabel.text = "There are \(count) items in the stash"
                    self?.emptyCartStashLabel.hidden = count == 0
                    UIView.animateWithDuration(0.3) {[weak self] in
                        self?.emptyCartStashLabel.alpha = count == 0 ? 0 : 1
                    }
                })
            }
        } else {
            print("Warn: DoneViewController.updateEmptyView: trying to update empty view without a list")
        }
    }
    
    @IBAction func onCloseTap(sender: UIButton) {
        close()
    }
    
    private func close() {
        listItemsTableViewController.clearPendingSwipeItemIfAny {
            navigationController?.popViewControllerAnimated(true)
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
                    self?.updateEmptyView()
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
                    self?.updateEmptyView()
                    onFinish()
                }
            }
        }
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // do nothing
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
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
        
        listItemsTableViewController.clearPendingSwipeItemIfAny {[weak self] in
            
            if let weakSelf = self {
                
                // WARN for now we assume user has always only one inventory. Note that general setup (database, server etc) supports multiple inventories though.
                Providers.inventoryProvider.inventories(weakSelf.successHandler{inventories in
                    if let inventory = inventories.first { // TODO list associated inventory
                        onHasInventory(inventory)
                        
                    } else { // user has no inventories - create first one. Note if offline there can be inventories in server - there has to be a sync when user comes online/signs up
                        let mySharedUser = ProviderFactory().userProvider.mySharedUser ?? SharedUser(email: "unknown@e.mail") // TODO how do we handle shared users internally (database etc) when user is offline
                        
                        let inventoryInput = Inventory(uuid: NSUUID().UUIDString, name: "Home", users: [mySharedUser])
                        Providers.inventoryProvider.addInventory(inventoryInput, weakSelf.successHandler{notused in
                            
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
    }
    
    @IBAction func onEmptyCartTap() {
        if !emptyCartStashLabel.hidden { // emptyCartStashLabel.hidden means: stash item count is 0 which means we don't direct the user to stash when tap on empty items button
            // quick "tapped" effect
            emptyCartLabel.textColor = emptyCartLabel.textColor.colorWithAlphaComponent(0.3)
            emptyCartStashLabel.textColor = emptyCartStashLabel.textColor.colorWithAlphaComponent(0.3)
            delay(0.3) {[weak self] in
                self?.emptyCartLabel.textColor = self?.emptyCartLabel.textColor.colorWithAlphaComponent(1)
                self?.emptyCartStashLabel.textColor = self?.emptyCartStashLabel.textColor.colorWithAlphaComponent(1)
            }
            
            delegate?.onEmptyCartTap()
        }
    }
}