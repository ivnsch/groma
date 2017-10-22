//
//  ProductsWithQuantityViewController.swift
//  shoppin
//
//  Created by ischuetz on 03/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

import Providers

protocol ProductsWithQuantityViewControllerDelegate: class {
    func loadModels(_ page: NSRange?, sortBy: InventorySortBy, onSuccess: @escaping ([ProductWithQuantity2]) -> Void)
    func remove(_ model: ProductWithQuantity2, index: Int, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void)
    func increment(_ model: ProductWithQuantity2, delta: Float, onSuccess: @escaping (Float) -> Void)
    func onModelSelected(_ model: ProductWithQuantity2, indexPath: IndexPath)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
    func onEmpty(_ empty: Bool)
    func onTableViewScroll(_ scrollView: UIScrollView)
    
    func isPullToAddEnabled() -> Bool
    func onPullToAdd()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate, ExplanationViewDelegate {
    
    fileprivate weak var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    var models: [ProductWithQuantity2] = []

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

    
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
    fileprivate var explanationManager: ExplanationManager = ExplanationManager()

    fileprivate var pullToAddView: MyRefreshControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initExplanationManager()
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        tableView.backgroundColor = Theme.defaultTableViewBGColor
        
        if delegate?.isPullToAddEnabled() ?? false {
            let refreshControl = PullToAddHelper.createPullToAdd(self)
            tableViewController.refreshControl = refreshControl
            refreshControl.addTarget(self, action: #selector(ProductsWithQuantityViewController.onPullRefresh(_:)), for: .valueChanged)
            self.pullToAddView = refreshControl
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
    
    fileprivate func initExplanationManager() {
        let contents = ExplanationContents(title: "Did you know?", text: "You can scrub an item left\nor right to change quantities", imageName: "scrub", buttonTitle: "Got it!", frameCount: 180)
        let checker = SwipeToIncrementAlertHelperNew()
        checker.preference = .showedCanSwipeToIncrementCounter
        explanationManager.explanationContents = contents
        explanationManager.checker = checker
    }
    
    @objc func onPullRefresh(_ sender: UIRefreshControl) {
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
    
    @objc func onEmptyInventoryViewTap(_ sender: UITapGestureRecognizer) {
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
            logger.w("No tabBarController: \(String(describing: tabBarController))")
        }
        
        load()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count + (explanationManager.showExplanation ? 1 : 0)

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
            let explanationView = explanationManager.generateExplanationView()
            cell.contentView.addSubview(explanationView)
            explanationView.frame = cell.contentView.bounds
            explanationView.fillSuperview()
            explanationView.delegate = self
            explanationView.imageView.startAnimating()
            return cell
            
        } else { // Normal cell
            let row = explanationManager.showExplanation ? indexPath.row - 1 : indexPath.row

            let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as! ProductWithQuantityTableViewCell
            
            let model = self.models[row]
            
            cell.model = model
            cell.delegate = self
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if explanationManager.showExplanation && indexPath.row == explanationManager.row { // Explanation cell
            return explanationManager.rowHeight
        } else {
            return cellHeight
        }
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
            delegate?.remove(models[indexPath.row], index: indexPath.row, onSuccess: {}, onError: {_ in })
        }
    }
    
    func indexPathOfItem(_ model: ProductWithQuantity2) -> IndexPath? {
        for i in 0..<models.count {
            let m = models[i]
            if m.product == model.product && m.quantity == model.quantity {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
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
//    
//    func onIncrementItemTap(_ cell: ProductWithQuantityTableViewCell) {
//        cell.cancelDeleteProgress()
//        checkChangeInventoryItemQuantity(cell, delta: 1)
//    }
//    
//    func onDecrementItemTap(_ cell: ProductWithQuantityTableViewCell) {
//        cell.cancelDeleteProgress()
//        checkChangeInventoryItemQuantity(cell, delta: -1)
//    }
//    
//    func onPanQuantityUpdate(_ cell: ProductWithQuantityTableViewCell, newQuantity: Float) {
//        cell.cancelDeleteProgress()
//        if let model = cell.model {
//            checkChangeInventoryItemQuantity(cell, delta: newQuantity - model.quantity)
//        } else {
//            logger.e("No model, can't update quantity")
//        }
//    }
    
    func onChangeQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float) {
        fatalError("Outdated - delete this controller!")
    }
    
    func onQuantityInput(_ cell: ProductWithQuantityTableViewCell, quantity: Float) {
        fatalError("Outdated - delete this controller!")
    }
    
    func onDeleteTap(_ cell: ProductWithQuantityTableViewCell) {
        fatalError("Outdated - delete this controller!")
    }
    
    /**
    Unwrap optionals safely
    Note that despite implicitly unwrapped may look suitable here, we prefer working with ? as general approach
    */
    fileprivate func checkChangeInventoryItemQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float) {
        if let inventoryItem = cell.model, let indexPath = getIndexPath(inventoryItem) {
            changeInventoryItemQuantity(cell, row: (indexPath as NSIndexPath).row, inventoryItem: inventoryItem, delta: delta)
        } else {
            print("Error: Cell has invalid state, inventory item and row must not be nil at this point")
        }
    }
    
    fileprivate func getIndexPath(_ model: ProductWithQuantity2) -> IndexPath? {
        for (i, m) in models.enumerated() {
            if same(m, model) {
                return IndexPath(row: i, section: 0)
            }
        }
        return nil
    }
    
    fileprivate func changeInventoryItemQuantity(_ cell: ProductWithQuantityTableViewCell, row: Int, inventoryItem: ProductWithQuantity2, delta: Float) {

        func remove() {
            cell.startDeleteProgress {[weak self] in
                self?.delegate?.remove(inventoryItem, index: row, onSuccess: {
                    self?.models.remove(at: row) // TODO!!!!!!!!!!!!!!!!!!!! use results
                    self?.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .top)
                    }, onError: {result in
                        logger.e("Error ocurred removing item: \(result)")
                })
            }
        }
        
        let newQuantity = inventoryItem.quantity + delta
        
        if newQuantity >= 0 {
            delegate?.increment(inventoryItem, delta: delta, onSuccess: {updatedQuantity in
                cell.shownQuantity = updatedQuantity
                if updatedQuantity == 0 {
//                    remove()
                }
            })
            
        } else { // user tries to decrement when the quantity is already 0 (quantity + delta is a negative number) -> start remove animation
//            remove()
        }
    }

    // Finds tableview related data of inventory item, if it's in tableview, otherwise returns nil
    fileprivate func inventoryItemTableViewData(_ inventoryItem: ProductWithQuantity2) -> (index: Int, item: ProductWithQuantity2, cell: ProductWithQuantityTableViewCell?)? { // note item -> the item currently in tableview TODO why do we need to return this if it's "same" as parameter inventoryItem
        if let (index, item) = (models.enumerated().filter{same($0.element, inventoryItem)}.first) {
            
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
    
    // Inserts item in table view, considering the current sortBy
    func insert(item: ProductWithQuantity2, scrollToRow: Bool) {
        guard let indexPath = findIndexPathForNewItem(item) else {logger.e("No index path for: \(item)"); return}
        tableView.insertRows(at: [indexPath], with: .top)
        if scrollToRow {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    fileprivate func findIndexPathForNewItem(_ inventoryItem: ProductWithQuantity2) -> IndexPath? {
        
        func findRow(_ isAfter: (ProductWithQuantity2) -> Bool) -> IndexPath {
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
                        if $0.product.product.item.name == inventoryItem.product.product.item.name {
                            return $0.product.unit.name > inventoryItem.product.unit.name
                        } else {
                            return $0.product.product.item.name > inventoryItem.product.product.item.name
                        }
                        
                    } else {
                        return $0.quantity > inventoryItem.quantity
                    }
                })
            case .alphabetic:
                return findRow({
                    if $0.product.product.item.name == inventoryItem.product.product.item.name {
                        if $0.quantity == inventoryItem.quantity {
                            return $0.product.unit.name > inventoryItem.product.unit.name
                        } else {
                            return $0.quantity > inventoryItem.quantity
                        }
                    } else {
                        return $0.product.product.item.name > inventoryItem.product.product.item.name
                    }
                    
                })
            }
        } else {
            print("Warn: InventoryItemsTableViewController.findIndexPathForNewItem: sortBy is not set")
            return nil
        }
    }
    
    func scrollToItem(_ item: ProductWithQuantity2) {
        if let indexPath = indexPathOfItem(item) {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        } else {
            logger.d("Didn't find item to scroll to")
        }
    }

    fileprivate func tryUpdateItem(_ inventoryItem: ProductWithQuantity2, scrollToCell: Bool) -> Bool {
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
    

    //////////////
    // helpers needed because referencing Self / protocol in protocol doesn't compile
    func same(_ p1: ProductWithQuantity2, _ p2: ProductWithQuantity2) -> Bool {
        return p1.product.same(p2.product)
    }
    
    func equal(_ p1: ProductWithQuantity2, _ p2: ProductWithQuantity2) -> Bool  {
        return p1.product == p2.product && p1.quantity == p2.quantity
    }
    //////////////
    
    func load() {
        guard let sortBy = sortBy else {logger.e("Can't load page, sortBy not set"); return}
        
        delegate?.loadModels(nil, sortBy: sortBy) {[weak self] models in
            self?.models = models
            self?.tableView.reloadData()
            self?.updateEmptyUI()
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
        
        load()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return DimensionsManager.pickerRowHeight
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
    
    
    // MARK: - ExplanationViewDelegate
    
    func onGotItTap(sender: UIButton) {
        explanationManager.dontShowAgain()
        tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }
}
