//
//  ManageBrandsController.swift
//  shoppin
//
//  Created by ischuetz on 19/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import Providers

class ManageBrandsController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, EditBrandControllerDelegate, ListTopBarViewDelegate, ExpandableTopViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!
    
    @IBOutlet weak var topControlTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchBar: UISearchBar!
    fileprivate var editButton: UIBarButtonItem!
    
    fileprivate let paginator = Paginator(pageSize: 100)
    fileprivate var loadingPage: Bool = false
    
    fileprivate var searchText: String = ""
    
    fileprivate var filteredBrands: [ItemWithCellAttributes<String>] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    
    fileprivate let toggleButtonInactiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 0.05, rotation: 0, xRight: 20)
    fileprivate let toggleButtonAvailableAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: 0, xRight: 20)
    fileprivate let toggleButtonActiveAction = FLoatingButtonAttributedAction(action: .toggle, alpha: 1, rotation: CGFloat(-Double.pi / 4))
    
    fileprivate var addEditBrandControllerManager: ExpandableTopViewController<EditBrandController>?
    
    fileprivate var updatingBrand: AddEditBrandControllerEditingData?
    
    override func viewWillAppear(_ animated: Bool) {
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
        
        initNavBar([.edit])
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    @objc func onSubmitTap(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            addEditBrandControllerManager?.controller?.submit()
        }
    }
    
    @objc func onEditTap(_ sender: UIBarButtonItem) {
        toggleEditing()
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Brands"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .save:
                let button = UIBarButtonItem(image: UIImage(named: "tb_done")!, style: .plain, target: self, action: #selector(ManageBrandsController.onSubmitTap(_:)))
                buttons.append(button)
            case .edit:
                let button = UIBarButtonItem(image: UIImage(named: "tb_edit")!, style: .plain, target: self, action: #selector(ManageBrandsController.onEditTap(_:)))
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    fileprivate func initAddEditBrandControllerManager() -> ExpandableTopViewController<EditBrandController> {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredBrands.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "brandCell", for: indexPath) as! ManageBrandsCell
        let brand = filteredBrands[(indexPath as NSIndexPath).row]
        cell.item = brand
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let brand = filteredBrands[(indexPath as NSIndexPath).row]
            Prov.brandProvider.removeProductsWithBrand(brand.item, remote: true, successHandler {[weak self] in
                self?.removeBrandUI(brand, indexPath: indexPath)
            })
        }
    }
    
    fileprivate func removeBrandUI(_ brand: String) {
        if let indexPath = indexPathForBrand(brand) {
            let wrappedBrand = ItemWithCellAttributes<String>(item: brand, boldRange: nil)
            removeBrandUI(wrappedBrand, indexPath: indexPath)
        } else {
            print("ManageBrandsViewController.removeBrandUI: Info: brand to be updated was not in table view: \(brand)")
        }
    }
    
    fileprivate func removeBrandUI(_ brand: ItemWithCellAttributes<String>, indexPath: IndexPath) {
        tableView.wrapUpdates {[weak self] in
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            _ = self?.filteredBrands.remove(brand)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    fileprivate func filter(_ searchText: String) {
        self.searchText = searchText
        clearAndLoadFirstPage()
    }
    
    fileprivate func onUpdatedBrands() {
        if let searchText = searchBar.text {
            filter(searchText)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let inventoryItem = filteredBrands[(indexPath as NSIndexPath).row].item
            updatingBrand = AddEditBrandControllerEditingData(brand: inventoryItem, indexPath: indexPath)
            addEditBrandControllerManager?.expand(true)
            addEditBrandControllerManager?.controller?.brand = updatingBrand
            initNavBar([.edit, .save])
        }
    }
    
    fileprivate func clearSearch() {
        searchBar.text = ""
        filteredBrands = []
    }
    
    // MARK: - EditBrandControllerDelegate
    
    func onValidationErrors(_ errors: ValidatorDictionary<ValidationError>) {
        present(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onBrandUpdated(_ brand: AddEditBrandControllerEditingData) {
        updateBrandUI(brand.brand, indexPath: brand.indexPath)
    }
    
    fileprivate func indexPathForBrand(_ brand: String) -> IndexPath? {
        let indexMaybe = filteredBrands.enumerated().filter{$0.element.item == brand}.first?.offset
        return indexMaybe.map{IndexPath(row: $0, section: 0)}
    }
    
    fileprivate func updateBrandUI(_ brand: String) {
        if let indexPath = indexPathForBrand(brand) {
            updateBrandUI(brand, indexPath: indexPath)
        } else {
            print("ManageBrandsViewController.updateBrandUI: Info: brand to be updated was not in table view: \(brand)")
        }
    }
    
    fileprivate func updateBrandUI(_ brand: String, indexPath: IndexPath) {
        // for now we will not do "content based" update like everywhere else in the app for these cases - content based it's a bit better than indexpath based, since maybe while we have the edit controller open we update the list (e.g remove an item on another device -> websocket notificaton) which makes index path invalid. We can't do this here because we use only strings.
//        brands.update(brand)
        guard (indexPath as NSIndexPath).row < filteredBrands.count else {return}
        
        let itemWithCellAttributes = ItemWithCellAttributes(item: brand, boldRange: brand.range(brand, caseInsensitive: true))
        
        filteredBrands[(indexPath as NSIndexPath).row] = itemWithCellAttributes

        onUpdatedBrands()
        
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        addEditBrandControllerManager?.expand(false)
        initNavBar([.edit])
    }
    
    fileprivate func setAddEditBrandControllerOpen(_ open: Bool) {
        addEditBrandControllerManager?.expand(open)
    }
    
    fileprivate func loadPossibleNextPage() {
        
        func setLoading(_ loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.isHidden = !loading
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)

                    Prov.brandProvider.brandsContainingText(weakSelf.searchText, range: weakSelf.paginator.currentPage, weakSelf.successHandler{brands in
                        
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
        _ = navigationController?.popViewController(animated: true)
    }
    
    func onTopBarTitleTap() {
    }
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .submit:
            if tableView.isEditing {
                addEditBrandControllerManager?.controller?.submit()
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
        
        if addEditBrandControllerManager?.expanded ?? false { // it's open - close
            addEditBrandControllerManager?.expand(false)
            initNavBar([.edit])

        } else { // it's closed - open
            addEditBrandControllerManager?.expand(true)
            initNavBar([.edit])
        }
    }
    
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    func onExpandableClose() {
        initNavBar([.edit])
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
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
    let indexPath: IndexPath
    init(brand: String, indexPath: IndexPath) {
        self.brand = brand
        self.indexPath = indexPath
    }
}
