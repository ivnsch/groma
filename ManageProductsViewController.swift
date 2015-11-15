//
//  ManageProductsViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class ManageProductsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BottonPanelViewDelegate, AddEditProductControllerDelegate, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

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
    
    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private var addEditProductControllerManager: ExpandableTopViewController<AddEditProductController>?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        products = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initNavBar([.Add])
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditProductControllerManager = initAddEditProductControllerManager()

        Providers.productProvider.products(successHandler {[weak self] products in
            self?.products = products
        })
    }
    
    private func initAddEditProductControllerManager() -> ExpandableTopViewController<AddEditProductController> {
        
        let navbarHeight = navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        let top = navbarHeight + statusBarHeight
        return ExpandableTopViewController(top: top, height: 140, openInset: -CGRectGetHeight(self.searchBar.frame), parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditProductController()
            controller.delegate = self
            return controller
        }
    }
    

    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                self.addButton = button
                buttons.append(button)
            case .Edit:
                let button = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditTap:")
                self.editButton = button
                buttons.append(button)
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            case .Cancel:
                let button = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "onCancelTap:")
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
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
            Providers.productProvider.delete(product.item, successHandler{[weak self] in
                self?.tableView.wrapUpdates {
                    self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    
                    self?.products.remove(product.item)
                    self?.filteredProducts.remove(product)
                }
            })
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
        addEditProductControllerManager?.controller?.editingData = AddEditProductControllerEditingData(product: filteredProducts[indexPath.row].item, indexPath: indexPath)
        addEditProductControllerManager?.expand(true)
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            if !editing {
                addEditProductControllerManager?.expand(false)
            }
        }
        
        initNavBar([.Cancel, .Save]) // remove possible top controller specific action buttons (e.g. on list item update we have a submit button), and set appropiate alpha
        
        tableView.setEditing(editing, animated: animated)

        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    
    func onEditTap(sender: UIBarButtonItem) {
        self.setEditing(!self.editing, animated: true, tryCloseTopViewController: true)
    }
    
    func onAddTap(sender: UIBarButtonItem) {
        if addEditProductControllerManager?.expanded ?? false {
            setAddEditProductControllerOpen(false)
            initNavBar([.Add])
            
        } else {
            clearSearch() // clear filter to avoid confusion, if we add an item it may be not in current filter and user will not see it appearing.
            setAddEditProductControllerOpen(true)
            initNavBar([.Cancel, .Save])
        }
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        addEditProductControllerManager?.controller?.submit()
    }

    func onCancelTap(sender: UIBarButtonItem) {
        setAddEditProductControllerOpen(false)
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredProducts = ItemWithCellAttributes.toItemsWithCellAttributes(products)
    }
    
    // MARK - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        switch action {
        case .Toggle:
            if addEditProductControllerManager?.expanded ?? false {
                addEditProductControllerManager?.expand(false)
                
            } else {
                clearSearch() // clear filter to avoid confusion, if we add an item it may be not in current filter and user will not see it appearing.
                setAddEditProductControllerOpen(true)
            }
            
            
        case .Submit:
            addEditProductControllerManager?.controller?.submit()
            
        case .Add, .Back, .Expand: break
        }
    }
    
    // MARK: - AddEditProductControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
         presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onSubmit(name: String, category: String, price: Float, baseQuantity: Float, unit: ProductUnit, editingData: AddEditProductControllerEditingData?) {
        if let editingData = editingData {
            updateProduct(editingData, name: name, category: category, price: price)
        } else {
            addProduct(name, category: category, price: price, baseQuantity: baseQuantity, unit: unit)
        }
    }
    
    func onCancelTap() {
        setAddEditProductControllerOpen(false)
    }

    private func updateProduct(editingData: AddEditProductControllerEditingData, name: String, category: String, price: Float) {
        let updatedProduct = editingData.product.copy(name: name, price: price, category: category)
        Providers.productProvider.update(updatedProduct, successHandler{[weak self] in
            if let weakSelf = self {
                weakSelf.products.update(updatedProduct)
                weakSelf.onUpdatedProducts()
                
                weakSelf.tableView.scrollToRowAtIndexPath(editingData.indexPath, atScrollPosition: .Middle, animated: true)
                weakSelf.addEditProductControllerManager?.expand(false)
            }
        })
    }
    
    private func addProduct(name: String, category: String, price: Float, baseQuantity: Float, unit: ProductUnit) {
        let product = ProductInput(name: name, price: price, category: category, baseQuantity: baseQuantity, unit: unit)
        Providers.productProvider.add(product, successHandler {[weak self] product in
            if let weakSelf = self {
                weakSelf.products.append(product)
                weakSelf.onUpdatedProducts()
                
                weakSelf.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: weakSelf.filteredProducts.count - 1, inSection: 0), atScrollPosition: .Middle, animated: true)
                weakSelf.addEditProductControllerManager?.expand(false)
            }
        })
    }

    private func setAddEditProductControllerOpen(open: Bool) {
        addEditProductControllerManager?.expand(open)
        
        if open {
            initNavBar([.Save, .Cancel])
            
        } else {
            initNavBar([.Add])
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
                    
                    Providers.productProvider.products(weakSelf.paginator.currentPage, weakSelf.successHandler{products in
                        weakSelf.products.appendAll(products)
                        
                        weakSelf.paginator.update(products.count)
                        
                        weakSelf.tableView.reloadData()
                        setLoading(false)
                    })
                }
            }
        }
    }
}
