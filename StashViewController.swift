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

    var backgroundColor: UIColor? {
        didSet {
            if let backgroundColor = backgroundColor {
                view.backgroundColor = backgroundColor
                listItemsTableViewController.tableView.backgroundColor = backgroundColor
            }
        }
    }
    
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
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItems:", name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItem:", name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSection:", name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: Theme.navigationBarTextColor], forState: .Normal)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: Theme.navigationBarTextColor]
        listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    private func initWithList(list: List) {
        
        Providers.listItemsProvider.listItems(list, sortOrderByStatus: .Stash, fetchMode: .MemOnly, successHandler{[weak self] listItems in
            let listItems = listItems.filter{$0.hasStatus(.Stash)}
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
        listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
            self?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    private func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        listItemsTableViewController.style = .Gray
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.listItemsTableViewDelegate = self
        
        listItemsTableViewController.status = .Stash
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
        //        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        //        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        
        //        self.listItemsTableViewController.tableViewShiftDown(64)
    }
    
    // MARK: - ListItemsTableViewDelegate

    func onListItemClear(tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        if let list = list {
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status1: .Stash, status: .Todo, remote: notifyRemote) {[weak self] result in
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
        listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true)
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // do nothing
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        // do nothing
    }
    
    func onIncrementItem(model: TableViewListItem, delta: Int) {
        // do nothing
    }
    
    // MARK: -
    
    func startSideMenuDrag() {
        listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    private func setItemUndone(listItem: ListItem) {
        
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    private func resetAllItems() {
        if let list = list {
            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
                if let weakSelf = self {
                    Providers.listItemsProvider.switchStatus(weakSelf.listItemsTableViewController.items, list: list, status1: .Stash, status: .Todo, remote: true) {result in
                        if result.success {
                            weakSelf.listItemsTableViewController.setListItems([])
                            weakSelf.close()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onResetTap(sender: UIBarButtonItem) {
        resetAllItems()
    }
    
    
    // MARK: - Websocket
    
    func onWebsocketListItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[ListItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Update:
                    listItemsTableViewController.updateListItems(notification.obj, status: .Stash, notifyRemote: false)
                    
                default: print("Error: StashViewController.onWebsocketUpdateListItems: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: StashViewController.onWebsocketAddListItems: no value")
            }
        } else {
            print("Error: StashViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketListItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ListItem>> {
            if let notification = info[WSNotificationValue] {
                
                let listItem = notification.obj
                
                switch notification.verb {
                case .Add:
                    listItemsTableViewController.updateOrAddListItem(listItem, status: .Stash, increment: true, scrollToSelection: true, notifyRemote: false)
                    
                case .Update:
                    listItemsTableViewController.updateListItem(listItem, status: .Stash, notifyRemote: false)
                    
                case .Delete:
                    listItemsTableViewController.removeListItem(listItem, animation: .Bottom)
                }
            } else {
                print("Error: StashViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: StashViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketSection(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Section>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    // There's no direct add of section
                    //                case .Add:
                    //                    addProductUI(notification.obj)
                case .Update:
                    // TODO what do we do here, if we reload the list (section order can be updated, not only name) can conflict with current state e.g. if user is editing or just swiping and item. For now do nothing - user will see updated section the next time list it's loaded
                    //                    updateProductUI(notification.obj)
                    print("Warn: TODO websocket section update")
                case .Delete:
                    // TODO similar to .Update comment
                    print("Warn: TODO websocket section delete")
                default: print("Error: StashViewController.onWebsocketSection: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: StashViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: StashViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    // TODO!! update all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                case .Delete:
                    // TODO!! delete all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                print("Error: StashViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: StashViewController.onWebsocketProduct: no userInfo")
        }
    }
}