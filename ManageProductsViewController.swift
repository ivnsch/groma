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

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, QuickAddDelegate, ExpandableTopViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!

    @IBOutlet weak var searchBar: UISearchBar!
    private var editButton: UIBarButtonItem!
    private var addButton: UIBarButtonItem!

    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var products: [Product] = [] {
        didSet {
            filteredProducts = ItemWithCellAttributes.toItemsWithCellAttributes(products)
        }
    }

    private var filteredProducts: [ItemWithCellAttributes<Product>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var sortBy: ProductSortBy = .Fav
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
        products = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Products"
        
        tableView.allowsSelectionDuringEditing = true
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()

        initNavBar([.Edit])
        
        Providers.productProvider.products(paginator.currentPage, sortBy: sortBy, successHandler {[weak self] products in
            self?.products = products
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func onEditTap(sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
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
        let top: CGFloat = 64
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: 290, openInset: top, closeInset: top, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
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
        let product = filteredProducts[indexPath.row]
        return product.item.brand.isEmpty ? 50 : 64
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
            self?.products.remove(product.item)
            self?.filteredProducts.remove(product)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }

    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredProducts = ItemWithCellAttributes.toItemsWithCellAttributes(products)
        } else {
            // TODO!!! range, check filter concept probably same problem as with quick add.
            // TODO sortby recently added or something, so user sees last added products on top
            Providers.productProvider.products(searchText, range: NSRange(location: 0, length: 10000), sortBy: .Fav, successHandler{[weak self] products in
                if let weakSelf = self {

                    let productWithCellAttributes = products.products.map{product in
                        return ItemWithCellAttributes(item: product, boldRange: product.name.range(searchText, caseInsensitive: true))
                    }
                    weakSelf.filteredProducts = productWithCellAttributes
                }
            })
        }
    }
    
    private func onUpdatedProducts() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
 
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            let product = filteredProducts[indexPath.row].item
            let productEditData = AddEditProductControllerEditingData(product: product, indexPath: indexPath)
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: productEditData))
            initNavBar([.Edit, .Save])
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredProducts = ItemWithCellAttributes.toItemsWithCellAttributes(products)
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
            let updatedProduct = editingItem.product.copy(name: input.name, price: input.price, category: updatedCategory, brand: input.brand, store: input.store)
            Providers.productProvider.update(updatedProduct, remote: true, successHandler{[weak self] in
                self?.updateProductUI(updatedProduct, indexPath: editingItem.indexPath)
            })
        }
        
        func onAddItem(input: ListItemInput) {
            let product = ProductInput(name: input.name, price: input.price, category: input.section, categoryColor: input.sectionColor, baseQuantity: input.baseQuantity, unit: input.unit, brand: input.brand, store: input.store)
            
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
        return self.view
    }
    
    // MARK: -
    
    private func indexPathForProduct(product: Product) -> NSIndexPath? {
        let indexMaybe = products.enumerate().filter{$0.element.same(product)}.first?.index
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
        products.update(product)
        onUpdatedProducts()
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
        initNavBar([.Edit])
    }
    
    private func addProductUI(product: Product) {
        products.append(product)
        onUpdatedProducts()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: filteredProducts.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
        setAddEditProductControllerOpen(false)
    }

    private func setAddEditProductControllerOpen(open: Bool) {
        topQuickAddControllerManager?.expand(open)
        initNavBar([.Edit])
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    Providers.productProvider.products(weakSelf.paginator.currentPage, sortBy: weakSelf.sortBy, weakSelf.successHandler{products in
                        weakSelf.products.appendAll(products)
                        
                        weakSelf.paginator.update(products.count)
                        
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
        topControlTopConstraint.constant = view.frame.height
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

struct AddEditProductControllerEditingData {
    let product: Product
    let indexPath: NSIndexPath
    init(product: Product, indexPath: NSIndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}