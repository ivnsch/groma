//
//  ManageProductsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import CMPopTipView
import QorumLogs

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

    @IBOutlet weak var searchBoxHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBoxMarginTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchBoxMarginBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UITextField!

    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var searchText: String = "" {
        didSet {
            clearAndLoadFirstPage()
        }
    }
    
    private var filteredProducts: [ItemWithCellAttributes<Product>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var sortBy: ProductSortBy = .Fav {
        didSet {
            if sortBy != oldValue {
                if let option = sortByOption(sortBy) {
                    sortByButton.setTitle(option.key, forState: .Normal)
                } else {
                    QL3("No option for \(sortBy)")
                }
                clearAndLoadFirstPage()
            }
        }
    }
    @IBOutlet weak var sortByButton: UIButton!
    private var sortByPopup: CMPopTipView?
    private let sortByOptions: [(value: ProductSortBy, key: String)] = [
        (.Fav, "Usage"), (.Alphabetic, "Alphabetic")
    ]
    
    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        clearAndLoadFirstPage()
    }
    
    func clearAndLoadFirstPage() {
        filteredProducts = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    func sortByOption(sortBy: ProductSortBy) -> (value: ProductSortBy, key: String)? {
        return sortByOptions.findFirst{$0.value == sortBy}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Products"
        
        tableView.allowsSelectionDuringEditing = true
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()

        initNavBar([.Edit])
        
        searchBar.addTarget(self, action: #selector(ManageProductsViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        loadPossibleNextPage()
        
        navigationItem.backBarButtonItem?.title = ""
        
        layout()

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ManageProductsViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ManageProductsViewController.onWebsocketProduct(_:)), name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ManageProductsViewController.onWebsocketProductCategory(_:)), name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ManageProductsViewController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)        
    }
    
    private func layout() {
        searchBoxHeightConstraint.constant = DimensionsManager.searchBarHeight
    }
    
    deinit {
        QL1("Deinit manage products controller")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func onEditTap(sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = trans("title_products")
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .Plain, target: self, action: "onEditTap:")
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    private func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
//        let top: CGFloat = 55
        let top: CGFloat = 0
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddManageProductsHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .Product
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("productCell", forIndexPath: indexPath) as! ManageProductsCell

        let product = filteredProducts[indexPath.row]

        cell.product = product
        
        cell.contentView.addBottomBorderWithColor(Theme.cellBottomBorderColor, width: 1)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let product = filteredProducts[indexPath.row]
            Providers.productProvider.delete(product.item, remote: true, successHandler{[weak self] in
                self?.removeProductUI(product, indexPath: indexPath)
            })
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    private func removeProductUI(product: Product) {
        if let indexPath = indexPathForProduct(product) {
            let wrappedProduct = ItemWithCellAttributes<Product>(item: product, boldRange: nil)
            removeProductUI(wrappedProduct, indexPath: indexPath)   
        } else {
            print("ManageProductsViewController.removeProductUI: Info: product to be updated was not in table view: \(product)")
        }
    }
    
    private func removeProductUI(product: ItemWithCellAttributes<Product>, indexPath: NSIndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self?.filteredProducts.remove(product)
        }
    }
    
    // MARK: - Filter
    
    
    func textFieldDidChange(textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    private func filter(searchText: String) {
        self.searchText = searchText
    }
    
    
    // MARK: -
    
    private func onUpdatedProducts() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func textFieldShouldReturn(sender: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            let product = filteredProducts[indexPath.row].item
            let productEditData = AddEditProductControllerEditingData(product: product, indexPath: indexPath)
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: productEditData))
            initNavBar([.Edit, .Save])
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
    }
    
    func onAddProduct(product: Product) {
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        
        func onEditItem(input: ListItemInput, editingItem: AddEditProductControllerEditingData) {
            let updatedCategory = editingItem.product.category.copy(name: input.section, color: input.sectionColor)
            let updatedProduct = editingItem.product.copy(name: input.name, category: updatedCategory, brand: input.brand)
            Providers.productProvider.update(updatedProduct, remote: true, successHandler{[weak self] in
                self?.updateProductUI(updatedProduct, indexPath: editingItem.indexPath)
            })
        }
        
        func onAddItem(input: ListItemInput) {
            let product = ProductInput(name: input.name, category: input.section, categoryColor: input.sectionColor, brand: input.brand)
            
            Providers.productProvider.countProducts(successHandler {[weak self] count in
                if let weakSelf = self {
                    SizeLimitChecker.checkInventoryItemsSizeLimit(count, controller: weakSelf) {
                        Providers.productProvider.add(product, weakSelf.successHandler {product in
                            weakSelf.addProductUI(product)
                        })
                    }
                }
            })
        }
        
        if let editingItem = editingItem as? AddEditProductControllerEditingData {
            onEditItem(input, editingItem: editingItem)
        } else {
            if editingItem == nil {
                onAddItem(input)
            } else {
                QL4("Cast didn't work: \(editingItem)")
            }
        }
    }
    
    func onQuickListOpen() {
    }
    
    func onAddProductOpen() {
    }
    
    func onAddGroupOpen() {
    }
    
    func onAddGroupItemsOpen() {
    }
    
    func parentViewForAddButton() -> UIView {
        // this is a hack, with view the button shows below to where it should be. With super view it works. Not time to find out. Defaulting to view because superview is optional and prefer to avoid ! TODO improve this
        return view.superview ?? view
    }
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void) {
        Providers.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(name: String) {
        clearAndLoadFirstPage()
    }
    
    func onRemovedBrand(name: String) {
        clearAndLoadFirstPage()
    }
    
    // MARK: -
    
    private func indexPathForProduct(product: Product) -> NSIndexPath? {
        let indexMaybe = filteredProducts.enumerate().filter{$0.element.item.same(product)}.first?.index
        return indexMaybe.map{NSIndexPath(forRow: $0, inSection: 0)}
    }

    private func updateProductUI(product: Product) {
        if let indexPath = indexPathForProduct(product) {
            updateProductUI(product, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.updateProductUI: Info: product to be updated was not in table view: \(product)")
        }
    }
    
    private func updateProductUI(product: Product, indexPath: NSIndexPath) {

        tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
            for i in 0..<weakSelf.filteredProducts.count {
                if weakSelf.filteredProducts[i].item.same(product) {
                    let item = ItemWithCellAttributes(item: product, boldRange: product.name.range(weakSelf.searchText, caseInsensitive: true))
                    weakSelf.filteredProducts[i] = item
                    if let cell = weakSelf.tableView.cellForRowAtIndexPath(indexPath) as? ManageProductsCell {
                        cell.product = item
                    }
                }
            }
        }

        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
        initNavBar([.Edit])
    }
    
    private func addProductUI(product: Product) {
        let item = ItemWithCellAttributes(item: product, boldRange: product.name.range(searchText, caseInsensitive: true))
        filteredProducts.append(item)
        onUpdatedProducts()
        setAddEditProductControllerOpen(false)
    }

    private func setAddEditProductControllerOpen(open: Bool) {
        topQuickAddControllerManager?.expand(open)
        initNavBar([.Edit])
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        synced(self) {[weak self] in guard let weakSelf = self else {return}
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    Providers.productProvider.products(weakSelf.searchText, range: weakSelf.paginator.currentPage, sortBy: weakSelf.sortBy, weakSelf.successHandler{products in
                        
                        let productWithCellAttributes = products.products.map{product in
                            return ItemWithCellAttributes(item: product, boldRange: product.name.range(weakSelf.searchText, caseInsensitive: true))
                        }
                        weakSelf.filteredProducts.appendAll(productWithCellAttributes)
                        
                        weakSelf.paginator.update(products.products.count)
                        
                        weakSelf.tableView.reloadData()
                        setLoading(false)
                    })
                }
            }
        }
    }
    
    private func toggleEditing() {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = expand ? view.frame.height : 10
        searchBoxHeightConstraint.constant = expand ? 0 : DimensionsManager.searchBarHeight
        searchBoxMarginTopConstraint.constant = expand ? 0 : 10
//        searchBoxMarginBottomConstraint.constant = expand ? 0 : 10
        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
    }
    
    // MARK: - Websocket
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    addProductUI(notification.obj)
                case .Update:
                    updateProductUI(notification.obj)
                case .Delete:
                    removeProductUI(notification.obj)
                default: QL4("Not handled verb: \(notification.verb)")
                }
            } else {
                QL4("Error: ManageProductsViewController.onWebsocketProduct: no value")
            }
        } else {
            QL4("Error: ManageProductsViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    func onWebsocketProductCategory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    clearAndLoadFirstPage()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    clearAndLoadFirstPage()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        clearAndLoadFirstPage()
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
            let picker = createPicker()
            let popup = MyTipPopup(customView: picker)
            if let row = (sortByOptions.indexOf{$0.value == sortBy}) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
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

struct AddEditProductControllerEditingData {
    let product: Product
    let indexPath: NSIndexPath
    init(product: Product, indexPath: NSIndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}