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
    
    var contentData: (itemType: QuickAddItemType, sortBy: QuickAddItemSortBy) = (.Product, .Fav) {
        didSet {
            if contentData.itemType != oldValue.itemType || contentData.sortBy != oldValue.sortBy {
                loadItems()
            }
        }
    }
    
    var onViewDidLoad: VoidFunction? // ensure called after outlets set
    
    private let paginator = Paginator(pageSize: 100)
    private var loadingPage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        clearAndLoadFirstPage()
    }
    
    private func clearAndLoadFirstPage() {
        quickAddItems = []
        paginator.reset()
        loadPossibleNextPage()
    }
    
    func loadItems() {
        switch contentData.itemType {
        case .Product:
            loadProducts()
        case .Group:
            loadGroups()
        }
    }

    private func toGroupSortBy(sortBy: QuickAddItemSortBy) -> GroupSortBy {
        switch sortBy {
        case .Alphabetic: return .Alphabetic
        case .Fav: return .Fav
        }
    }
    
    private func toProductSortBy(sortBy: QuickAddItemSortBy) -> ProductSortBy {
        switch sortBy {
        case .Alphabetic: return .Alphabetic
        case .Fav: return .Fav
        }
    }
    
    private func loadGroups() {
        
        Providers.listItemGroupsProvider.groups(paginator.currentPage, sortBy: toGroupSortBy(contentData.sortBy), successHandler{[weak self] groups in
            self?.quickAddItems = groups.map{QuickAddGroup($0)}
        })
    }
    
    private func loadProducts() {
        Providers.productProvider.products(paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), successHandler{[weak self] products in
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
            switch contentData.itemType {
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
            cell = itemCell
            
        } else if let groupItem = item as? QuickAddGroup {
            let groupCell = collectionView.dequeueReusableCellWithReuseIdentifier("groupCell", forIndexPath: indexPath) as! QuickAddGroupCell
            groupCell.item = groupItem
            cell = groupCell
            
        } else {
            print("Error: invalid model type in quickAddItems: \(item)")
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("itemCell", forIndexPath: indexPath) // assign something so it compiles
            cell.contentView.backgroundColor = UIColor.flatGrayColorDark()
        }
     
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
            let textSize = item.labelText.size(Fonts.verySmallLight).increase(0, dy: 6)
            filteredQuickAddItems[indexPath.row].textSize = textSize // cache calculated text size
            return textSize
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let item = filteredQuickAddItems[indexPath.row]

        // Comment for product and group items: Increment items immediately in memory, then do db update with the incremented items. We could do the increment in database (which is a bit more reliable), but this requires us to fetch first the item which makes the operation relatively slow. We also have to add list items at the same time and this operation should not slow others. And for favs reliability is not very important.
        // TODO!!! review when testing server sync that - when adding many items quickly - the list item count in server is the same. In the simulator it's visible how the updateFav operation for some reason "cuts" the adding of items, that is if we tap a product 20 times very quickly normally it will continue adding until 20 after we stop tapping. But with updateFav, it just adds until we stop tapping. This operation touches only the product, which makes this weird, as the increment list items affects the listitem but shouldn't affect the product. But for some reason it seems to "cut" the pending listitem increments (?). So problem is, maybe when we tap 20 times - we send 20 request to the server, which processes it correctly and adds 20 items, but due to the "cut" we add less than 20 in the client. So when we do sync we suddenly see more items than what we thought we added.
        // One possible solution for this is to store the favs in this class, and do a batch update / fav increment only when the user exists quick add.
        
        if let productItem = item as? QuickAddProduct {
            productItem.product.fav++
            Providers.productProvider.updateFav(productItem.product, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
            delegate?.onAddProduct(productItem.product)
            
        } else if let groupItem = item as? QuickAddGroup {
            groupItem.group.fav++
            Providers.listItemGroupsProvider.update(groupItem.group, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
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
                    
                    switch weakSelf.contentData.itemType {
                    case .Product:
                        Providers.productProvider.products(weakSelf.paginator.currentPage, sortBy: weakSelf.toProductSortBy(weakSelf.contentData.sortBy), weakSelf.successHandler{products in
                            let quickAddItems = products.map{QuickAddProduct($0)}
                            onItemsLoaded(quickAddItems)
                        })
                    case .Group:
                        Providers.listItemGroupsProvider.groups(weakSelf.paginator.currentPage, sortBy: weakSelf.toGroupSortBy(weakSelf.contentData.sortBy), weakSelf.successHandler{groups in
                            let quickAddItems = groups.map{QuickAddGroup($0)}
                            onItemsLoaded(quickAddItems)
                        })
                    }
                }
            }
        }
    }
}
