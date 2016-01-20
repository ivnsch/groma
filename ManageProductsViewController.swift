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

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, AddEditListItemViewControllerDelegate, ListTopBarViewDelegate, ExpandableTopViewControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var topBar: ListTopBarView!

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
    
    private var addEditProductControllerManager: ExpandableTopViewController<AddEditListItemViewController>?

    private var updatingProduct: AddEditProductControllerEditingData?
    
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

        navigationController?.setNavigationBarHidden(true, animated: false)

        initTopBar()
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditProductControllerManager = initAddEditProductControllerManager()

        topBar.delegate = self
        topBar.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        Providers.productProvider.products(paginator.currentPage, sortBy: sortBy, successHandler {[weak self] products in
            self?.products = products
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func initTopBar() {
        topBar.setBackVisible(true)
        topBar.title = "Products"
        topBar.positionTitleLabelLeft(true, animated: false)
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonIds([.ToggleOpen])
    }
    
    private func initAddEditProductControllerManager() -> ExpandableTopViewController<AddEditListItemViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<AddEditListItemViewController> =  ExpandableTopViewController(top: top, height: 180, animateTableViewInset: false, parentViewController: self, tableView: tableView) {
            let controller = UIStoryboard.addEditListItemViewController()
            controller.delegate = self
            controller.onViewDidLoad = {
                controller.modus = .Product
            }
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
            Providers.productProvider.productsContainingText(searchText, successHandler{[weak self] products in
                if let weakSelf = self {

                    let productWithCellAttributes = products.map{product in
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
            let inventoryItem = filteredProducts[indexPath.row].item
            updatingProduct = AddEditProductControllerEditingData(product: inventoryItem, indexPath: indexPath)
            addEditProductControllerManager?.expand(true)
            addEditProductControllerManager?.controller?.updatingItem = AddEditItem(item: inventoryItem)
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredProducts = ItemWithCellAttributes.toItemsWithCellAttributes(products)
    }
    
    // MARK: - AddEditListItemViewControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand) {
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        if let updatingProduct = updatingProduct {
            if let price = priceText.floatValue { // Note quantity for product is ignored
                updateProduct(updatingProduct, name: name, category: category, categoryColor: categoryColor, price: price, brand: brand)
            }
        } else {
            print("Warn: InventoryItemsController.onUpdateTap: No updatingProduct")
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, successHandler: VoidFunction? = nil) {
        if let price = priceText.floatValue {
            addProduct(name, category: category, categoryColor: categoryColor, price: price, baseQuantity: baseQuantity, unit: unit, brand: brand)
        } else {
            print("Error: ManageProductsViewController.submitInputs: Invalid price: \(priceText)")
        }
    }

    private func updateProduct(editingData: AddEditProductControllerEditingData, name: String, category: String, categoryColor: UIColor, price: Float, brand: String?) {
        let updatedCategory = editingData.product.category.copy(name: category, color: categoryColor)
        let updatedProduct = editingData.product.copy(name: name, price: price, category: updatedCategory, brand: brand)
        Providers.productProvider.update(updatedProduct, remote: true, successHandler{[weak self] in
            self?.updateProductUI(updatedProduct, indexPath: editingData.indexPath)
        })
    }
    
    private func addProduct(name: String, category: String, categoryColor: UIColor, price: Float, baseQuantity: Float, unit: ProductUnit, brand: String) {
        let product = ProductInput(name: name, price: price, category: category, categoryColor: categoryColor, baseQuantity: baseQuantity, unit: unit, brand: brand)
        Providers.productProvider.add(product, successHandler {[weak self] product in
            self?.addProductUI(product)
        })
    }
    
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
        addEditProductControllerManager?.expand(false)
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    private func addProductUI(product: Product) {
        products.append(product)
        onUpdatedProducts()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: filteredProducts.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
        setAddEditProductControllerOpen(false)
    }

    private func setAddEditProductControllerOpen(open: Bool) {
        addEditProductControllerManager?.expand(open)
        if open {
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformIdentity, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
        } else {
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
        }
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

    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func onTopBarTitleTap() {
    }
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Submit:
            if tableView.editing {
                addEditProductControllerManager?.controller?.submit(.Update)
            } else {
                addEditProductControllerManager?.controller?.submit(.Add)
            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            toggleEditing()
        default: print("Error: ManageProductsViewController.onTopBarButtonTap: No handled action: \(buttonId)")
        }
    }
    
    private func toggleEditing() {
        tableView.setEditing(!tableView.editing, animated: true)
    }
    
    private func toggleTopAddController() {
        
        if addEditProductControllerManager?.expanded ?? false { // it's open - close
            addEditProductControllerManager?.expand(false)
            
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            
        } else { // it's closed - open
            addEditProductControllerManager?.expand(true)
            
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        topControlTopConstraint.constant = view.frame.height
        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
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
                }
            } else {
                print("Error: ManageProductsViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: ManageProductsViewController.onWebsocketProduct: no userInfo")
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

private struct AddEditProductControllerEditingData {
    let product: Product
    let indexPath: NSIndexPath
    init(product: Product, indexPath: NSIndexPath) {
        self.product = product
        self.indexPath = indexPath
    }
}