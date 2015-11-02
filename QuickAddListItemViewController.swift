//
//  QuickAddListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

// TODO rename this controller in only groups controller and remove the old groups controller. Also delegate methods not with "Add" but simply "Tap" - the implementation of this delegate decides what the tap means.

protocol QuickAddListItemDelegate {
    func onAddProduct(product: Product)
    func onAddGroup(group: ListItemGroup)
    func onCloseQuickAddTap()
//    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
}

enum QuickAddItemType {
    case Product, Group
}

enum QuickAddContent {
    case Items, AddProduct
}

// Table view controller with searchbox, used for items or groups quick add
class QuickAddListItemViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!

    var delegate: QuickAddListItemDelegate?
    var itemType: QuickAddItemType = .Product { // for now product/group mutually exclusive (no mixed tableview)
        didSet {
            if itemType != oldValue {
                loadItems()
            }
        }
    }
    
    // TODO generic name maybe items or so
    var quickAddItems: [QuickAddItem] = [] {
        didSet {
            filteredQuickAddItems = quickAddItems
        }
    }
    
    private var filteredQuickAddItems: [QuickAddItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var open: Bool = false

    var onViewDidLoad: VoidFunction? // ensure called after outlets set
    
    private let paginator = Paginator(pageSize: 20)
    private var loadingPage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        
        onViewDidLoad?()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        quickAddItems = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    func loadItems() {
        switch itemType {
        case .Product:
            loadProducts()
        case .Group:
            loadGroups()
        }
    }
    
    private func loadGroups() {
        Providers.listItemGroupsProvider.groups(successHandler{[weak self] groups in
            self?.quickAddItems = groups.map{QuickAddGroup($0)}
        })
    }

    private func loadProducts() {
        Providers.productProvider.products(successHandler{[weak self] products in
            self?.quickAddItems = products.map{QuickAddProduct($0)}
        })
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filter(searchText)
    }
    
    private func filter(searchText: String) {
        if searchText.isEmpty {
            filteredQuickAddItems = quickAddItems
        } else {
            switch itemType {
            case .Product:
                Providers.productProvider.productsContainingText(searchText, successHandler{[weak self] products in
                    self?.quickAddItems = products.map{QuickAddProduct($0)}
                })
            case .Group:
                Providers.listItemGroupsProvider.groupsContainingText(searchText, successHandler{[weak self] groups in
                    self?.quickAddItems = groups.map{QuickAddGroup($0)}
                })
            }
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredQuickAddItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = filteredQuickAddItems[indexPath.row]

        var cell: UITableViewCell
        if let productItem = item as? QuickAddProduct {
            let itemCell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! QuickAddItemCell
            itemCell.item = productItem
            cell = itemCell
            
        } else if let groupItem = item as? QuickAddGroup {
            let groupCell = tableView.dequeueReusableCellWithIdentifier("groupCell", forIndexPath: indexPath) as! QuickAddGroupCell
            groupCell.item = groupItem
            cell = groupCell
            
        } else {
            print("Error: invalid model type in quickAddItems: \(item)")
            cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) // assign something so it compiles
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let item = filteredQuickAddItems[indexPath.row]
        
        if let productItem = item as? QuickAddProduct {
            delegate?.onAddProduct(productItem.product)
            
        } else if let groupItem = item as? QuickAddGroup {
            delegate?.onAddGroup(groupItem.group)
            
        } else {
            print("Error: invalid model type in quickAddItems, select cell. \(item)")
        }
    }
    
    func scrollToBottom() {
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: quickAddItems.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.editing = editing
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
            self.tableViewFooter.hidden = !loading
        }
        
        func onItemsLoaded(items: [QuickAddItem]) {
            quickAddItems.appendAll(items)
            
            paginator.update(items.count)
            
            tableView.reloadData()
            setLoading(false)
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd {
                
                if (!weakSelf.loadingPage) {
                    setLoading(true)
                    
                    switch weakSelf.itemType {
                    case .Product:
                        Providers.productProvider.products(weakSelf.paginator.currentPage, weakSelf.successHandler{products in
                            let quickAddItems = products.map{QuickAddProduct($0)}
                            onItemsLoaded(quickAddItems)
                        })
                    case .Group:
                        Providers.listItemGroupsProvider.groups(weakSelf.paginator.currentPage, weakSelf.successHandler{groups in
                            let quickAddItems = groups.map{QuickAddGroup($0)}
                            onItemsLoaded(quickAddItems)
                        })
                    }
                }
            }
        }
    }
}
