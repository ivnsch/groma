//
//  ManageProductCategoriesController.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class ManageProductCategoriesController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EditProductCategoryControllerDelegate, ListTopBarViewDelegate, ExpandableTopViewControllerDelegate {

    @IBOutlet weak var topBar: ListTopBarView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!
    
//    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UISearchBar!
    private var editButton: UIBarButtonItem!
    private var addButton: UIBarButtonItem!
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var categories: [ProductCategory] = [] {
        didSet {
            filteredCategories = ItemWithCellAttributes.toItemsWithCellAttributes(categories)
        }
    }
    
    private var filteredCategories: [ItemWithCellAttributes<ProductCategory>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private var addEditCategoryControllerManager: ExpandableTopViewController<EditProductCategoryController>?
    
    private var updatingProduct: AddEditCategoryControllerEditingData?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        clearAndLoadFirstPage()
    }
    
    func clearAndLoadFirstPage() {
        categories = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        initTopBar()
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditCategoryControllerManager = initAddEditProductControllerManager()
        
        topBar.delegate = self
        topBar.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    private func initTopBar() {
        topBar.setBackVisible(true)
        topBar.title = "Categories"
        topBar.positionTitleLabelLeft(true, animated: false)
        topBar.setRightButtonIds([.Edit])
    }
    
    private func initAddEditProductControllerManager() -> ExpandableTopViewController<EditProductCategoryController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<EditProductCategoryController> =  ExpandableTopViewController(top: top, height: 60, animateTableViewInset: false, parentViewController: self, tableView: tableView) {
            let controller = EditProductCategoryController()
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
        return filteredCategories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("categoryCell", forIndexPath: indexPath) as! ManageProductCategoryCell
        
        let product = filteredCategories[indexPath.row]
        
        cell.category = product.item
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            ConfirmationPopup.show(message: "Warning: This will remove all the list, group, inventory, history and stats items that reference this category", controller: self, onOk: {[weak self] in
                if let weakSelf = self {
                    let category = weakSelf.filteredCategories[indexPath.row]
                    Providers.productCategoryProvider.remove(category.item, weakSelf.successHandler{
                        weakSelf.removeCategoryUI(category, indexPath: indexPath)
                    })
                }
            })
        }
    }
    
    private func removeCategoryUI(category: ProductCategory) {
        if let indexPath = indexPathForCategory(category) {
            let wrappedCategory = ItemWithCellAttributes<ProductCategory>(item: category, boldRange: nil)
            removeCategoryUI(wrappedCategory, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.removeCategoryUI: Info: category to be updated was not in table view: \(category)")
        }
    }
    
    private func removeCategoryUI(category: ItemWithCellAttributes<ProductCategory>, indexPath: NSIndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self?.categories.remove(category.item)
            self?.filteredCategories.remove(category)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredCategories = ItemWithCellAttributes.toItemsWithCellAttributes(categories)
        } else {
            Providers.productCategoryProvider.categoriesContainingText(searchText, successHandler{[weak self] categories in
                if let weakSelf = self {
                    
                    let productWithCellAttributes = categories.map{product in
                        return ItemWithCellAttributes(item: product, boldRange: product.name.range(searchText, caseInsensitive: true))
                    }
                    weakSelf.filteredCategories = productWithCellAttributes
                }
            })
        }
    }
    
    private func onUpdatedCategories() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            let inventoryItem = filteredCategories[indexPath.row].item
            updatingProduct = AddEditCategoryControllerEditingData(category: inventoryItem, indexPath: indexPath)
            addEditCategoryControllerManager?.expand(true)
            addEditCategoryControllerManager?.controller?.category = updatingProduct
            topBar.setRightButtonIds([.Submit, .Edit])
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredCategories = ItemWithCellAttributes.toItemsWithCellAttributes(categories)
    }
    
    // MARK: - EditProductCategoryControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onCategoryUpdated(editingData: AddEditCategoryControllerEditingData) {
        updateCategoryUI(editingData.category, indexPath: editingData.indexPath)
    }
    
    private func indexPathForCategory(category: ProductCategory) -> NSIndexPath? {
        let indexMaybe = categories.enumerate().filter{$0.element.same(category)}.first?.index
        return indexMaybe.map{NSIndexPath(forRow: $0, inSection: 0)}
    }
    
    private func updateCategoryUI(category: ProductCategory) {
        if let indexPath = indexPathForCategory(category) {
            updateCategoryUI(category, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.updateCategoryUI: Info: product to be updated was not in table view: \(category)")
        }
    }
    
    private func updateCategoryUI(category: ProductCategory, indexPath: NSIndexPath) {
        categories.update(category)
        onUpdatedCategories()
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
        addEditCategoryControllerManager?.expand(false)
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    private func addCategoryUI(product: ProductCategory) {
        categories.append(product)
        onUpdatedCategories()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: filteredCategories.count - 1, inSection: 0), atScrollPosition: .Middle, animated: true)
        setAddEditProductControllerOpen(false)
    }
    
    private func setAddEditProductControllerOpen(open: Bool) {
        addEditCategoryControllerManager?.expand(open)
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
                
                    Providers.productCategoryProvider.categories(weakSelf.paginator.currentPage, weakSelf.successHandler{categories in
                        weakSelf.categories.appendAll(categories)
                        
                        weakSelf.paginator.update(categories.count)
                        
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
                addEditCategoryControllerManager?.controller?.submit()
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
        
        if addEditCategoryControllerManager?.expanded ?? false { // it's open - close
            addEditCategoryControllerManager?.expand(false)
            topBar.setRightButtonIds([.Edit])
            
        } else { // it's closed - open
            addEditCategoryControllerManager?.expand(true)
            topBar.setRightButtonIds([.Edit])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
//        topControlTopConstraint.constant = view.frame.height
//        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        topBar.setRightButtonIds([.Edit])        
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
    }
    
    // MARK: - Websocket
    // TODO
//    
//    func onWebsocketProduct(note: NSNotification) {
//        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
//            if let notification = info[WSNotificationValue] {
//                switch notification.verb {
//                case .Add:
//                    addProductUI(notification.obj)
//                case .Update:
//                    updateProductUI(notification.obj)
//                case .Delete:
//                    removeProductUI(notification.obj)
//                }
//            } else {
//                print("Error: ManageProductsViewController.onWebsocketProduct: no value")
//            }
//        } else {
//            print("Error: ManageProductsViewController.onWebsocketProduct: no userInfo")
//        }
//    }
}

struct AddEditCategoryControllerEditingData {
    let category: ProductCategory
    let indexPath: NSIndexPath
    init(category: ProductCategory, indexPath: NSIndexPath) {
        self.category = category
        self.indexPath = indexPath
    }
}