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

    fileprivate let paginator = Paginator(pageSize: 20)
    fileprivate var loadingPage: Bool = false
    
    fileprivate var searchText: String = "" {
        didSet {
            clearAndLoadFirstPage()
        }
    }
    
    fileprivate var filteredProducts: [ItemWithCellAttributes<Product>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var sortBy: ProductSortBy = .fav {
        didSet {
            if sortBy != oldValue {
                if let option = sortByOption(sortBy) {
                    sortByButton.setTitle(option.key, for: UIControlState())
                } else {
                    QL3("No option for \(sortBy)")
                }
                clearAndLoadFirstPage()
            }
        }
    }
    @IBOutlet weak var sortByButton: UIButton!
    fileprivate var sortByPopup: CMPopTipView?
    fileprivate let sortByOptions: [(value: ProductSortBy, key: String)] = [
        (.fav, trans("sort_by_usage")), (.alphabetic, trans("sort_by_alphabetic"))
    ]
    
    fileprivate let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 0.05, rotation: 0, xRight: 20)
    fileprivate let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: 0, xRight: 20)
    fileprivate let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        clearAndLoadFirstPage()
    }
    
    func clearAndLoadFirstPage() {
        filteredProducts = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    func sortByOption(_ sortBy: ProductSortBy) -> (value: ProductSortBy, key: String)? {
        return sortByOptions.findFirst{$0.value == sortBy}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = trans("title_products")
        
        tableView.allowsSelectionDuringEditing = true
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()

        initNavBar([.edit])
        
        searchBar.addTarget(self, action: #selector(ManageProductsViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        loadPossibleNextPage()
        
        navigationItem.backBarButtonItem?.title = ""
        
        layout()

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(ManageProductsViewController.handleTap(_:)))
        recognizer.delegate = self
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ManageProductsViewController.onWebsocketProduct(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Product.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ManageProductsViewController.onWebsocketProductCategory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProductCategory.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ManageProductsViewController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)        
    }
    
    fileprivate func layout() {
        searchBoxHeightConstraint.constant = DimensionsManager.searchBarHeight
    }
    
    deinit {
        QL1("Deinit manage products controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func handleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func onEditTap(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = trans("title_products")
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .plain, target: self, action: #selector(ManageProductsViewController.onEditTap(_:)))
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    fileprivate func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
//        let top: CGFloat = 55
        let top: CGFloat = 0
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddManageProductsHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.modus = .product
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! ManageProductsCell

        let product = filteredProducts[(indexPath as NSIndexPath).row]

        cell.product = product
        
        cell.contentView.addBottomBorderWithColor(Theme.cellBottomBorderColor, width: 1)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let product = filteredProducts[(indexPath as NSIndexPath).row]
            Providers.productProvider.delete(product.item, remote: true, successHandler{[weak self] in
                self?.removeProductUI(product, indexPath: indexPath)
            })
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    fileprivate func removeProductUI(_ product: Product) {
        if let indexPath = indexPathForProduct(product) {
            let wrappedProduct = ItemWithCellAttributes<Product>(item: product, boldRange: nil)
            removeProductUI(wrappedProduct, indexPath: indexPath)   
        } else {
            print("ManageProductsViewController.removeProductUI: Info: product to be updated was not in table view: \(product)")
        }
    }
    
    fileprivate func removeProductUI(_ product: ItemWithCellAttributes<Product>, indexPath: IndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            _ = self?.filteredProducts.remove(product)
        }
    }
    
    // MARK: - Filter
    
    
    func textFieldDidChange(_ textField: UITextField) {
        filter(textField.text ?? "")
    }
    
    fileprivate func filter(_ searchText: String) {
        self.searchText = searchText
    }
    
    
    // MARK: -
    
    fileprivate func onUpdatedProducts() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let product = filteredProducts[(indexPath as NSIndexPath).row].item
            let productEditData = AddEditProductControllerEditingData(product: product, indexPath: indexPath)
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: productEditData))
            initNavBar([.edit, .save])
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(_ group: ListItemGroup, onFinish: VoidFunction?) {
    }
    
    func onAddProduct(_ product: Product) {
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
        func onEditItem(_ input: ListItemInput, editingItem: AddEditProductControllerEditingData) {
            let updatedCategory = editingItem.product.category.copy(name: input.section, color: input.sectionColor)
            let updatedProduct = editingItem.product.copy(name: input.name, category: updatedCategory, brand: input.brand)
            Providers.productProvider.update(updatedProduct, remote: true, successHandler{[weak self] in
                self?.updateProductUI(updatedProduct, indexPath: editingItem.indexPath)
            })
        }
        
        func onAddItem(_ input: ListItemInput) {
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
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        Providers.productCategoryProvider.categoryWithName(name, successHandler {category in
            handler(category.color)
        })
    }
    
    func onRemovedSectionCategoryName(_ name: String) {
        clearAndLoadFirstPage()
    }
    
    func onRemovedBrand(_ name: String) {
        clearAndLoadFirstPage()
    }
    
    // MARK: -
    
    fileprivate func indexPathForProduct(_ product: Product) -> IndexPath? {
        let indexMaybe = filteredProducts.enumerated().filter{$0.element.item.same(product)}.first?.offset
        return indexMaybe.map{IndexPath(row: $0, section: 0)}
    }

    fileprivate func updateProductUI(_ product: Product) {
        if let indexPath = indexPathForProduct(product) {
            updateProductUI(product, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.updateProductUI: Info: product to be updated was not in table view: \(product)")
        }
    }
    
    fileprivate func updateProductUI(_ product: Product, indexPath: IndexPath) {

        tableView.wrapUpdates {[weak self] in guard let weakSelf = self else {return}
            for i in 0..<weakSelf.filteredProducts.count {
                if weakSelf.filteredProducts[i].item.same(product) {
                    let item = ItemWithCellAttributes(item: product, boldRange: product.name.range(weakSelf.searchText, caseInsensitive: true))
                    weakSelf.filteredProducts[i] = item
                    if let cell = weakSelf.tableView.cellForRow(at: indexPath) as? ManageProductsCell {
                        cell.product = item
                    }
                }
            }
        }

        topQuickAddControllerManager?.expand(false)
        topQuickAddControllerManager?.controller?.onClose()
        initNavBar([.edit])
    }
    
    fileprivate func addProductUI(_ product: Product) {
        let item = ItemWithCellAttributes(item: product, boldRange: product.name.range(searchText, caseInsensitive: true))
        filteredProducts.append(item)
        onUpdatedProducts()
        setAddEditProductControllerOpen(false)
    }

    fileprivate func setAddEditProductControllerOpen(_ open: Bool) {
        topQuickAddControllerManager?.expand(open)
        initNavBar([.edit])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage()
        }
    }
    
    fileprivate func loadPossibleNextPage() {
        
        func setLoading(_ loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.isHidden = !loading
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
    
    fileprivate func toggleEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = expand ? view.frame.height : 10
        searchBoxHeightConstraint.constant = expand ? 0 : DimensionsManager.searchBarHeight
        searchBoxMarginTopConstraint.constant = expand ? 0 : 10
//        searchBoxMarginBottomConstraint.constant = expand ? 0 : 10
        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        topQuickAddControllerManager?.controller?.onClose()
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
    }
    
    // MARK: - Websocket
    
    func onWebsocketProduct(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<Product>> {
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
    
    func onWebsocketProductCategory(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    clearAndLoadFirstPage()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
        // TODO notification - note has the sender name
        clearAndLoadFirstPage()
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

    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = sortByOptions[row].key
        return label
    }
    
    @IBAction func onSortByTap(_ sender: UIButton) {
        if let popup = self.sortByPopup {
            popup.dismiss(animated: true)
        } else {
            let picker = createPicker()
            let popup = MyTipPopup(customView: picker)
            if let row = (sortByOptions.index{$0.value == sortBy}) {
                picker.selectRow(row, inComponent: 0, animated: false)
            }
            popup.presentPointing(at: sortByButton, in: view, animated: true)
        }
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
}

struct AddEditProductControllerEditingData {
    let product: Product
    let indexPath: IndexPath
    init(product: Product, indexPath: IndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}
