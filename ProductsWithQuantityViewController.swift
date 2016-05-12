//
//  ProductsWithQuantityViewController.swift
//  shoppin
//
//  Created by ischuetz on 03/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import QorumLogs

protocol ProductsWithQuantityViewControllerDelegate: class {
    func loadModels(page: NSRange, sortBy: InventorySortBy, onSuccess: [ProductWithQuantity] -> Void)
    func remove(model: ProductWithQuantity, onSuccess: VoidFunction, onError: ProviderResult<Any> -> Void)
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: Int -> Void)
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
    func onEmpty(empty: Bool)
    func onTableViewScroll(scrollView: UIScrollView)
    
    func isPullToAddEnabled() -> Bool
    func onPullToAdd()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    private weak var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    private(set) var models: [ProductWithQuantity] = []

    var sortBy: InventorySortBy? = .Count
    @IBOutlet weak var sortByButton: UIButton!
//    private var sortByPopup: CMPopTipView?
    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewImg: UIImageView!
    @IBOutlet weak var emptyViewLabel1: UILabel!
    @IBOutlet weak var emptyViewLabel2: UILabel!
    
    weak var delegate: ProductsWithQuantityViewControllerDelegate?
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready

    let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private let cellHeight = DimensionsManager.defaultCellHeight
    
    func clearAndLoadFirstPage() {
        models = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        if delegate?.isPullToAddEnabled() ?? false {
            let refreshControl = PullToAddHelper.createPullToAdd(self)
            tableViewController.refreshControl = refreshControl
            refreshControl.addTarget(self, action: #selector(ProductsWithQuantityViewController.onPullRefresh(_:)), forControlEvents: .ValueChanged)
        }
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ProductsWithQuantityViewController.onEmptyInventoryViewTap(_:)))
        emptyView.addGestureRecognizer(tapRecognizer)
        
        if let emptyViewData = delegate?.emptyViewData()  {
            emptyViewLabel1.text = emptyViewData.text
            emptyViewLabel2.text = emptyViewData.text2
            emptyViewImg.image = UIImage(named: emptyViewData.imgName)
        }
    }
    
    func onPullRefresh(sender: UIRefreshControl) {
        sender.endRefreshing()
        delegate?.onPullToAdd()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destinationViewController as! UITableViewController
            tableViewController.tableView.dataSource = self
            tableViewController.tableView.delegate = self
        }
    }
    
    func onEmptyInventoryViewTap(sender: UITapGestureRecognizer) {
        delegate?.onEmptyViewTap()
    }
    
    override func viewWillAppear(animated:Bool) {
        onViewWillAppear?()
        
        tableView.allowsSelectionDuringEditing = true
        
        if let _ = tabBarController?.tabBar.frame.height {
            // TODO this is not enough, why?
//            tableView.bottomInset = tabBarHeight + Constants.tableViewAdditionalBottomInset
            tableView.bottomInset = 120
        } else {
            QL3("No tabBarController: \(tabBarController)")
        }
        
        clearAndLoadFirstPage()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("inventoryCell", forIndexPath: indexPath) as! ProductWithQuantityTableViewCell
        
        let model = self.models[indexPath.row]
        
        cell.model = model
        cell.row = indexPath.row
        cell.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if editing {
            return .Delete
        } else {
            return .None
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            if let item = removeItemUI(indexPath) {
                delegate?.remove(item, onSuccess: {}, onError: {[weak self] result in
                    self?.clearAndLoadFirstPage()
                    self?.defaultErrorHandler()(providerResult: result)
                })
            } else {
                QL4("Invalid state! no item: \(indexPath)")
            }
        }
    }
    
    func indexPathOfItem(model: ProductWithQuantity) -> NSIndexPath? {
        for i in 0..<models.count {
            if models[i].same(model) {
                return NSIndexPath(forRow: i, inSection: 0)
            }
        }
        return nil
    }
    
    // The optional handling is not necessary for this class, but we write it like this for subclasses that remove item externally (e.g. websocket)
    func removeItemUI(indexPath: NSIndexPath) -> ProductWithQuantity? {
        let itemMaybe = models[safe: indexPath.row]
        if let item = itemMaybe {
            tableView.wrapUpdates {[weak self] in
                self?.models.remove(item)
                self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                self?.updateEmptyUI()
            }
        }
        return itemMaybe
    }

    func appendItemUI(item: ProductWithQuantity, scrollToCell: Bool) {
        
        // Warning (depending where this is used): this adds the inventory item at the end of the current page - this may look a bit buggy and if user scrolls down the item may be "repeated", but for now don't have a better solution,
        // the alternative which is loading all the pages until we are in the page where the position of the item is correct (according to current sorting criteria) is inefficient as well as difficult to implement
        // a compromise is to choose a big enough page size where most users will have smaller inventories, so this can't happen
        
        var insertedIndexPath: NSIndexPath?
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                if let indexPathToInsert = weakSelf.findIndexPathForNewItem(item)  { // note: before append
                    weakSelf.models.insert(item, atIndex: indexPathToInsert.row)
                    weakSelf.tableView.insertRowsAtIndexPaths([indexPathToInsert], withRowAnimation: .Top)
                    weakSelf.updateEmptyUI()
                    
                    insertedIndexPath = indexPathToInsert
                } else {
                    QL4("No indexPathToInsert")
                }
            }
        }
        
        if scrollToCell {
            if let insertedIndexPath = insertedIndexPath {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: insertedIndexPath.row, inSection: 0), atScrollPosition: .Top, animated: true)
            }
        }
    }
    
    func updateModelUI(same: ProductWithQuantity -> Bool, updatedModel: ProductWithQuantity) -> Bool {
        for i in 0..<models.count {
            if same(models[i]) {
                models[i] = updatedModel
                tableView.reloadData()
                return true
            }
        }
        return false
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
        
        delegate?.onTableViewScroll(scrollView)
    }
    
    func updateEmptyUI() {
        emptyView.setHiddenAnimated(!models.isEmpty)
        delegate?.onEmpty(models.isEmpty)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let model = models[indexPath.row]
        delegate?.onModelSelected(model, indexPath: indexPath)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
    }
    
    // MARK: - ProductWithQuantityTableViewCellDelegate
    
    func onIncrementItemTap(cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        self.checkChangeInventoryItemQuantity(cell, delta: 1)
    }
    
    func onDecrementItemTap(cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        self.checkChangeInventoryItemQuantity(cell, delta: -1)
    }
    
    func onPanQuantityUpdate(cell: ProductWithQuantityTableViewCell, newQuantity: Int) {
        cell.cancelDeleteProgress()
        if let model = cell.model {
            checkChangeInventoryItemQuantity(cell, delta: newQuantity - model.quantity)
        } else {
            QL4("No model, can't update quantity")
        }
    }
    
    /**
    Unwrap optionals safely
    Note that despite implicitly unwrapped may look suitable here, we prefer working with ? as general approach
    */
    private func checkChangeInventoryItemQuantity(cell: ProductWithQuantityTableViewCell, delta: Int) {
        if let inventoryItem = cell.model, row = cell.row {
            changeInventoryItemQuantity(cell, row: row, inventoryItem: inventoryItem, delta: delta)
        } else {
            print("Error: Cell has invalid state, inventory item and row must not be nil at this point")
        }
    }
    
    private func changeInventoryItemQuantity(cell: ProductWithQuantityTableViewCell, row: Int, inventoryItem: ProductWithQuantity, delta: Int) {
        
        if inventoryItem.quantity + delta >= 0 {
            
            delegate?.increment(inventoryItem, delta: delta, onSuccess: {[weak self] updatedQuantity in
                
                if let weakSelf = self {
                    
                    weakSelf.updateQuantityUI(inventoryItem, updatedQuantity: updatedQuantity, cell: cell, row: row)
                    
                    if inventoryItem.quantity + delta == 0 {
                        cell.startDeleteProgress {
                            
                            weakSelf.tableView.reloadData()
                            
                            
                            weakSelf.delegate?.remove(inventoryItem, onSuccess: {
                                weakSelf.removeUI(row)
                                
                            }, onError: {result in
                            })
                        }
                    }
                }
            })
        }
    }
    
    // TODO review this method why pass delta separately? why need to pass inventory item from tableview instead of parameter inventory item?
    func updateIncrementUI(inventoryItem: ProductWithQuantity, delta: Int) {
        if let (index, item, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: delta, cell: cellMaybe, row: index)
        } else {
            print("Warn: InventoryItemsTableViewController.updateIncrementUI: Didn't find inventoryItem: \(inventoryItem)")
        }
    }
    
    // Finds tableview related data of inventory item, if it's in tableview, otherwise returns nil
    private func inventoryItemTableViewData(inventoryItem: ProductWithQuantity) -> (index: Int, item: ProductWithQuantity, cell: ProductWithQuantityTableViewCell?)? { // note item -> the item currently in tableview TODO why do we need to return this if it's "same" as parameter inventoryItem
        if let (index, item) = (models.enumerate().filter{$0.element.same(inventoryItem)}.first) {
            
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                if let cell = cell as? ProductWithQuantityTableViewCell {
                    return (index, item, cell)
                    
                } else {
                    print("Error: InventoryItemsTableViewController.inventoryItemTableViewData: Cell cast failed: \(index)")
                    return nil
                }
            } else { // cell is nil (not visible)
                return (index, item, nil)
            }
            
        } else { // inventory item is not there
            return nil
        }
    }
    
    private func findIndexPathForNewItem(inventoryItem: ProductWithQuantity) -> NSIndexPath? {
        
        func findRow(isAfter: ProductWithQuantity -> Bool) -> NSIndexPath {
            let row: Int = {
                if let firstBiggerItemTuple = (models.enumerate().filter{isAfter($0.element)}).first {
                    return firstBiggerItemTuple.index // insert in above the first biggest item
                } else {
                    return models.count // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()
            return NSIndexPath(forRow: row, inSection: 0)
        }
        
        if let sortBy = sortBy {
            switch sortBy {
            case .Count:
                return findRow({
                    if $0.quantity == inventoryItem.quantity {
                        return $0.product.name > inventoryItem.product.name
                    } else {
                        return $0.quantity > inventoryItem.quantity
                    }
                })
            case .Alphabetic:
                return findRow({
                    if $0.product.name == inventoryItem.product.name {
                        return $0.quantity > inventoryItem.quantity
                    } else {
                        return $0.product.name > inventoryItem.product.name
                    }
                    
                })
            }
        } else {
            print("Warn: InventoryItemsTableViewController.findIndexPathForNewItem: sortBy is not set")
            return nil
        }
    }
    
    func addOrIncrementUI(inventoryItems: [ProductWithQuantity]) {
        for inventoryItem in inventoryItems {
            addOrIncrementUI(inventoryItem)
        }
    }

    func addOrUpdateUI(inventoryItems: [ProductWithQuantity]) {
        for inventoryItem in inventoryItems {
            addOrUpdateUI(inventoryItem, scrollToCell: false)
        }
    }

    private func tryUpdateItem(inventoryItem: ProductWithQuantity, scrollToCell: Bool) -> Bool {
        if let (index, _, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            models[index] = inventoryItem
            if let cell = cellMaybe {
                cell.model = inventoryItem
                cell.setNeedsLayout()
            }
            if scrollToCell {
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
            }
            return true
        } else {
            return false
        }
    }
    
    private func tryIncrementItem(inventoryItem: ProductWithQuantity) -> Bool {
        if let (index, item, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: inventoryItem.quantity, cell: cellMaybe, row: index)
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
            return true
        } else {
            return false
        }
    }

    func addOrUpdateUI(item: ProductWithQuantity, scrollToCell: Bool) {
        if !tryUpdateItem(item, scrollToCell: scrollToCell) {
            appendItemUI(item, scrollToCell: scrollToCell)
        }
    }
    
    func addOrIncrementUI(item: ProductWithQuantity) {
        if !tryIncrementItem(item) {
            appendItemUI(item, scrollToCell: false)
        }
    }
    
    private func updateQuantityUI(item: ProductWithQuantity, updatedQuantity: Int, cell: ProductWithQuantityTableViewCell?, row: Int) {
        let updatedItem = item.updateQuantityCopy(updatedQuantity)
        
        models[row] = updatedItem
        if let cell = cell {
            cell.model = updatedItem
            cell.quantityLabel.text = "\(updatedItem.quantity)"
        }
    }
    
    private func updateIncrementUI(inventoryItem: ProductWithQuantity, delta: Int, cell: ProductWithQuantityTableViewCell?, row: Int) {
        let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
        models[row] = incrementedItem
        if let cell = cell {
            cell.model = incrementedItem
            cell.quantityLabel.text = "\(incrementedItem.quantity)"
        }
    }
    
    func remove(inventoryItem: ProductWithQuantity) {
        if let (index, _) = (models.enumerate().filter{$0.element.same(inventoryItem)}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: \(inventoryItem)")
        }
    }
    
    func remove(inventoryItemInventoryUuid: String, inventoryItemProductUuid: String) {
        if let (index, _) = (models.enumerate().filter{$0.element.product.uuid == inventoryItemProductUuid}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: inventoryItemInventoryUuid: \(inventoryItemInventoryUuid), inventoryItemProductUuid: \(inventoryItemProductUuid)")
        }
    }
    
    private func removeUI(row: Int) {
        tableView.wrapUpdates {[weak self] in
            self?.models.removeAtIndex(row)
            self?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Bottom)
        }
        updateEmptyUI()
    }
    
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            let tableViewFooter = tableViewController.view.viewWithTag(ViewTags.TableViewFooter) as? LoadingFooter
            tableViewFooter?.hidden = !loading
        }
        
        if let sortBy = sortBy {
            
            synced(self) {[weak self] in
                let weakSelf = self!
                
                if !weakSelf.paginator.reachedEnd {
                    
                    if (!weakSelf.loadingPage) {
                        setLoading(true)
                        
                        weakSelf.delegate?.loadModels(weakSelf.paginator.currentPage, sortBy: sortBy) {inventoryItems in
                            
                            // Make sure if handler called multiple times (e.g. db result is different than mem cache result, which causes handler to be called again with db result) the items cleared, otherwise we get duplicates
                            if weakSelf.paginator.isFirstPage {
                                weakSelf.models = []
                            }
                            
                            weakSelf.models.appendAll(inventoryItems)
                            weakSelf.paginator.update(inventoryItems.count)
                            weakSelf.tableView.reloadData()
                            weakSelf.updateEmptyUI()
                            setLoading(false)
                        }
                    }
                }
            }
            
        } else {
            print("Warn: InventoryItemsTableViewController.loadPossibleNextPage: can't load page, sortBy not set")
        }
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy = sortByOption.value
        sortByButton.setTitle(sortByOption.key, forState: .Normal)
        
        clearAndLoadFirstPage()
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    @IBAction func onSortByTap(sender: UIButton) {
//        if let popup = self.sortByPopup {
//            popup.dismissAnimated(true)
//        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sortByButton, inView: view, animated: true)
//        }
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}