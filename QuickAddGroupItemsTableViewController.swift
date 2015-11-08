//
//  QuickAddGroupItemsTableViewController.swift
//  shoppin
//
//  Created by ischuetz on 08/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuickAddGroupItemsTableViewControllerDelegate {
    func onCloseQuickAddTap()
    func onGroupItemPlusTap(product: Product)
    func onGroupItemMinusTap(product: Product)
}

class QuickAddGroupItemsTableViewController: UIViewController, QuickAddProductCellDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var tableViewFooter: LoadingFooter!
    
    var delegate: QuickAddGroupItemsTableViewControllerDelegate?
    
    // TODO generic name maybe items or so
    var quickAddItems: [QuickAddProduct] = [] {
        didSet {
            filteredQuickAddItems = quickAddItems
        }
    }
    
    private var filteredQuickAddItems: [QuickAddProduct] = [] {
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
        loadProducts()
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
            filteredQuickAddItems = quickAddItems.map{$0.clearBoldRangeCopy()}
        } else {
            
            Providers.productProvider.productsContainingText(searchText, successHandler{[weak self] products in
                self?.quickAddItems = products.map{QuickAddProduct($0, boldRange: $0.name.range(searchText, caseInsensitive: true))}
            })
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredQuickAddItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = filteredQuickAddItems[indexPath.row]
        
        let itemCell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! QuickAddProductCell
        itemCell.item = item
        itemCell.indexPath = indexPath
        itemCell.delegate = self
        
        return itemCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = filteredQuickAddItems[indexPath.row]
        delegate?.onGroupItemPlusTap(item.product)
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
        
        func onItemsLoaded(items: [QuickAddProduct]) {
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
                    Providers.productProvider.products(weakSelf.paginator.currentPage, weakSelf.successHandler{products in
                        let quickAddItems = products.map{QuickAddProduct($0)}
                        onItemsLoaded(quickAddItems)
                    })
                }
            }
        }
    }
    
    // MARK: - QuickAddProductCellDelegate
    
    func onPlusTap(indexPath: NSIndexPath) {
        let item = filteredQuickAddItems[indexPath.row]
        delegate?.onGroupItemPlusTap(item.product)
    }
    
    func onMinusTap(indexPath: NSIndexPath) {
        let item = filteredQuickAddItems[indexPath.row]
        delegate?.onGroupItemMinusTap(item.product)
    }
}