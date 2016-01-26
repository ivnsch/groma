//
//  ManageBrandsController.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class ManageBrandsController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EditBrandControllerDelegate, ListTopBarViewDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UISearchBar!
    private var editButton: UIBarButtonItem!
    
    private let paginator = Paginator(pageSize: 100)
    private var loadingPage: Bool = false
    
    private var searchText: String = ""
    
    private var filteredBrands: [ItemWithCellAttributes<String>] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    
    private let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 0.05, rotation: 0, xRight: 20)
    private let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: 0, xRight: 20)
    private let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .Toggle, alpha: 1, rotation: CGFloat(-M_PI_4))
    
    private var addEditBrandControllerManager: ExpandableTopViewController<EditBrandController>?
    
    private var updatingBrand: AddEditBrandControllerEditingData?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        clearAndLoadFirstPage()
    }
    
    func clearAndLoadFirstPage() {
        filteredBrands = []
        paginator.reset()
        tableView.reloadData()
        loadPossibleNextPage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelectionDuringEditing = true
        
        addEditBrandControllerManager = initAddEditBrandControllerManager()
        
        initNavBar([.Edit])
        
        loadPossibleNextPage()
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        if tableView.editing {
            addEditBrandControllerManager?.controller?.submit()
        }
    }
    
    func onEditTap(sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Brands"
        
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
    
    private func initAddEditBrandControllerManager() -> ExpandableTopViewController<EditBrandController> {
        let top: CGFloat = 64
        let manager: ExpandableTopViewController<EditBrandController> =  ExpandableTopViewController(top: top, height: 60, parentViewController: self, tableView: tableView) {
            let controller = EditBrandController()
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
        return filteredBrands.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("brandCell", forIndexPath: indexPath) as! ManageBrandsCell
        let brand = filteredBrands[indexPath.row]
        cell.item = brand
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let brand = filteredBrands[indexPath.row]
            Providers.brandProvider.removeBrand(brand.item, successHandler {[weak self] in
                self?.removeBrandUI(brand, indexPath: indexPath)
            })
        }
    }
    
    private func removeBrandUI(brand: String) {
        if let indexPath = indexPathForBrand(brand) {
            let wrappedBrand = ItemWithCellAttributes<String>(item: brand, boldRange: nil)
            removeBrandUI(wrappedBrand, indexPath: indexPath)
        } else {
            print("ManageBrandsViewController.removeBrandUI: Info: brand to be updated was not in table view: \(brand)")
        }
    }
    
    private func removeBrandUI(brand: ItemWithCellAttributes<String>, indexPath: NSIndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self?.filteredBrands.remove(brand)
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    private func filter(searchText: String) {
        self.searchText = searchText
        clearAndLoadFirstPage()
    }
    
    private func onUpdatedBrands() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            let inventoryItem = filteredBrands[indexPath.row].item
            updatingBrand = AddEditBrandControllerEditingData(brand: inventoryItem, indexPath: indexPath)
            addEditBrandControllerManager?.expand(true)
            addEditBrandControllerManager?.controller?.brand = updatingBrand
            initNavBar([.Edit, .Save])
        }
    }
    
    private func clearSearch() {
        searchBar.text = ""
        filteredBrands = []
    }
    
    // MARK: - EditBrandControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onBrandUpdated(brand: AddEditBrandControllerEditingData) {
        updateBrandUI(brand.brand, indexPath: brand.indexPath)
    }
    
    private func indexPathForBrand(brand: String) -> NSIndexPath? {
        let indexMaybe = filteredBrands.enumerate().filter{$0.element.item == brand}.first?.index
        return indexMaybe.map{NSIndexPath(forRow: $0, inSection: 0)}
    }
    
    private func updateBrandUI(brand: String) {
        if let indexPath = indexPathForBrand(brand) {
            updateBrandUI(brand, indexPath: indexPath)
        } else {
            print("ManageBrandsViewController.updateBrandUI: Info: brand to be updated was not in table view: \(brand)")
        }
    }
    
    private func updateBrandUI(brand: String, indexPath: NSIndexPath) {
        // for now we will not do "content based" update like everywhere else in the app for these cases - content based it's a bit better than indexpath based, since maybe while we have the edit controller open we update the list (e.g remove an item on another device -> websocket notificaton) which makes index path invalid. We can't do this here because we use only strings.
//        brands.update(brand)
        guard indexPath.row < filteredBrands.count else {return}
        
        let itemWithCellAttributes = ItemWithCellAttributes(item: brand, boldRange: brand.range(brand, caseInsensitive: true))
        
        filteredBrands[indexPath.row] = itemWithCellAttributes

        onUpdatedBrands()
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        addEditBrandControllerManager?.expand(false)
        initNavBar([.Edit])
    }
    
    private func setAddEditBrandControllerOpen(open: Bool) {
        addEditBrandControllerManager?.expand(open)
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

                    Providers.brandProvider.brandsContainingText(weakSelf.searchText, range: weakSelf.paginator.currentPage, weakSelf.successHandler{brands in
                        
                        let brandsWithCellAttributes: [ItemWithCellAttributes] = brands.map {brand in
                            ItemWithCellAttributes(item: brand, boldRange: brand.range(weakSelf.searchText, caseInsensitive: true))
                        }
                        
                        weakSelf.filteredBrands.appendAll(brandsWithCellAttributes)
                        
                        weakSelf.paginator.update(brands.count)
                        
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
                addEditBrandControllerManager?.controller?.submit()
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
        
        if addEditBrandControllerManager?.expanded ?? false { // it's open - close
            addEditBrandControllerManager?.expand(false)
            initNavBar([.Edit])

        } else { // it's closed - open
            addEditBrandControllerManager?.expand(true)
            initNavBar([.Edit])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    func onExpandableClose() {
        initNavBar([.Edit])
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
    }
    
    // MARK: - Websocket
    // TODO
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

struct AddEditBrandControllerEditingData {
    let brand: String
    let indexPath: NSIndexPath
    init(brand: String, indexPath: NSIndexPath) {
        self.brand = brand
        self.indexPath = indexPath
    }
}