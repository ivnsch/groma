//
//  ProductsWithQuantityViewControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 18/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import QorumLogs
import Providers

protocol ProductsWithQuantityViewControllerDelegateNew: class {
    
    func loadModels(sortBy: InventorySortBy, onSuccess: @escaping () -> Void)
    
    func itemForRow(row: Int) -> ProductWithQuantity2?
    var itemsCount: Int {get}
    
    // This is not pretty but making ProductWithQuantity2 extend Identifiable causes the typical weird Swift generics errors so we cast and compare in the delegate instead
    func same(lhs: ProductWithQuantity2, rhs: ProductWithQuantity2) -> Bool
    
    func remove(_ model: ProductWithQuantity2, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void)
    
    func increment(_ model: ProductWithQuantity2, delta: Float, onSuccess: @escaping (Float) -> Void)
    
    func onModelSelected(_ index: Int)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
    func onEmpty(_ empty: Bool)
    func onTableViewScroll(_ scrollView: UIScrollView)
    
    func isPullToAddEnabled() -> Bool
    func onPullToAdd()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewControllerNew: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, UIPickerViewDataSource, UIPickerViewDelegate, ExplanationViewDelegate {
    
    fileprivate weak var tableViewController: UITableViewController! // initially there was only a tableview but pull to refresh control seems to work better with table view controller
    
    var tableView: UITableView {
        return tableViewController.tableView
    }
    
    @IBOutlet weak var topMenuView: UIView!
    
    var sortBy: InventorySortBy? = .count
    @IBOutlet weak var sortByButton: UIButton!
    //    private var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.count, trans("sort_by_count")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    @IBOutlet weak var emptyViewControllerContainer: UIView!
    fileprivate var emptyViewController: EmptyViewController!

    var isEmpty: Bool {
        return itemsCount == 0
    }
    
    @IBOutlet weak var topMenusHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: ProductsWithQuantityViewControllerDelegateNew? {
        didSet {
            initEmptyViewLabelsIfConditions()
        }
    }
    
    var onViewWillAppear: VoidFunction? // to be able to ensure sortBy is not set before UI is ready
    
    var showQuantityButtons: Bool = true {
        didSet {
            tableView.reloadData()
        }
    }
    
    var itemsCount: Int {
        return delegate?.itemsCount ?? 0
    }
    
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
    fileprivate(set) var explanationManager: ExplanationManager = ExplanationManager()
    
    fileprivate var pullToAddView: MyRefreshControl?

    fileprivate let placeholderIdentifier = "placeholder"
    var placeHolderItem: (indexPath: IndexPath, item: InventoryItem)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initExplanationManager()        
        initEmptyView()
        
        tableView.register(UINib(nibName: "PlaceHolderItemCell", bundle: nil), forCellReuseIdentifier: placeholderIdentifier)
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450
        
        if delegate?.isPullToAddEnabled() ?? false {
            let refreshControl = PullToAddHelper.createPullToAdd(self, backgroundColor: Theme.lightGreyBackground)
            tableViewController.refreshControl = refreshControl
            refreshControl.addTarget(self, action: #selector(ProductsWithQuantityViewController.onPullRefresh(_:)), for: .valueChanged)
            self.pullToAddView = refreshControl
        }
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func onTap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
        view.resignFirstResponder()
    }
    
    fileprivate func initEmptyView() {
        let emptyViewController = UIStoryboard.emptyViewStoryboard()
        emptyViewController.addTo(container: emptyViewControllerContainer)
        emptyViewController.onTapOrPull = {[weak self] in
            self?.delegate?.onEmptyViewTap()
        }
        self.emptyViewController = emptyViewController
        
        initEmptyViewLabelsIfConditions()
    }
    
    fileprivate func initEmptyViewLabelsIfConditions() {
        if let emptyViewController = emptyViewController, let delegate = delegate {
            let emptyViewData = delegate.emptyViewData()
            emptyViewController.labels = (emptyViewData.text, emptyViewData.text2)
        }
    }
    
    func updateEmptyUI() {
        setEmptyUI(isEmpty, animated: true)
        // necessary?
        delegate?.onEmpty(isEmpty)
        topMenuView.setHiddenAnimated(isEmpty)
    }
    
    func setEmptyUI(_ empty: Bool, animated: Bool) {
        let hidden = !empty
        if animated {
            emptyViewControllerContainer.setHiddenAnimated(hidden)
        } else {
            emptyViewControllerContainer.isHidden = hidden
        }
    }
    
    fileprivate func initExplanationManager() {
        let contents = ExplanationContents(title: "Did you know?", text: "You can press and hold\nto set individual items in edit mode", imageName: "longpressedit", buttonTitle: "Got it!", frameCount: 210)
        let checker = SwipeToIncrementAlertHelperNew()
        checker.preference = .showedLongTapToEditCounter
        explanationManager.explanationContents = contents
        explanationManager.checker = checker
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
    
    override func viewWillAppear(_ animated:Bool) {
        onViewWillAppear?()
        
        tableView.allowsSelectionDuringEditing = true
        
        if let _ = tabBarController?.tabBar.frame.height {
            // TODO this is not enough, why?
            //            tableView.bottomInset = tabBarHeight + Constants.tableViewAdditionalBottomInset
            tableView.bottomInset = 41
        } else {
            QL3("No tabBarController: \(tabBarController)")
        }
        
        load()
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsCount + (explanationManager.showExplanation ? 1 : 0)
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
            
        }else if let placeHolderItem = placeHolderItem, placeHolderItem.indexPath == indexPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: placeholderIdentifier) as! PlaceHolderItemCell
            cell.categoryColorView.backgroundColor = placeHolderItem.item.product.product.item.category.color
            return cell
            
        } else { // Normal cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "inventoryCell", for: indexPath) as! ProductWithQuantityTableViewCell
            
            let row = explanationManager.showExplanation ? indexPath.row - 1 : indexPath.row
            if let model = delegate?.itemForRow(row: row) {
                cell.model = model
            } else {
                if delegate == nil {
                    QL4("No delegate")
                } else {
                    QL4("Illegal state: No item for row: \(row)")
                }
                
            }
            
            cell.setMode(showQuantityButtons ? .edit : .readonly)
            
            cell.indexPath = indexPath
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
            guard let model = delegate?.itemForRow(row: indexPath.row) else {QL4("Illegal state: no model"); return}
            
            delegate?.remove(model, onSuccess: {}, onError: {_ in })
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.onModelSelected(indexPath.row)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)
    }
    
    // MARK: - ProductWithQuantityTableViewCellDelegate
    
    func onChangeQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float) {
        changeInventoryItemQuantity(cell, delta: delta, isInput: false)
    }
    
    func onQuantityInput(_ cell: ProductWithQuantityTableViewCell, quantity: Float) {
        guard let model = cell.model else {QL4("Invalid state: Cell must have model"); return}
        
        // Since we already wrote everything based on deltas, we transform our quantity update to delta
        let delta = quantity - model.quantity
        
        changeInventoryItemQuantity(cell, delta: delta, isInput: true)
    }
    
    func onDeleteTap(_ cell: ProductWithQuantityTableViewCell) {
        if let model = cell.model {
            delegate?.remove(model, onSuccess: {}, onError: {_ in })
        } else {
            QL4("No model, can't update quantity")
        }
    }
    
    fileprivate func findFirstVisibleItem(_ f: (ProductWithQuantity2) -> Bool) -> (index: Int, model: ProductWithQuantity2, cell: ProductWithQuantityTableViewCell)? {
        return (tableView.visibleCells.flatMap {cell in
            let cell =  cell as! ProductWithQuantityTableViewCell
            guard let model = cell.model else {QL4("Invalid state: no model"); return nil}
            guard let indexPath = cell.indexPath else {QL4("Invalid state: no index path"); return nil}
            
            if f(model) {
                return (indexPath.row, model, cell)
            } else {
                return nil
            }
        }).first
    }
    
    fileprivate func findFirstItem(_ f: (ProductWithQuantity2) -> Bool) -> (index: Int, model: ProductWithQuantity2)? {
        for itemIndex in 0..<itemsCount {
            guard let item = delegate?.itemForRow(row: itemIndex) else {QL4("Illegal state: no item for index: \(itemIndex). Or delegate is nil: \(delegate)"); return nil}
            if f(item) {
                return (itemIndex, item)
            }
            
        }
        return nil
    }
    
    
    // Inserts item in table view, considering the current sortBy
    func insert(item: ProductWithQuantity2, scrollToRow: Bool) {
        guard let indexPath = findIndexPathForNewItem(item) else {
            QL1("No index path for: \(item), appending"); return;
        }
        QL1("Found index path: \(indexPath) for: \(item.product.product.item.name), sortBy: \(sortBy)")
        tableView.insertRows(at: [indexPath], with: .top)
        
        updateEmptyUI()
        
        if scrollToRow {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    func update(item: ProductWithQuantity2, scrollToRow index: Int?) {
        tableView.reloadData() // update with quantity change is tricky, since the sorting (by quantity) can cause the item to change positions. So we just reload the tableview
        
        if let index = index {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    
    // TODO!!!!!!!!!!!!!!!! insert at specific place: for realm it's not a problem we just have to append to the list (the results should continue being sorted so we don't need to do anything else). but we have to insert the item in the visible rows of the table - look for its place here using the cells instead of models.
    fileprivate func findIndexPathForNewItem(_ inventoryItem: ProductWithQuantity2) -> IndexPath? {
        func findRow(_ isAfter: (ProductWithQuantity2) -> Bool) -> IndexPath? {
        
            let row: Int? = {
                if let firstBiggerItemTuple = findFirstItem({isAfter($0)}) {
                    return firstBiggerItemTuple.index - 1 // insert in above the first biggest item (Note: -1 because our new item is already in the results, so we have to substract it). 
                } else {
                    return itemsCount - 1 // no biggest item - our item is the biggest - return end of page (about page see warning in addOrUpdateIncrementUI)
                }
            }()

            let finalRow = row.map{explanationManager.showExplanation ? $0 + 1 : $0}

            return finalRow.map{IndexPath(row: $0, section: 0)}
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
    
    fileprivate func changeInventoryItemQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float, isInput: Bool) {
        
        guard let model = cell.model else {QL4("Invalid state: Cell must have model"); return}

        delegate?.increment(model, delta: delta, onSuccess: {updatedQuantity in
            if !isInput { // for input it's not only not necessary to re-set quantity but it also would delete a possible trailing dot
                cell.shownQuantity = updatedQuantity
            }
        })
    }
    
    func scrollTo(_ index: Int) {
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
    }
    
    func update(index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    func reload() {
        tableView.reloadData()
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
        guard let sortBy = sortBy else {QL4("Can't load models, sortBy not set"); return}
        
        tableView.reloadData()
        updateEmptyUI()
        
        delegate?.loadModels(sortBy: sortBy) {[weak self] models in
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
    
    // MARK: - Scrol delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pullToAddView?.updateForScrollOffset(offset: scrollView.contentOffset.y, startOffset: -60)
    }
}


struct ExplanationContents {
    var title: String
    var text: String
    var imageName: String
    var buttonTitle: String
    var frameCount: Int
}

class ExplanationManager {

    var view: ExplanationView?
    
    var row: Int {
        return 0
    }
    
    var rowHeight: CGFloat {
        return 270
    }
    
    var showExplanation: Bool {
        guard let checker = checker else {QL1("No checker"); return false}
        
        return checker.showPopup()
    }
    
    var explanationContents: ExplanationContents?
    var checker: SwipeToIncrementAlertHelperNew? // TODO naming, etc. (quickly recycled old class)
    
    func generateExplanationView() -> ExplanationView {
        
        guard let contents = explanationContents else {QL4("Invalid state: No explanation contents, returning dummy view"); return ExplanationView()}

        return view ?? {
            let view = ExplanationView()
            view.titleLabel.text = contents.title
            view.msgLabel.text = contents.text
            view.msgLabel.sizeToFit()
            view.gotItButton.setTitle(contents.buttonTitle, for: .normal)

            self.view = view
            
            var arr = [UIImage]()
            for i in 0...contents.frameCount {
                guard let img = UIImage(named: "\(contents.imageName)\(i)") else {QL4("No image for: \(i), returning dummy view"); return ExplanationView()}
                arr.append(img)
            }
            
            view.imageView.animationImages = arr
            
            return view
        }()
    }
    
    func dontShowAgain() {
        guard let checker = checker else {QL1("No checker"); return}
        
        checker.dontShowAgain()
    }
    
}
