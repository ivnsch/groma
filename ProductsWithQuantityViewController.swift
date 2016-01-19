//
//  ProductsWithQuantityViewController.swift
//  shoppin
//
//  Created by ischuetz on 03/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

class ProductWithQuantity: Equatable, Identifiable {
    var product: Product {
        fatalError("override")
    }
    var quantity: Int {
        fatalError("override")
    }
    func same(rhs: ProductWithQuantity) -> Bool {
        return product.same(rhs.product)
    }
    func incrementQuantityCopy(delta: Int) -> ProductWithQuantity {
        fatalError("override")
    }
}
func ==(lhs: ProductWithQuantity, rhs: ProductWithQuantity) -> Bool {
    return lhs.product == rhs.product && lhs.quantity == rhs.quantity
}

protocol ProductsWithQuantityViewControllerDelegate {
    func loadModels(page: NSRange, sortBy: InventorySortBy, onSuccess: [ProductWithQuantity] -> Void)
    func remove(model: ProductWithQuantity, onSuccess: VoidFunction, onError: ProviderResult<Any> -> Void)
    func increment(model: ProductWithQuantity, delta: Int, onSuccess: VoidFunction)
    func onModelSelected(model: ProductWithQuantity, indexPath: NSIndexPath)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    private(set) var models: [ProductWithQuantity] = []
    
    @IBOutlet var tableViewFooter: LoadingFooter!

    var sortBy: InventorySortBy? = .Count
    @IBOutlet weak var sortByButton: UIButton!
    private var sortByPopup: CMPopTipView?
    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyViewImg: UIImageView!
    @IBOutlet weak var emptyViewLabel1: UILabel!
    @IBOutlet weak var emptyViewLabel2: UILabel!
    
    var delegate: ProductsWithQuantityViewControllerDelegate?
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready

    
    var tableViewTopInset: CGFloat {
        get {
            return tableView.topInset
        }
        set {
            tableView.topInset = newValue
        }
    }
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    
    func clearAndLoadFirstPage() {
        models = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyInventoryViewTap:"))
        emptyView.addGestureRecognizer(tapRecognizer)
        
        if let emptyViewData = delegate?.emptyViewData()  {
            emptyViewLabel1.text = emptyViewData.text
            emptyViewLabel2.text = emptyViewData.text2
            emptyViewImg.image = UIImage(named: emptyViewData.imgName)
        }
    }
    
    func onEmptyInventoryViewTap(sender: UITapGestureRecognizer) {
        delegate?.onEmptyViewTap()
    }
    
    override func viewWillAppear(animated:Bool) {
        onViewWillAppear?()
        
        tableView.allowsSelectionDuringEditing = true
        tableView.bottomInset = tabBarController?.tabBar.frame.height ?? 100
        
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
        
        cell.nameLabel.text = NSLocalizedString(model.product.name, comment: "")
        
        cell.centerVerticallyNameLabelConstraint.constant = model.product.brand.isEmpty ? 0 : 10
        cell.brandLabel.text = model.product.brand
        
        cell.quantityLabel.text = String(model.quantity)
        
        cell.model = model
        
        cell.row = indexPath.row
        cell.delegate = self
        
        cell.cancelDeleteProgress() // some recycled cells were showing red bar on top
        
        // this was initially a local function but it seems we have to use a closure, see http://stackoverflow.com/a/26237753/930450
        // TODO change quantity / edit inventory items
        //        let incrementItem = {(quantity: Int) -> () in
        //            //let newQuantity = inventoryItem.quantity + quantity
        //            //if (newQuantity >= 0) {
        //                inventoryItem.quantityDelta += quantity
        //                self.inventoryItemsProvider.updateInventoryItem(inventoryItem)
        //                cell.quantityLabel.text = String(inventoryItem.quantity)
        //            //}
        //        }
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // update the table view in advance, so delete animation is quick. If something goes wrong we reload the content in onError and do default error handling
            let planItem = models[indexPath.row]
            tableView.wrapUpdates {[weak self] in
                self?.models.remove(planItem)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                self?.updateEmptyView()
            }
            
            delegate?.remove(planItem, onSuccess: {}, onError: {[weak self] result in
                self?.clearAndLoadFirstPage()
                self?.defaultErrorHandler()(providerResult: result)
            })
        }
    }
    
    private func updateEmptyView() {
        emptyView.setHiddenAnimated(!models.isEmpty)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let model = models[indexPath.row]
        delegate?.onModelSelected(model, indexPath: indexPath)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
    }
    
    // MARK: - InventoryItemTableViewCellDelegate
    
    func onIncrementItemTap(cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        self.checkChangeInventoryItemQuantity(cell, delta: 1)
    }
    
    func onDecrementItemTap(cell: ProductWithQuantityTableViewCell) {
        cell.cancelDeleteProgress()
        self.checkChangeInventoryItemQuantity(cell, delta: -1)
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
            
            delegate?.increment(inventoryItem, delta: delta, onSuccess: {[weak self] in
                
                if let weakSelf = self {
                    
                    weakSelf.updateIncrementUI(inventoryItem, delta: delta, cell: cell, row: row)
                    
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
                return findRow({$0.quantity > inventoryItem.quantity})
            case .Alphabetic:
                return findRow({$0.product.name > inventoryItem.product.name})
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
    
    private func tryIncrementItem(inventoryItem: ProductWithQuantity) -> Bool {
        if let (index, item, cellMaybe) = inventoryItemTableViewData(inventoryItem) {
            updateIncrementUI(item, delta: inventoryItem.quantity, cell: cellMaybe, row: index)
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Top, animated: true)
            return true
        } else {
            return false
        }
    }
    
    func addOrIncrementUI(inventoryItem: ProductWithQuantity) {
        if !tryIncrementItem(inventoryItem) {
            // Warning: this adds the inventory item at the end of the current page - this may look a bit buggy and if user scrolls down the item may be "repeated", but for now don't have a better solution,
            // the alternative which is loading all the pages until we are in the page where the position of the item is correct (according to current sorting criteria) is inefficient as well as difficult to implement
            // a compromise is to choose a big enough page size where most users will have smaller inventories, so this can't happen
            tableView.wrapUpdates {[weak self] in
                if let weakSelf = self {
                    if let indexPathToInsert = weakSelf.findIndexPathForNewItem(inventoryItem)  { // note: before append
                        weakSelf.models.insert(inventoryItem, atIndex: indexPathToInsert.row)
                        weakSelf.tableView.insertRowsAtIndexPaths([indexPathToInsert], withRowAnimation: .Top)
                        weakSelf.updateEmptyView()
                    } else {
                        print("Error: InventoryItemsTableViewController.addOrIncrementUI: No indexPathToInsert")
                    }
                }
            }
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
        updateEmptyView()
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        if let sortBy = sortBy {
            
            synced(self) {[weak self] in
                let weakSelf = self!
                
                if !weakSelf.paginator.reachedEnd {
                    
                    if (!weakSelf.loadingPage) {
                        setLoading(true)
                        
                        weakSelf.delegate?.loadModels(weakSelf.paginator.currentPage, sortBy: sortBy) {inventoryItems in
                            weakSelf.models.appendAll(inventoryItems)
                            weakSelf.paginator.update(inventoryItems.count)
                            weakSelf.tableView.reloadData()
                            weakSelf.updateEmptyView()
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
        if let popup = self.sortByPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sortByButton, inView: view, animated: true)
        }
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}