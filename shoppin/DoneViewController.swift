//
//  DoneViewController.swift
//  shoppin
//
//  Created by ischuetz on 26.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol CartViewControllerDelegate {
    func onEmptyCartTap()
}

class DoneViewController: UIViewController, ListItemsTableViewDelegate {

    private var listItemsTableViewController: ListItemsTableViewController!
    
    var list: List? {
        didSet { // TODO check if there's a timing problem when we implement memory cache, this may be called before it's displayed (so we see no listitems)?
            loadList()
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
    
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var totalDonePriceLabel: UILabel!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyCartLabel: UILabel!
    @IBOutlet weak var emptyCartStashLabel: UILabel!
    
    var delegate: CartViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableViewController()
        
        navigationController?.setNavigationBarHidden(false, animated: true)

        navigationItem.title = "Cart"
        
        onUIReady?()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItems:", name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItem:", name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSection:", name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryWithHistoryAfterSave:", name: WSNotificationName.InventoryItemsWithHistoryAfterSave.rawValue, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    private func loadList() {
        if let list = list {
            initWithList(list)
        }
    }
    
    private func initWithList(list: List) {
        
        Providers.listItemsProvider.listItems(list, sortOrderByStatus: .Done, fetchMode: .MemOnly, successHandler{[weak self] listItems in
            
            if let weakSelf = self {
                let doneListItems = listItems.filter{$0.hasStatus(.Done)}
                weakSelf.listItemsTableViewController.setListItems(doneListItems)
                self?.updateEmptyView()
                self?.updatePriceView()
            }
        })
        // FIXME note that list's listItems are not set, so we don't use this, maybe just remove this variable, or set it
//        let donelistItems = list.listItems.filter{$0.done}
//        self.listItemsTableViewController.setListItems(donelistItems)
    }
    
    private func updatePriceView() {
        totalDonePriceLabel.text = listItemsTableViewController.totalPrice.toLocalCurrencyString()
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
                Providers.listItemsProvider.listItemCount(.Stash, list: list, fetchMode: .Both, successHandler {[weak self] count in
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
        listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
            self?.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    private func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        listItemsTableViewController.style = .Gray

        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)

        listItemsTableViewController.listItemsTableViewDelegate = self
        
        listItemsTableViewController.status = .Done
        //TODO the tap recognizer to clearPendingSwipeItemIfAny should be in listItemsTableViewController instead of here and in ViewController- but it didn't work (quickly) there
//        let gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
//        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        
//        self.listItemsTableViewController.tableViewShiftDown(64)
    }
    
    // MARK: - ListItemsTableViewDelegate

    func onListItemClear(tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        if let list = self.list {
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status1: .Done, status: .Todo, mode: .Single, remote: notifyRemote) {[weak self] result in
                if result.success {
                    self!.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
                    self?.updateEmptyView()
                    self?.updatePriceView()
                }
                onFinish()
            }
        } else {
            onFinish()
        }
    }

    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true)
        updatePriceView()
    }
    
    private func sendAllItemToStash(onFinish: VoidFunction) {
        if let list = self.list {
            Providers.listItemsProvider.switchStatus(self.listItemsTableViewController.items, list: list, status1: .Done, status: .Stash, mode: .All, remote: true) {[weak self] result in
                if result.success {
                    self?.listItemsTableViewController.setListItems([])
                    self?.updateEmptyView()
                    self?.updatePriceView()
                    onFinish()
                }
            }
        }
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        updatePriceView()
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        // do nothing
    }
    
    func onIncrementItem(model: TableViewListItem, delta: Int) {
        // do nothing
    }
    
    func onPullToAdd() {
        // do nothing
    }
    
    func onTableViewScroll(scrollView: UIScrollView) {
    }
    
    // MARK: -
    
    func startSideMenuDrag() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    private func setItemUndone(listItem: ListItem) {

    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    @IBAction func onAddToInventoryTap(sender: UIBarButtonItem) {
        if let list = list {
            
            if InventoryAuthChecker.checkAccess(list.inventory, controller: self) {
                addAllItemsToInventory()
            }
        } else {
            print("Warn: DoneViewController.onAddToInventoryTap: list is not set, can't add to inventory")
        }
    }
    
    private func addAllItemsToInventory() {
        
        func onSizeLimitOk(list: List) {
            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
                if let weakSelf = self {
                    let inventoryItemsInput = weakSelf.listItemsTableViewController.items.map{ProductWithQuantityInput(product: $0.product, quantity: $0.doneQuantity)}
                    Providers.inventoryItemsProvider.addToInventory(list.inventory, itemInputs: inventoryItemsInput, remote: true, weakSelf.successHandler{result in
                        weakSelf.sendAllItemToStash {
                            weakSelf.close()
                        }
                    })
                }
            }
        }
        
        if let list = list {
            Providers.inventoryItemsProvider.countInventoryItems(list.inventory, successHandler {[weak self] count in
                if let weakSelf = self {
                    SizeLimitChecker.checkInventoryItemsSizeLimit(count, controller: weakSelf) {
                        onSizeLimitOk(list)
                    }
                }
            })
        } else {
            print("Warn: DoneViewController.addAllItemsToInventory: list is not set, can't add to inventory")
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
    
    // MARK: - Websocket
    
    func onWebsocketListItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[ListItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Update:
                    listItemsTableViewController.updateListItems(notification.obj, status: .Done, notifyRemote: false)
                    
                default: print("Error: DoneViewController.onWebsocketUpdateListItems: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: DoneViewController.onWebsocketAddListItems: no value")
            }
        } else {
            print("Error: DoneViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketListItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ListItem>> {
            if let notification = info[WSNotificationValue] {
                
                let listItem = notification.obj
                
                switch notification.verb {
                case .Add:
                    listItemsTableViewController.updateOrAddListItem(listItem, status: .Done, increment: true, scrollToSelection: true, notifyRemote: false)
                    
                case .Update:
                    listItemsTableViewController.updateListItem(listItem, status: .Done, notifyRemote: false)
                    
                case .Delete:
                    listItemsTableViewController.removeListItem(listItem)
                    
                default: QL4("Not handled verb: \(notification.verb)")
                }
            } else {
                print("Error: DoneViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: DoneViewController.onWebsocketAddListItems: no userInfo")
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
                default: print("Error: DoneViewController.onWebsocketSection: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: DoneViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: DoneViewController.onWebsocketAddListItems: no userInfo")
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
                print("Error: DoneViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: DoneViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    // This is called when added items to inventory which means they were removed from done controller, so we have to remove them
    func onWebsocketInventoryWithHistoryAfterSave(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSEmptyNotification> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadList()
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
        }
    }
}