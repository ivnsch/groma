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
    fileprivate var editButton: UIBarButtonItem!
    fileprivate var addButton: UIBarButtonItem!
    
    fileprivate let paginator = Paginator(pageSize: 20)
    fileprivate var loadingPage: Bool = false
    
    fileprivate var filteredCategories: [ItemWithCellAttributes<ProductCategory>] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    fileprivate var searchText: String = ""

    fileprivate let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 0.05, rotation: 0, xRight: 20)
    fileprivate let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: 0, xRight: 20)
    fileprivate let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    fileprivate var addEditCategoryControllerManager: ExpandableTopViewController<EditProductCategoryController>?
    
    fileprivate var updatingProduct: AddEditCategoryControllerEditingData?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        clearAndLoadFirstPage(false)
    }
    
    func clearAndLoadFirstPage(_ isSearchLoad: Bool) {
        filteredCategories = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage(isSearchLoad)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditCategoryControllerManager = initAddEditProductControllerManager()
        
        initNavBar([.edit])
        
        NotificationCenter.default.addObserver(self, selector: #selector(ManageProductCategoriesController.onWebsocketProductCategory(_:)), name: NSNotification.Name(rawValue: WSNotificationName.ProductCategory.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ManageProductCategoriesController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func onSubmitTap(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            addEditCategoryControllerManager?.controller?.submit()
        }
    }
    
    func onEditTap(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Categories"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .save:
                let button = UIBarButtonItem(image: UIImage(named: "tb_done")!, style: .plain, target: self, action: #selector(ManageProductCategoriesController.onSubmitTap(_:)))
                buttons.append(button)
            case .edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .plain, target: self, action: #selector(ManageProductCategoriesController.onEditTap(_:)))
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    fileprivate func initAddEditProductControllerManager() -> ExpandableTopViewController<EditProductCategoryController> {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as! ManageProductCategoryCell
        
        let item = filteredCategories[(indexPath as NSIndexPath).row]
        
        cell.item = item
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            ConfirmationPopup.show(message: "Warning: This will remove all the list, group, inventory, history and stats items that reference this category", controller: self, onOk: {[weak self] in
                if let weakSelf = self {
                    let category = weakSelf.filteredCategories[(indexPath as NSIndexPath).row]
                    Providers.productCategoryProvider.remove(category.item, remote: true, weakSelf.successHandler{
                        weakSelf.removeCategoryUI(category, indexPath: indexPath)
                    })
                }
            })
        }
    }
    
    fileprivate func removeCategoryUI(_ category: ProductCategory) {
        if let indexPath = indexPathForCategory(category) {
            let wrappedCategory = ItemWithCellAttributes<ProductCategory>(item: category, boldRange: nil)
            removeCategoryUI(wrappedCategory, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.removeCategoryUI: Info: category to be updated was not in table view: \(category)")
        }
    }
    
    fileprivate func removeCategoryUI(_ category: ItemWithCellAttributes<ProductCategory>, indexPath: IndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            _ = self?.filteredCategories.remove(category)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    fileprivate func filter(_ searchText: String) {
        self.searchText = searchText
        clearAndLoadFirstPage(true)
    }
    
    fileprivate func onUpdatedCategories() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let inventoryItem = filteredCategories[(indexPath as NSIndexPath).row].item
            updatingProduct = AddEditCategoryControllerEditingData(category: inventoryItem, indexPath: indexPath)
            addEditCategoryControllerManager?.expand(true)
            addEditCategoryControllerManager?.controller?.category = updatingProduct
            initNavBar([.edit, .save])
        }
    }
    
    fileprivate func clearSearch() {
        searchBar.text = ""
        filteredCategories = []
    }
    
    // MARK: - EditProductCategoryControllerDelegate
    
    func onValidationErrors(_ errors: ValidatorDictionary<ValidationError>) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onCategoryUpdated(_ editingData: AddEditCategoryControllerEditingData) {
        updateCategoryUI(editingData.category, indexPath: editingData.indexPath)
    }
    
    fileprivate func indexPathForCategory(_ category: ProductCategory) -> IndexPath? {
        let indexMaybe = filteredCategories.enumerated().filter{$0.element.item.same(category)}.first?.offset
        return indexMaybe.map{IndexPath(row: $0, section: 0)}
    }
    
    fileprivate func updateCategoryUI(_ category: ProductCategory) {
        if let indexPath = indexPathForCategory(category) {
            updateCategoryUI(category, indexPath: indexPath)
        } else {
            print("ManageProductsViewController.updateCategoryUI: Info: product to be updated was not in table view: \(category)")
        }
    }
    
    fileprivate func updateCategoryUI(_ category: ProductCategory, indexPath: IndexPath) {
        // TODO content based not index based update. Index path can become invalid e.g. if in the meantime we get a websocket update that changes the list.
        guard (indexPath as NSIndexPath).row < filteredCategories.count else {return}
        
        let itemWithCellAttributes = ItemWithCellAttributes(item: category, boldRange: category.name.range(searchText, caseInsensitive: true))
        
        filteredCategories[(indexPath as NSIndexPath).row] = itemWithCellAttributes
        
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        addEditCategoryControllerManager?.expand(false)
        initNavBar([.edit])
    }
    
    fileprivate func addCategoryUI(_ category: ProductCategory) {
        let wrappedCategory = ItemWithCellAttributes<ProductCategory>(item: category, boldRange: nil)
        filteredCategories.append(wrappedCategory)
        onUpdatedCategories()
        tableView.scrollToRow(at: IndexPath(row: filteredCategories.count - 1, section: 0), at: .top, animated: true)
        setAddEditProductControllerOpen(false)
    }
    
    fileprivate func setAddEditProductControllerOpen(_ open: Bool) {
        addEditCategoryControllerManager?.expand(open)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage(false)
        }
    }
    
    fileprivate func loadPossibleNextPage(_ isSearchLoad: Bool) {
        // TODO: has to be adjusted to new Results api. Category controller is not enabled in the app yet so skipping for now
//        
//        func setLoading(_ loading: Bool) {
//            self.loadingPage = loading
//            self.tableViewFooter.isHidden = !loading
//        }
//        
//        synced(self) {[weak self] in
//            let weakSelf = self!
//            
//            if !weakSelf.paginator.reachedEnd || isSearchLoad { // if pagination, load only if we are not at the end, for search load always
//                
//                if (!weakSelf.loadingPage) {
//                    if !isSearchLoad { // block on pagination to avoid loading multiple times on scroll. No blocking on search - here we have to process each key stroke
//                        setLoading(true)
//                    }
//                
//                    Providers.productCategoryProvider.categoriesContainingText(weakSelf.searchText, range: weakSelf.paginator.currentPage, weakSelf.successHandler{tuple in
//                        
//                        // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
//                        // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
//                        
//                        print("current search in the box: \(weakSelf.searchText), result text: \(tuple.text). results: \(tuple.categories)")
//                        
//                        
//                        if tuple.text == weakSelf.searchText {
//
//                            let categoriesWithCellAttributes = tuple.categories.map {category in
//                                ItemWithCellAttributes(item: category, boldRange: category.name.range(weakSelf.searchText, caseInsensitive: true))
//                            }
//                            weakSelf.filteredCategories.appendAll(categoriesWithCellAttributes)
//                            
//                            weakSelf.paginator.update(tuple.categories.count)
//                            
//                            weakSelf.tableView.reloadData()
//                            
//                            setLoading(false)
//                            
//                        } else {
//                            setLoading(false)
//                        }
//                    })
//                }
//            }
//        }
    }
    
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onTopBarTitleTap() {
    }
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .submit:
            if tableView.isEditing {
                addEditCategoryControllerManager?.controller?.submit()
            }
        case .toggleOpen:
            toggleTopAddController()
        case .edit:
            toggleEditing()
        default: print("Error: ManageProductsViewController.onTopBarButtonTap: No handled action: \(buttonId)")
        }
    }
    
    fileprivate func toggleEditing() {
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    fileprivate func toggleTopAddController() {
        
        if addEditCategoryControllerManager?.expanded ?? false { // it's open - close
            addEditCategoryControllerManager?.expand(false)
            initNavBar([.edit])
            
        } else { // it's closed - open
            addEditCategoryControllerManager?.expand(true)
            initNavBar([.edit])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
//        topControlTopConstraint.constant = view.frame.height
//        self.view.layoutIfNeeded()
    }
    
    func onExpandableClose() {
        initNavBar([.edit])
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
    }
    
    // MARK: - Websocket
    
    func onWebsocketProductCategory(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ProductCategory>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    clearAndLoadFirstPage(true)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
        // TODO notification - note has the sender name
        clearAndLoadFirstPage(true) // TODO parameter "isSearchLoad" bad naming - describe better what the flag is for, also in other controllers where this is used
    }
}

struct AddEditCategoryControllerEditingData {
    let category: ProductCategory
    let indexPath: IndexPath
    init(category: ProductCategory, indexPath: IndexPath) {
        self.category = category
        self.indexPath = indexPath
    }
}
