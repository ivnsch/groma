//
//  HistoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, HistoryItemGroupHeaderViewDelegate {

    private let historyProvider = ProviderFactory().historyProvider
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    @IBOutlet var tableViewFooter: LoadingFooter!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var emptyHistoryView: UIView!

    private var dateFormatter: NSDateFormatter!
    
    private var sectionModels: [SectionModel<HistoryItemGroup>] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    @IBOutlet weak var inventoriesButton: UIButton!
    private var inventoryPicker: InventoryPicker?
    private var selectedInventory: Inventory? {
        didSet {
            if (selectedInventory.map{$0 != oldValue} ?? true) { // load only if it's not set (?? true) or if it's a different inventory
                loadHistory()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.topInset = 64 + 40 // (top + menu bar)
        
        dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .FullStyle
        dateFormatter.timeStyle = .ShortStyle
        
        inventoryPicker = InventoryPicker(button: inventoriesButton, view: view) {[weak self] inventory in
            self?.selectedInventory = inventory
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketHistoryItem:", name: WSNotificationName.HistoryItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketInventoryWithHistoryAfterSave:", name: WSNotificationName.InventoryItemsWithHistoryAfterSave.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadInventories()
    }
    
    private func loadInventories() {
        Providers.inventoryProvider.inventories(successHandler{[weak self] inventories in
            self?.inventoryPicker?.inventories = inventories
        })
    }
    
    private func loadHistory() {
        sectionModels = []
        paginator.reset() // TODO improvement either memory cache or reset only if history has changed (marked items as bought since last load)
        loadPossibleNextPage()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionModels.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = sectionModels[section]
        return sectionModel.expanded ? sectionModel.obj.historyItems.count : 0
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionModel = sectionModels[section]
        let group = sectionModel.obj
        let view = NSBundle.loadView("HistoryItemGroupHeaderView", owner: self) as! HistoryItemGroupHeaderView
        
        view.userName = group.user.email
        view.date = dateFormatter.stringFromDate(group.date)
        view.price = group.totalPrice.toLocalCurrencyString()
        
        view.sectionIndex = section
        view.sectionModel = sectionModel
        view.delegate = self
        
        return view
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("historyCell", forIndexPath: indexPath) as! HistoryItemCell
        
        let historyItem = sectionModels[indexPath.section].obj.historyItems[indexPath.row]
        
        // TODO format price, date
        
        cell.itemNameLabel.text = historyItem.product.name
        cell.itemUnitLabel.text = "\(historyItem.quantity) x \(historyItem.product.price.toLocalCurrencyString())"
        cell.itemPriceLabel.text = (Float(historyItem.quantity) * historyItem.product.price).toLocalCurrencyString()
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("select: \(indexPath)")
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
    }
    
    private func loadPossibleNextPage() {
        
        if let inventory = selectedInventory {
            
            func setLoading(loading: Bool) {
                self.loadingPage = loading
                self.tableViewFooter.hidden = !loading
            }
            
            synced(self) {[weak self] in
                let weakSelf = self!
                
                if !weakSelf.paginator.reachedEnd {
                    
                    if (!weakSelf.loadingPage) {
                        setLoading(true)
                        
                        weakSelf.historyProvider.historyItemsGroups(weakSelf.paginator.currentPage, inventory: inventory, weakSelf.successHandler{historyItems in
                            for historyItem in historyItems {
                                weakSelf.sectionModels.append(SectionModel(obj: historyItem))
                            }
                            
                            weakSelf.emptyHistoryView.setHiddenAnimated(weakSelf.sectionModels.count > 0)
                            
                            weakSelf.paginator.update(historyItems.count)
                            
                            weakSelf.tableView.reloadData()
                            setLoading(false)
                        })
                    }
                }
            }
            
        } else {
            print("Warn: HistoryViewController.loadPossibleNextPage: Can't load page because there's no selected inventory")
        }
    }

    
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // TODO lock? many deletes quickly could cause a crash here. >>> Or remove immediately and rever if failure result
            let historyItem = sectionModels[indexPath.section].obj.historyItems[indexPath.row]
            historyProvider.removeHistoryItem(historyItem, successHandler({result in
                
                tableView.wrapUpdates {[weak self] in
                    self?.removeHistoryItemUI(indexPath)
                }
            }))

        } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    private func removeHistoryItemUI(indexPath: NSIndexPath) {
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        let group = sectionModels[indexPath.section].obj
        var historyItems = group.historyItems
        historyItems.removeAtIndex(indexPath.row)
        let updatedGroup = group.copy(historyItems: historyItems)
        sectionModels[indexPath.section] = SectionModel(obj: updatedGroup)
    }
    
    private func removeHistoryItemUI(historyItem: HistoryItem) {
        var removed = false
        for sectionModel in sectionModels {
            for item in sectionModel.obj.historyItems {
                if item.same(historyItem) {
                    sectionModel.obj.historyItems.removeUsingIdentifiable(item)
                    removed = true
                }
            }
        }
        if !removed {
            print("Info: HistoryViewController.removeHistoryItemUI: historyItem was not in table view: \(historyItem)")
        }
    }

    // MARK: - HistoryItemGroupHeaderViewDelegate
    
    func onHeaderTap(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
    }
    
    private func setHeaderExpanded(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        
        let sectionIndexPaths: [NSIndexPath] = (0..<sectionModel.obj.historyItems.count).map {
            return NSIndexPath(forRow: $0, inSection: sectionIndex)
        }
        
        if sectionModel.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                sectionModel.expanded = false
            }
        } else { // expand
            tableView.wrapUpdates {[weak self] in
                self?.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                sectionModel.expanded = true
            }
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionIndex), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
    }
    
    
    // MARK: - Websocket
    
    func onWebsocketHistoryItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<HistoryItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    removeHistoryItemUI(notification.obj)
                default: print("Error: HistoryViewController.onWebsocketHistoryItem: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: HistoryViewController.onWebsocketHistoryItem: no value")
            }
        } else {
            print("Error: HistoryViewController.onWebsocketHistoryItem: no userInfo")
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
                print("Error: HistoryViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: HistoryViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    
    // This is called when added items to inventory / history, so we have to update
    func onWebsocketInventoryWithHistoryAfterSave(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSEmptyNotification> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: print("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
        }
    }
}
