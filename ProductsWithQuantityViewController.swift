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
    func loadModels(_ page: NSRange, sortBy: InventorySortBy, onSuccess: @escaping ([ProductWithQuantity]) -> Void)
    func remove(_ model: ProductWithQuantity, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void)
    func increment(_ model: ProductWithQuantity, delta: Int, onSuccess: @escaping (Int) -> Void)
    func onModelSelected(_ model: ProductWithQuantity, indexPath: IndexPath)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
    func onEmpty(_ empty: Bool)
    func onTableViewScroll(_ scrollView: UIScrollView)
    
    func isPullToAddEnabled() -> Bool
    func onPullToAdd()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    fileprivate weak var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    fileprivate(set) var models: [ProductWithQuantity] = []

    @IBOutlet weak var topMenuView: UIView!
    
    var sortBy: InventorySortBy? = .count
    @IBOutlet weak var sortByButton: UIButton!
//    private var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.count, trans("sort_by_count")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewImg: UIImageView!
    @IBOutlet weak var emptyViewLabel1: UILabel!
    @IBOutlet weak var emptyViewLabel2: UILabel!
    
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: ProductsWithQuantityViewControllerDelegate?
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready

    let paginator = Paginator(pageSize: 20)
    fileprivate var loadingPage: Bool = false
    
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
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
            refreshControl.addTarget(self, action: #selector(ProductsWithQuantityViewController.onPullRefresh(_:)), for: .valueChanged)
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
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        delegate?.onPullToAdd()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedTableViewController" {
            tableViewController = segue.destination as! UITableViewController
            tableViewController.tableView.dataSource = self
            tableViewController.tableView.delegate = self
        }
    }
    
    func onEmptyInventoryViewTap(_ sender: UITapGestureRecognizer) {
        delegate?.onEmptyViewTap()
    }
    
    override func viewWillAppear(_ animated:Bool) {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as! ProductWithQuantityTableViewCell
        
        let model = self.models[(indexPath as NSIndexPath).row]
        
        cell.model = model
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if isEditing {
            return .delete
        } else {
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            if let item = removeItemUI(indexPath) {
                delegate?.remove(item, onSuccess: {}, onError: {[weak self] result in
                    self?.clearAndLoadFirstPage()
                    self?.defaultErrorHandler()(result)
                })
            } else {
                QL4("Invalid state! no item: \(indexPath)")
            }
        }
    }
    
    func indexPathOfItem(_ model: ProductWithQuantity) -> IndexPath? {
        for i in 0..<models.count {
            if models[i].same(model) {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
    }
    
    // The optional handling is not necessary for this class, but we write it like this for subclasses that remove item externally (e.g. websocket)
    func removeItemUI(_ indexPath: IndexPath) -> ProductWithQuantity? {
        let itemMaybe = models[safe: (indexPath as NSIndexPath).row]
        if let item = itemMaybe {
            tableView.wrapUpdates {[weak self] in
                _ = self?.models.remove(item)
                self?.tableView.deleteRows(at: [indexPath], with: .top)
                self?.updateEmptyUI()
            }
        }
        return itemMaybe
    }

    func appendItemUI(_ item: ProductWithQuantity, scrollToCell: Bool) {
        
        // Warning (depending where this is used): this adds the inventory item at the end of the current page - this may look a bit buggy and if user scrolls down the item may be "repeated", but for now don't have a better solution,
        // the alternative which is loading all the pages until we are in the page where the position of the item is correct (according to current sorting criteria) is inefficient as well as difficult to implement
        // a compromise is to choose a big enough page size where most users will have smaller inventories, so this can't happen
        
        var insertedIndexPath: IndexPath?
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                if let indexPathToInsert = weakSelf.findIndexPathForNewItem(item)  { // note: before append
                    weakSelf.models.insert(item, at: (indexPathToInsert as NSIndexPath).row)
                    weakSelf.tableView.insertRows(at: [indexPathToInsert], with: .top)
                    weakSelf.updateEmptyUI()
                    
                    insertedIndexPath = indexPathToInsert
                } else {
                    QL4("No indexPathToInsert")
                }
            }
        }
        
        if scrollToCell {
            if let insertedIndexPath = insertedIndexPath {
                tableView.scrollToRow(at: IndexPath(row: (insertedIndexPath as NSIndexPath).row, section: 0), at: .top, animated: true)
            }
        }
    }
    
    func updateModelUI(_ same: (ProductWithQuantity) -> Bool, updatedModel: ProductWithQuantity) -> Bool {
        for i in 0..<models.count {
            if same(models[i]) {
                models[i] = updatedModel
                tableView.reloadData()
                return true
            }
        }
        return false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
        topMenuView.setHiddenAnimated(models.isEmpty)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = models[(indexPath as NSIndexPath).row]
        delegate?.onModelSelected(model, indexPath: indexPath)
        
        if let cell = tableView.cellForRow(at: IndexPath(row: (indexPath as NSIndexPath).row, section: 0)) as? ProductWithQuantityTableViewCell {
            cell.cancelDeleteProgress()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
    }
    
    // MARK: - ProductWithQuantityTableViewCellDelegate
    
    func onIncrementItemTap(_ cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        checkChangeInventoryItemQuantity(cell, delta: 1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onDecrementItemTap(_ cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        checkChangeInventoryItemQuantity(cell, delta: -1)
        SwipeToIncrementAlertHelper.check(self)
    }
    
    func onPanQuantityUpdate(_ cell: ProductWithQuantityTableViewCell, newQuantity: Int) {
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
    fileprivate func checkChangeInventoryItemQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Int) {
        if let inventoryItem = cell.model, let indexPath = getIndexPath(inventoryItem) {
            changeInventoryItemQuantity(cell, row: (indexPath as NSIndexPath).row, inventoryItem: inventoryItem, delta: delta)
        } else {
            print("Error: Cell has invalid state, inventory item and row must not be nil at this point")
        }
    }
    
    fileprivate func getIndexPath(_ model: ProductWithQuantity) -> IndexPath? {
        for (i, m) in models.enumerated() {
            if m.same(model) {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
    }
    
    fileprivate func changeInventoryItemQuantity(_ cell: ProductWithQuantityTableViewCell, row: Int, inventoryItem: ProductWithQuantity, delta: Int) {
        
        func remove() {
            cell.startDeleteProgress {[weak self] in
                self?.remove(inventoryItem)
                
                self?.delegate?.remove(inventoryItem, onSuccess: {
                    }, onError: {[weak self] result in
                        QL4("Error ocurred - reloading first page")
                        self?.clearAndLoadFirstPage()
                })
            }
        }
        
        let newQuantity = inventoryItem.quantity + delta
        
        if newQuantity >= 0 {
            delegate?.increment(inventoryItem, delta: delta, onSuccess: {[weak self] updatedQuantity in
                self?.updateQuantityUI(inventoryItem, updatedQuantity: updatedQuantity)
                if newQuantity == 0 {
                    remove()
                }
            })
            
        } else { // user tries to decrement when the quantity is already 0 (quantity + delta is a negative number) -> start remove animation
            remove()
        }
    }

    // Finds tableview related data of inventory item, if it's in tableview, otherwise returns nil
    fileprivate func inventoryItemTableViewData(_ inventoryItem: ProductWithQuantity) -> (index: Int, item: ProductWithQuantity, cell: ProductWithQuantityTableViewCell?)? { // note item -> the item currently in tableview TODO why do we need to return this if it's "same" as parameter inventoryItem
        if let (index, item) = (models.enumerated().filter{$0.element.same(inventoryItem)}.first) {
            
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) {
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
    
    fileprivate func findIndexPathForNewItem(_ inventoryItem: ProductWithQuantity) -> IndexPath? {
        
        func findRow(_ isAfter: (ProductWithQuantity) -> Bool) -> IndexPath {
            let row: Int = {
                if let firstBiggerItemTuple = (models.enumerated().filter{isAfter($0.element)}).first {
                    return firstBiggerItemTuple.offset // insert in above the first biggest item
                } else {
                    return models.count // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()
            return IndexPath(row: row, section: 0)
        }
        
        if let sortBy = sortBy {
            switch sortBy {
            case .count:
                return findRow({
                    if $0.quantity == inventoryItem.quantity {
                        return $0.product.name > inventoryItem.product.name
                    } else {
                        return $0.quantity > inventoryItem.quantity
                    }
                })
            case .alphabetic:
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
    
    func addOrIncrementUI(_ inventoryItems: [ProductWithQuantity]) {
        for inventoryItem in inventoryItems {
            addOrIncrementUI(inventoryItem)
        }
    }

    func addOrUpdateUI(_ inventoryItems: [ProductWithQuantity]) {
        for inventoryItem in inventoryItems {
            addOrUpdateUI(inventoryItem, scrollToCell: false)
        }
    }
    
    func scrollToItem(_ item: ProductWithQuantity) {
        if let indexPath = indexPathOfItem(item) {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        } else {
            QL2("Didn't find item to scroll to")
        }
    }

    fileprivate func tryUpdateItem(_ inventoryItem: ProductWithQuantity, scrollToCell: Bool) -> Bool {
        if let (index, _, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            models[index] = inventoryItem
            if let cell = cellMaybe {
                cell.model = inventoryItem
                cell.setNeedsLayout()
            }
            if scrollToCell {
                tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
            }
            return true
        } else {
            return false
        }
    }
    
    fileprivate func tryIncrementItem(_ inventoryItem: ProductWithQuantity) -> Bool {
        if let (index, item, _) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: inventoryItem.quantity)
            tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
            return true
        } else {
            return false
        }
    }

    func addOrUpdateUI(_ item: ProductWithQuantity, scrollToCell: Bool) {
        if !tryUpdateItem(item, scrollToCell: scrollToCell) {
            appendItemUI(item, scrollToCell: scrollToCell)
        }
    }
    
    func addOrIncrementUI(_ item: ProductWithQuantity) {
        if !tryIncrementItem(item) {
            appendItemUI(item, scrollToCell: false)
        }
    }
    
    fileprivate func updateQuantityUI(_ item: ProductWithQuantity, updatedQuantity: Int) {
        if let (index, _, cellMaybe) = inventoryItemTableViewData(item) {
            let updatedItem = item.updateQuantityCopy(updatedQuantity)
            models[index] = updatedItem
            if let cell = cellMaybe {
                cell.model = updatedItem
                cell.quantityLabel.text = "\(updatedItem.quantity)"
            }
        } else {
            QL3("Warn: InventoryItemsTableViewController.remove: didn't find item: \(item)")
        }
    }
    
    func updateIncrementUI(_ inventoryItem: ProductWithQuantity, delta: Int) {
        if let (index, _, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            let incrementedItem = inventoryItem.incrementQuantityCopy(delta)
            models[index] = incrementedItem
            if let cell = cellMaybe {
                cell.model = incrementedItem
                cell.quantityLabel.text = "\(incrementedItem.quantity)"
            }
        } else {
            QL3("Warn: InventoryItemsTableViewController.remove: didn't find item: \(inventoryItem)")
        }
    }
    
    func remove(_ inventoryItem: ProductWithQuantity) {
        if let (index, _) = (models.enumerated().filter{$0.element.same(inventoryItem)}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: \(inventoryItem)")
        }
    }
    
    func remove(_ inventoryItemInventoryUuid: String, inventoryItemProductUuid: String) {
        if let (index, _) = (models.enumerated().filter{$0.element.product.uuid == inventoryItemProductUuid}.first) {
            removeUI(index)
        } else {
            print("Warn: InventoryItemsTableViewController.remove: didn't find intentoryItme: inventoryItemInventoryUuid: \(inventoryItemInventoryUuid), inventoryItemProductUuid: \(inventoryItemProductUuid)")
        }
    }
    
    fileprivate func removeUI(_ row: Int) {
        tableView.wrapUpdates {[weak self] in
            self?.models.remove(at: row)
            self?.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: UITableViewRowAnimation.bottom)
        }
        updateEmptyUI()
    }
    
    
    fileprivate func loadPossibleNextPage() {
        
        func setLoading(_ loading: Bool) {
            self.loadingPage = loading
            let tableViewFooter = tableViewController.view.viewWithTag(ViewTags.TableViewFooter) as? LoadingFooter
            tableViewFooter?.isHidden = !loading
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let sortByOption = sortByOptions[row]
        sortBy = sortByOption.value
        sortByButton.setTitle(sortByOption.key, for: UIControlState())
        
        clearAndLoadFirstPage()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    @IBAction func onSortByTap(_ sender: UIButton) {
//        if let popup = self.sortByPopup {
//            popup.dismissAnimated(true)
//        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointing(at: sortByButton, in: view, animated: true)
//        }
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}
