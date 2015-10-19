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
}

enum QuickAddItemType {
    case Product, Group
}

class QuickAddListItemViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    
    @IBOutlet weak var orderAlphabeticallyButton: UIButton!
    @IBOutlet weak var showGroupsButton: UIButton!
    @IBOutlet weak var showProductsButton: UIButton!
    
    var delegate: QuickAddListItemDelegate?
    
    var itemType: QuickAddItemType = .Product // for now product/group mutually exclusive (no mixed tableview)
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    @IBAction func onCloseTap(sender: UIButton) {
        delegate?.onCloseQuickAddTap()
    }
    
    @IBAction func onOrderAlphabeticallyTap(sender: UIButton) {
        // TODO
    }
    
    @IBAction func onShowGroupsTap(sender: UIButton) {
        loadGroups()
        toggleItemTypeButtons(false)
    }
    
    @IBAction func onShowProductsTap(sender: UIButton) {
        loadProducts()
        toggleItemTypeButtons(true)
    }
    
    // Toggle for showProduct state - if showing product, show product button has to be disabled and group enabled, same for group
    // Assumes only 2 possible states, product and group (Bool)
    private func toggleItemTypeButtons(showProduct: Bool) {
        showGroupsButton.enabled = showProduct
        showProductsButton.enabled = !showProduct
    }
}
