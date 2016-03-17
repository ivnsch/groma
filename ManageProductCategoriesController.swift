//
//  ManageProductCategoriesController.swift
//  shoppin
//
//  Created by ischuetz on 20/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

class ManageProductCategoriesController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EditProductCategoryControllerDelegate, ListTopBarViewDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!
    
//    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UISearchBar!
    private var editButton: UIBarButtonItem!
    private var addButton: UIBarButtonItem!
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    private var filteredCategories: [ItemWithCellAttributes<ProductCategory>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private var searchText: String = ""

    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private var addEditCategoryControllerManager: ExpandableTopViewController<EditProductCategoryController>?
    
    private var updatingProduct: AddEditCategoryControllerEditingData?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        clearAndLoadFirstPage(false)
    }
    
    func clearAndLoadFirstPage(isSearchLoad: Bool) {
        filteredCategories = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage(isSearchLoad)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditCategoryControllerManager = initAddEditProductControllerManager()
        
        initNavBar([.Edit])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        if tableView.editing {
            addEditCategoryControllerManager?.controller?.submit()
        }
    }
    
    func onEditTap(sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Categories"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Save:
                let button = UIBarButtonItem(image: UIImage(named: "tb_done")!, style: .Plain, target: self, action: "onSubmitTap:")
                buttons.append(button)
            case .Edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .Plain, target: self, action: "onEditTap:")
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    private func initAddEditProductControllerManager() -> ExpandableTopViewController<EditProductCategoryController> {
        let top: CGFloat = 64
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
        
        let item = filteredCategories[indexPath.row]
        
        cell.item = item
        
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
                    Providers.productCategoryProvider.remove(category.item, remote: true, weakSelf.successHandler{
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
            self?.filteredCategories.remove(category)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    private func filter(searchText: String) {
        self.searchText = searchText
        clearAndLoadFirstPage(true)
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
            initNavBar([.Edit, .Save])
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredCategories = []
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
        let indexMaybe = filteredCategories.enumerate().filter{$0.element.item.same(category)}.first?.index
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
        // TODO content based not index based update. Index path can become invalid e.g. if in the meantime we get a websocket update that changes the list.
        guard indexPath.row < filteredCategories.count else {return}
        
        let itemWithCellAttributes = ItemWithCellAttributes(item: category, boldRange: category.name.range(searchText, caseInsensitive: true))
        
        filteredCategories[indexPath.row] = itemWithCellAttributes
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        addEditCategoryControllerManager?.expand(false)
        initNavBar([.Edit])
    }
    
    private func addCategoryUI(category: ProductCategory) {
        let wrappedCategory = ItemWithCellAttributes<ProductCategory>(item: category, boldRange: nil)
        filteredCategories.append(wrappedCategory)
        onUpdatedCategories()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: filteredCategories.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
        setAddEditProductControllerOpen(false)
    }
    
    private func setAddEditProductControllerOpen(open: Bool) {
        addEditCategoryControllerManager?.expand(open)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage(false)
        }
    }
    
    private func loadPossibleNextPage(isSearchLoad: Bool) {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd || isSearchLoad { // if pagination, load only if we are not at the end, for search load always
                
                if (!weakSelf.loadingPage) {
                    if !isSearchLoad { // block on pagination to avoid loading multiple times on scroll. No blocking on search - here we have to process each key stroke
                        setLoading(true)
                    }
                
                    Providers.productCategoryProvider.categoriesContainingText(weakSelf.searchText, range: weakSelf.paginator.currentPage, weakSelf.successHandler{tuple in
                        
                        // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                        // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                        
                        print("current search in the box: \(weakSelf.searchText), result text: \(tuple.text). results: \(tuple.categories)")
                        
                        
                        if tuple.text == weakSelf.searchText {

                            let categoriesWithCellAttributes = tuple.categories.map {category in
                                ItemWithCellAttributes(item: category, boldRange: category.name.range(weakSelf.searchText, caseInsensitive: true))
                            }
                            weakSelf.filteredCategories.appendAll(categoriesWithCellAttributes)
                            
                            weakSelf.paginator.update(tuple.categories.count)
                            
                            weakSelf.tableView.reloadData()
                            
                            setLoading(false)
                            
                        } else {
                            setLoading(false)
                        }
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
            initNavBar([.Edit])
            
        } else { // it's closed - open
            addEditCategoryControllerManager?.expand(true)
            initNavBar([.Edit])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
//        topControlTopConstraint.constant = view.frame.height
//        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        initNavBar([.Edit])
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
    }
    
    // MARK: - Websocket
    
    func onWebsocketProductCategory(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    clearAndLoadFirstPage(true)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    clearAndLoadFirstPage(true)
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
        clearAndLoadFirstPage(true) // TODO parameter "isSearchLoad" bad naming - describe better what the flag is for, also in other controllers where this is used
    }
}

struct AddEditCategoryControllerEditingData {
    let category: ProductCategory
    let indexPath: NSIndexPath
    init(category: ProductCategory, indexPath: NSIndexPath) {
        self.category = category
        self.indexPath = indexPath
    }
}