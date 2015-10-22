//
//  QuickAddListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

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
    
    var delegate: QuickAddListItemDelegate?
    var itemType: QuickAddItemType = .Product { // for now product/group mutually exclusive (no mixed tableview)
        didSet {
            if itemType != oldValue {
                loadItems()
            }
        }
    }
    
    private var quickAddItems: [QuickAddItem] = [] {
        didSet {
            filteredQuickAddItems = quickAddItems
        }
    }
    
    private var filteredQuickAddItems: [QuickAddItem] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
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
        filteredQuickAddItems = {
            if searchText.isEmpty {
                return quickAddItems
            } else {
                return quickAddItems.filter{$0.labelText.contains(searchText, caseInsensitive: true)}
            }
        }()
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
}
