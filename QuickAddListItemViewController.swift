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
class QuickAddListItemViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
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
            collectionView.reloadData()
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
            filteredQuickAddItems = quickAddItems.map{$0.clearBoldRangeCopy()}
        } else {
            switch itemType {
            case .Product:
                Providers.productProvider.productsContainingText(searchText, successHandler{[weak self] products in
                    self?.quickAddItems = products.map{QuickAddProduct($0, boldRange: $0.name.range(searchText, caseInsensitive: true))}
                })
            case .Group:
                Providers.listItemGroupsProvider.groupsContainingText(searchText, successHandler{[weak self] groups in
                    self?.quickAddItems = groups.map{QuickAddGroup($0, boldRange: $0.name.range(searchText, caseInsensitive: true))}
                })
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredQuickAddItems.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = filteredQuickAddItems[indexPath.row]
        
        var cell: UICollectionViewCell
        if let productItem = item as? QuickAddProduct {
            let itemCell = collectionView.dequeueReusableCellWithReuseIdentifier("itemCell", forIndexPath: indexPath) as! QuickAddItemCell
            itemCell.item = productItem
            itemCell.nameLabel.textColor = UIColor.whiteColor()
            cell = itemCell
            
        } else if let groupItem = item as? QuickAddGroup {
            let groupCell = collectionView.dequeueReusableCellWithReuseIdentifier("groupCell", forIndexPath: indexPath) as! QuickAddGroupCell
            groupCell.item = groupItem
            groupCell.nameLabel.textColor = UIColor.whiteColor()
            cell = groupCell
            
        } else {
            print("Error: invalid model type in quickAddItems: \(item)")
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("itemCell", forIndexPath: indexPath) // assign something so it compiles
        }
     
        cell.contentView.backgroundColor = UIColor.flatGrayColorDark()
        
        if !item.didAnimateAlready { // show cell grow animation while scrolling down
            cell.transform = CGAffineTransformMakeScale(0.5, 0.5)
            let delay = NSTimeInterval(Double(indexPath.row) * 0.4 / Double(filteredQuickAddItems.count))
            UIView.animateWithDuration(0.2, delay: delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                cell.transform = CGAffineTransformMakeScale(1, 1)
                }, completion: {finished in
                    item.didAnimateAlready = true
            })
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let item = filteredQuickAddItems[indexPath.row]
        
        if let textSize = item.textSize {
            return textSize
        } else {
            let textSize = item.labelText.size(Fonts.regularLight).increase(6, dy: 6)
            filteredQuickAddItems[indexPath.row].textSize = textSize // cache calculated text size
            return textSize
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
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
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: quickAddItems.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
//        collectionView.editing = editing // TODO! collection view doesn't know this - for what did we need editing with tableview here anyway?
    }
    
    private func loadPossibleNextPage() {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
//            self.tableViewFooter.hidden = !loading
        }
        
        func onItemsLoaded(items: [QuickAddItem]) {
            quickAddItems.appendAll(items)
            
            paginator.update(items.count)
            
            collectionView.reloadData()
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
