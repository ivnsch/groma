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
    
    fileprivate let paginator = Paginator(pageSize: 20)
    fileprivate var loadingPage: Bool = false
    
    @IBOutlet var tableViewFooter: LoadingFooter!
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var emptyHistoryView: UIView!

    fileprivate var dateFormatter: DateFormatter!
    
    fileprivate var sectionModels: [SectionModel<HistoryItemGroup>] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    @IBOutlet weak var inventoriesButton: UIButton!
    fileprivate var inventoryPicker: InventoryPicker?
    fileprivate var selectedInventory: DBInventory? {
        didSet {
            if (selectedInventory.map{$0 != oldValue} ?? true) { // load only if it's not set (?? true) or if it's a different inventory
                loadHistory()
            }
        }
    }
    
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.topInset = 40 // (menu bar)
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        inventoryPicker = InventoryPicker(button: inventoriesButton, view: view) {[weak self] inventory in
            self?.selectedInventory = inventory
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.onWebsocketHistoryItem(_:)), name: NSNotification.Name(rawValue: WSNotificationName.HistoryItem.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.onWebsocketProduct(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Product.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.onWebsocketProductCategory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProductCategory.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.onWebsocketListItem(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ListItem.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HistoryViewController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)        
    }
    
    deinit {
        QL1("Deinit history controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadInventories()
    }
    
    fileprivate func loadInventories() {
        Providers.inventoryProvider.inventories(true, successHandler{[weak self] inventories in
            self?.inventoryPicker?.inventories = inventories
        })
    }
    
    fileprivate func loadHistory() {
        sectionModels = []
        paginator.reset() // TODO improvement either memory cache or reset only if history has changed (marked items as bought since last load)
        loadPossibleNextPage()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionModels.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionModel = sectionModels[section]
        return sectionModel.expanded ? sectionModel.obj.historyItems.count : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionModel = sectionModels[section]
        let group = sectionModel.obj
        let view = Bundle.loadView("HistoryItemGroupHeaderView", owner: self) as! HistoryItemGroupHeaderView
        
        view.userName = group.user.email
        view.date = dateFormatter.string(from: group.date)
        view.price = group.totalPrice.toLocalCurrencyString()
        
        view.sectionIndex = section
        view.sectionModel = sectionModel
        view.delegate = self
        
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell", for: indexPath) as! HistoryItemCell
        
        let historyItem = sectionModels[(indexPath as NSIndexPath).section].obj.historyItems[(indexPath as NSIndexPath).row]
        
        cell.itemNameLabel.text = historyItem.product.name
        cell.itemUnitLabel.text = "\(historyItem.quantity) x \(historyItem.paidPrice.toLocalCurrencyString())"
        cell.itemPriceLabel.text = historyItem.totalPaidPrice.toLocalCurrencyString()
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("select: \(indexPath)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
    }
    
    fileprivate func loadPossibleNextPage() {
        
        if let inventory = selectedInventory {
            
            func setLoading(_ loading: Bool) {
                self.loadingPage = loading
                self.tableViewFooter.isHidden = !loading
            }
            
            synced(self) {[weak self] in
                let weakSelf = self!
                
                if !weakSelf.paginator.reachedEnd {
                    
                    if (!weakSelf.loadingPage) {
                        setLoading(true)
                        
                        Providers.historyProvider.historyItemsGroups(weakSelf.paginator.currentPage, inventory: inventory, weakSelf.successHandler{historyItems in
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
            self.tableViewFooter.isHidden = true
        }
    }

    
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            func delete() {
                let historyItem = sectionModels[(indexPath as NSIndexPath).section].obj.historyItems[(indexPath as NSIndexPath).row]
                Providers.historyProvider.removeHistoryItem(historyItem, successHandler({[weak self] result in
                    self?.removeHistoryItemUI(indexPath)
                }))
            }
            
            let alreadyShowedPopup: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.showedDeleteHistoryItemHelp) ?? false
            if alreadyShowedPopup {
                delete()
            } else {
                AlertPopup.show(title: trans("popup_title_info"), message: trans("popup_delete_history_also_deletes_stats"), controller: self, okMsg: trans("popup_button_got_it")) {
                    PreferencesManager.savePreference(PreferencesManagerKey.showedDeleteHistoryItemHelp, value: true)
                    delete()
                }
            }

        } else if editingStyle == .insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    fileprivate func removeHistoryItemUI(_ indexPath: IndexPath) {
        tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
            weakSelf.tableView.deleteRows(at: [indexPath], with: .bottom)
            let section = weakSelf.sectionModels[(indexPath as NSIndexPath).section]
            let group = section.obj
            var historyItems = group.historyItems
            historyItems.remove(at: (indexPath as NSIndexPath).row)
            let updatedGroup = group.copy(historyItems: historyItems)
            weakSelf.sectionModels[(indexPath as NSIndexPath).section] = SectionModel(expanded: section.expanded, obj: updatedGroup)
        }
    }

    fileprivate func removeHistoryItemUI(_ historyItemUuid: String) -> Bool {
        for (sectionIndex, sectionModel) in sectionModels.enumerated() {
            for (itemIndex, item) in sectionModel.obj.historyItems.enumerated() {
                if item.uuid == historyItemUuid {
                    removeHistoryItemUI(IndexPath(row: itemIndex, section: sectionIndex))
                    _ = sectionModel.obj.historyItems.removeUsingIdentifiable(item)
                    return true
                }
            }
        }
        QL1("HistoryItem was not in table view: \(historyItemUuid)")
        return false
    }
    
    fileprivate func removeHistoryItemUI(_ historyItem: HistoryItem) {
        _ = removeHistoryItemUI(historyItem.uuid)
    }

    // MARK: - HistoryItemGroupHeaderViewDelegate
    
    func onHeaderTap(_ header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        if header.open {
            header.open = false
        } else {
            setHeaderExpanded(header, sectionIndex: sectionIndex, sectionModel: sectionModel)
        }
    }
    
    func onDeleteGroupTap(_ sectionModel: SectionModel<HistoryItemGroup>, header: HistoryItemGroupHeaderView) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("history_delete_items_in_group"), okTitle: trans("popup_button_ok"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {[weak self] in guard let weakSelf = self else {return}
            Providers.historyProvider.removeHistoryItemsGroup(sectionModel.obj, remote: true, weakSelf.successHandler{
                weakSelf.loadHistory()
            })
        }, onCancel: nil)
    }

    // MARK: -
    
    fileprivate func setHeaderExpanded(_ header: HistoryItemGroupHeaderView, sectionIndex: Int, sectionModel: SectionModel<HistoryItemGroup>) {
        
        let sectionIndexPaths: [IndexPath] = (0..<sectionModel.obj.historyItems.count).map {
            return IndexPath(row: $0, section: sectionIndex)
        }
        
        if sectionModel.expanded { // collapse
            tableView.wrapUpdates {[weak self] in
                self?.tableView.deleteRows(at: sectionIndexPaths, with: .top)
                sectionModel.expanded = false
            }
        } else { // expand
            
            tableView.wrapAnimationAndUpdates({[weak self] in
                self?.tableView.insertRows(at: sectionIndexPaths, with: .top)
                sectionModel.expanded = true
            }, onComplete: {[weak self] in
                self?.tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: sectionIndex), at: UITableViewScrollPosition.top, animated: true)
            })
        }
    }
    
    
    // MARK: - Websocket
    
    func onWebsocketHistoryItem(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<HistoryItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    _ = removeHistoryItemUI(notification.obj)
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<[String]>> { // group - see note in MyWebsocketDispatcher for explanation
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
    
    func onWebsocketProduct(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    loadHistory()
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onWebsocketProductCategory(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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

    func onWebsocketListItem(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<RemoteBuyCartResult>> {
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
    func onWebsocketInventoryWithHistoryAfterSave(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSEmptyNotification> {
            
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    loadHistory()
                default: QL4("Error: InventoryItemsViewController.onWebsocketInventoryWithHistoryAfterSave: History: not implemented: \(notification.verb)")
                }
            }
        }
    }
    
    func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
        // TODO notification - note has the sender name
        selectedInventory = nil // cause to reload in all cases
        loadInventories()
    }
}
