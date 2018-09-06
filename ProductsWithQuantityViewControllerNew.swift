//
//  ProductsWithQuantityViewControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 18/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

import Providers

typealias InventoryItemsSortOption = (value: InventorySortBy, key: String)

protocol ProductsWithQuantityViewControllerDelegateNew: class {
    
    func loadModels(sortBy: InventorySortBy, onSuccess: @escaping () -> Void)
    
    func itemForRow(row: Int) -> ProductWithQuantity2?
    var itemsCount: Int {get}
    
    // This is not pretty but making ProductWithQuantity2 extend Identifiable causes the typical weird Swift generics errors so we cast and compare in the delegate instead
    func same(lhs: ProductWithQuantity2, rhs: ProductWithQuantity2) -> Bool
    
    func remove(_ model: ProductWithQuantity2, onSuccess: @escaping VoidFunction, onError: @escaping (ProviderResult<Any>) -> Void)
    
    func increment(_ model: ProductWithQuantity2, delta: Float, onSuccess: @escaping (Float) -> Void)
    
    func onModelSelected(_ index: Int)
    func onDeepPress(_ index: Int)
    func emptyViewData() -> (text: String, text2: String, imgName: String)
    func onEmptyViewTap()
    func onEmpty(_ empty: Bool)
    func onTableViewScroll(_ scrollView: UIScrollView)
    
    func isPullToAddEnabled() -> Bool
    func onPullToAdd()
}


/// Generic controller for sorted products with a quantity, which can be incremented and decremented
class ProductsWithQuantityViewControllerNew: UIViewController, UITableViewDataSource, UITableViewDelegate, ProductWithQuantityTableViewCellDelegate, ExplanationViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var topMenuView: UIView!
    @IBOutlet weak var topDivider: UIView!

    var sortBy: InventoryItemsSortOption? {
        didSet {
            if let sortBy = sortBy {
                sortByButton.setTitle(sortBy.key, for: UIControlState())
            } else {
                logger.w("sortBy is nil")
            }
        }
    }
    
    @IBOutlet weak var sortByButton: UIButton!
    //    private var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [InventoryItemsSortOption] = [
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
    
    var itemsCount: Int {
        return delegate?.itemsCount ?? 0
    }
    
    fileprivate let cellHeight = DimensionsManager.defaultCellHeight
    
    fileprivate(set) var explanationManager: ExplanationManager = ExplanationManager()

    fileprivate let placeholderIdentifier = "placeholder"
    var placeHolderItem: (indexPath: IndexPath, item: InventoryItem)?
    
    fileprivate var initializedTableViewBottomInset = false
    var bottomInsetWhileTopMenuOpen: CGFloat = 0

    fileprivate var pullToAdd: PullToAddHelper?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initExplanationManager()        
        initEmptyView()
        
        tableView.register(UINib(nibName: "PlaceHolderItemCell", bundle: nil), forCellReuseIdentifier: placeholderIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView() // quick fix to hide separators in empty space http://stackoverflow.com/a/14461000/930450

        tableView.backgroundColor = Theme.defaultTableViewBGColor

        sortBy = sortByOptions.first

        pullToAdd = PullToAddHelper(tableView: tableView, onPull: { [weak self] in
            self?.delegate?.onPullToAdd()
        })

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }

    @objc func onTap(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
        view.resignFirstResponder()
    }

    fileprivate func initEmptyView() {
        let emptyViewController = UIStoryboard.emptyViewStoryboard()
        emptyViewController.view.isHidden = true
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
        topDivider.isHidden = isEmpty
    }

    func setEmptyUI(_ empty: Bool, animated: Bool) {
        let hidden = !empty
        if animated {
            emptyViewController.view.isHidden = hidden
            emptyViewControllerContainer.setHiddenAnimated(hidden)
        } else {
            emptyViewControllerContainer.isHidden = hidden
        }
    }

    fileprivate func initExplanationManager() {
        guard !UIAccessibilityIsVoiceOverRunning() else { return }

        let contents = ExplanationContents(title: trans("popup_title_did_you_know"), text: trans("popup_long_press_to_edit"), imageName: "longpressedit", buttonTitle: trans("popup_button_got_it"), frameCount: 210)
        let checker = SwipeToIncrementAlertHelperNew()
        checker.preference = .showedLongTapToEditCounter
        explanationManager.explanationContents = contents
        explanationManager.checker = checker
    }

    override func viewWillAppear(_ animated: Bool) {
        onViewWillAppear?()
        
        tableView.allowsSelectionDuringEditing = true
        
        load()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        delay(0.5) { [weak self] in self?.pullToAdd?.setHidden(false) }

        // Set inset such that newly added cells can be positioned directly below the quick add controller
        // Before of view did appear final table view height is not set. We also have to execute this only the first time because later it may be that the table view is contracted (quick add is open) which would set an incorrect inset.
        if !initializedTableViewBottomInset {
            initializedTableViewBottomInset = true
            bottomInsetWhileTopMenuOpen = tableView.height + topMenusHeightConstraint.constant - DimensionsManager.quickAddHeight - DimensionsManager.defaultCellHeight
            tableView.bottomInset = 0
        }
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
            
        } else if let placeHolderItem = placeHolderItem, placeHolderItem.indexPath == indexPath {
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
                    logger.e("No delegate")
                } else {
                    logger.e("Illegal state: No item for row: \(row)")
                }
                
            }
            
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
            guard let model = delegate?.itemForRow(row: indexPath.row) else {logger.e("Illegal state: no model"); return}
            
            delegate?.remove(model, onSuccess: {}, onError: {_ in })
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.onModelSelected(indexPath.row)
    }

    func onDeepPress(_ cell: ProductWithQuantityTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            delegate?.onDeepPress(indexPath.row)
        } else {
            logger.e("Invalid state: No index path for pressed cell: \(cell)", .ui)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: true)

        // Update cell mode
        let cellMode: QuantityViewMode = editing ? .edit : .readonly
        if let cells = tableView.visibleCells as? [ProductWithQuantityTableViewCell] {
            for cell in cells {
                cell.setMode(cellMode, animated: true)
            }
        } else {
            logger.e("Invalid state, couldn't cast: \(tableView.visibleCells)")
        }
    }
    
    // MARK: - ProductWithQuantityTableViewCellDelegate
    
    func onChangeQuantity(_ cell: ProductWithQuantityTableViewCell, delta: Float) {
        changeInventoryItemQuantity(cell, delta: delta, isInput: false)
    }
    
    func onQuantityInput(_ cell: ProductWithQuantityTableViewCell, quantity: Float) {
        guard let model = cell.model else {logger.e("Invalid state: Cell must have model"); return}
        
        // Since we already wrote everything based on deltas, we transform our quantity update to delta
        let delta = quantity - model.quantity
        
        changeInventoryItemQuantity(cell, delta: delta, isInput: true)
    }
    
    func onDeleteTap(_ cell: ProductWithQuantityTableViewCell) {
        if let model = cell.model {
            delegate?.remove(model, onSuccess: {}, onError: {_ in })
        } else {
            logger.e("No model, can't update quantity")
        }
    }

    var isControllerInEditMode: Bool {
        return isEditing
    }

    // MARK: -
    
    fileprivate func findFirstVisibleItem(_ f: (ProductWithQuantity2) -> Bool) -> (index: Int, model: ProductWithQuantity2, cell: ProductWithQuantityTableViewCell)? {
        return (tableView.visibleCells.compactMap {cell in
            let cell =  cell as! ProductWithQuantityTableViewCell
            guard let model = cell.model else {logger.e("Invalid state: no model"); return nil}
            guard let indexPath = cell.indexPath else {logger.e("Invalid state: no index path"); return nil}
            
            if f(model) {
                return (indexPath.row, model, cell)
            } else {
                return nil
            }
        }).first
    }
    
    fileprivate func findFirstItem(_ f: (ProductWithQuantity2) -> Bool) -> (index: Int, model: ProductWithQuantity2)? {
        for itemIndex in 0..<itemsCount {
            guard let item = delegate?.itemForRow(row: itemIndex) else {logger.e("Illegal state: no item for index: \(itemIndex). Or delegate is nil: \(String(describing: delegate))"); return nil}
            if f(item) {
                return (itemIndex, item)
            }
            
        }
        return nil
    }
    
    
    // Inserts item in table view, considering the current sortBy
    func insert(item: ProductWithQuantity2, scrollToRow: Bool) {
        guard let indexPath = findIndexPathForNewItem(item) else {
            logger.v("No index path for: \(item), appending"); return;
        }
        logger.v("Found index path: \(indexPath) for: \(item.product.product.item.name), sortBy: \(String(describing: sortBy))")
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
        
        if let sortBy = sortBy?.value {
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
        
        guard let model = cell.model else {logger.e("Invalid state: Cell must have model"); return}

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
        guard let sortBy = sortBy else {logger.e("Can't load models, sortBy not set"); return}

        delay(0.2) { // smoother animation when showing controller
            self.delegate?.loadModels(sortBy: sortBy.value) { [weak self] in
                self?.tableView.reloadData()
                self?.updateEmptyUI()
            }
        }
    }

    @IBAction func onSortByTap(_ sender: UIButton) {
        let picker = createPicker()
        let popup = MyTipPopup(customView: picker.view)
        popup.presentPointing(at: sortByButton, in: view, animated: true)
        addChildViewController(picker)
        popup.onDismiss = { [weak picker] in
            picker?.removeFromParentViewController()
        }
    }

    fileprivate func createPicker() -> UIViewController {
        let picker = TooltipPicker()
        picker.view.frame = CGRect(x: 0, y: 0, width: 150, height: 100)
        let optionNames = sortByOptions.map { $0.key }
        picker.config(options: optionNames, selectedOption: sortBy?.key) { [weak self] selectedOption in
            guard let weakSelf = self else { return }
            weakSelf.sortBy = weakSelf.sortByOptions.findFirst { $0.key == selectedOption }
            weakSelf.load()
        }
        return picker
    }
    
    // MARK: - ExplanationViewDelegate
    
    func onGotItTap(sender: UIButton) {
        explanationManager.dontShowAgain()
        tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .top)
    }
    
    // MARK: - Scroll delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.onTableViewScroll(scrollView)
        pullToAdd?.scrollViewDidScroll(scrollView: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pullToAdd?.scrollViewDidEndDecelerating(scrollView)
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
        guard let checker = checker else {logger.v("No checker"); return false}
        
        return checker.showPopup()
    }

    var explanationContents: ExplanationContents?
    var checker: SwipeToIncrementAlertHelperNew? // TODO naming, etc. (quickly recycled old class)

    func generateExplanationView() -> ExplanationView {
        
        guard let contents = explanationContents else {logger.e("Invalid state: No explanation contents, returning dummy view"); return ExplanationView()}

        return view ?? {
            let view = ExplanationView()
            view.titleLabel.text = contents.title
            view.msgLabel.text = contents.text
            view.msgLabel.sizeToFit()
            view.gotItButton.setTitle(contents.buttonTitle, for: .normal)

            self.view = view
            
            var arr = [UIImage]()
            for i in 0...contents.frameCount {
                guard let img = UIImage(named: "\(contents.imageName)\(i)") else {logger.e("No image for: \(i), returning dummy view"); return ExplanationView()}
                arr.append(img)
            }
            
            view.imageView.animationImages = arr
            
            return view
        }()
    }
    
    func dontShowAgain() {
        guard let checker = checker else {logger.v("No checker"); return}
        
        checker.dontShowAgain()
    }

    // Debugging
    func reset() {
        checker?.reset()
    }
}
