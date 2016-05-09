//
//  HistoryViewController.swift
//  shoppin
//
//  Created by ischuetz on 17/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

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
    
    private let cellHeight = DimensionsManager.defaultCellHeight

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.topInset = 40 // (menu bar)
        
        dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .FullStyle
        dateFormatter.timeStyle = .ShortStyle
        
        inventoryPicker = InventoryPicker(button: inventoriesButton, view: view) {[weak self] inventory in
            self?.selectedInventory = inventory
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.onWebsocketHistoryItem(_:)), name: WSNotificationName.HistoryItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.onWebsocketProduct(_:)), name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.onWebsocketProductCategory(_:)), name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.onWebsocketListItem(_:)), name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HistoryViewController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadInventories()
    }
    
    private func loadInventories() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellHeight
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
        
        cell.itemNameLabel.text = historyItem.product.name
        cell.itemUnitLabel.text = "\(historyItem.quantity) x \(historyItem.paidPrice.toLocalCurrencyString())"
        cell.itemPriceLabel.text = historyItem.totalPaidPrice.toLocalCurrencyString()
        
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
            QL2("Can't load page because there's no selected inventory")
            self.tableViewFooter.hidden = true
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
            
            func delete() {
                let historyItem = sectionModels[indexPath.section].obj.historyItems[indexPath.row]
                historyProvider.removeHistoryItem(historyItem, successHandler({[weak self] result in
                    self?.removeHistoryItemUI(indexPath)
                }))
            }
            
            let alreadyShowedPopup: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.showedDeleteHistoryItemHelp) ?? false
            if alreadyShowedPopup {
                delete()
            } else {
                AlertPopup.show(title: "Info", message: "Deleting history items will also delete their data from the stats", controller: self, okMsg: "Got it!") {
                    PreferencesManager.savePreference(PreferencesManagerKey.showedDeleteHistoryItemHelp, value: true)
                    delete()
                }
            }

        } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    private func removeHistoryItemUI(indexPath: NSIndexPath) {
        tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
            weakSelf.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Bottom)
            let section = weakSelf.sectionModels[indexPath.section]
            let group = section.obj
            var historyItems = group.historyItems
            historyItems.removeAtIndex(indexPath.row)
            let updatedGroup = group.copy(historyItems: historyItems)
            weakSelf.sectionModels[indexPath.section] = SectionModel(expanded: section.expanded, obj: updatedGroup)
        }
    }

    private func removeHistoryItemUI(historyItemUuid: String) -> Bool {
        for (sectionIndex, sectionModel) in sectionModels.enumerate() {
            for (itemIndex, item) in sectionModel.obj.historyItems.enumerate() {
                if item.uuid == historyItemUuid {
                    removeHistoryItemUI(NSIndexPath(forRow: itemIndex, inSection: sectionIndex))
                    sectionModel.obj.historyItems.removeUsingIdentifiable(item)
                    return true
                }
            }
        }
        QL1("HistoryItem was not in table view: \(historyItemUuid)")
        return false
    }
    
    private func removeHistoryItemUI(historyItem: HistoryItem) {
        removeHistoryItemUI(historyItem.uuid)
    }

    // MARK: - HistoryItemGroupHeaderViewDelegate
    
    func onHeaderTap(header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        if header.open {
            header.open = false
        } else {
            setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
        }
    }
    
    func onDeleteGroupTap(sectionModel: SectionModel<HistoryItemGroup>, header: HistoryItemGroupHeaderView) {
        ConfirmationPopup.show(title: "Confirm", message: "This will delete all the history items in this group", okTitle: "Ok", cancelTitle: "Cancel", controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Providers.historyProvider.removeHistoryItemsGroup(sectionModel.obj, remote: true, weakSelf.successHandler{
                weakSelf.loadHistory()
            })
        }, onCancel: nil)
    }

    // MARK: -
    
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
            
            tableView.wrapAnimationAndUpdates({[weak self] in
                self?.tableView.insertRowsAtIndexPaths(sectionIndexPaths, withRowAnimation: .Top)
                sectionModel.expanded = true
            }, onComplete: {[weak self] in
                self?.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: sectionIndex), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            })
        }
    }
    
    
    // MARK: - Websocket
    
    func onWebsocketHistoryItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<HistoryItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    removeHistoryItemUI(notification.obj)
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<[String]>> { // group - see note in MyWebsocketDispatcher for explanation
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadHistory()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    loadHistory()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadHistory()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProductCategory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    loadHistory()
                case .DeleteWithBrand:
                    loadHistory()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }

    func onWebsocketListItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteBuyCartResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .BuyCart:
                    loadHistory()
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
            }
            
        } else {
            QL4("No userInfo")
        }
    }
    
    // This is called when added items to inventory / history, so we have to update
    func onWebsocketInventoryWithHistoryAfterSave(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSEmptyNotification> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
        }
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        selectedInventory = nil // cause to reload in all cases
        loadInventories()
    }
}
