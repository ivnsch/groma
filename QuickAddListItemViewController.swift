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
    func onHasItems(hasItems: Bool)
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
}

enum QuickAddItemType {
    case Product, Group
}

enum QuickAddContent {
    case Items, AddProduct
}


class QuickAddListItemViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: QuickAddListItemDelegate?
    
    private var filteredQuickAddItems: [QuickAddItem] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var open: Bool = false
    
    var contentData: (itemType: QuickAddItemType, sortBy: QuickAddItemSortBy) = (.Product, .Fav) {
        didSet {
            if contentData.itemType != oldValue.itemType || contentData.sortBy != oldValue.sortBy {
                clearAndLoadFirstPage(false)
                
            }
        }
    }
    
    // The search for which items are filtered
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                clearAndLoadFirstPage(true)
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
        clearAndLoadFirstPage(false)
    }
    
    private func clearAndLoadFirstPage(isSearchLoad: Bool) {
        filteredQuickAddItems = []
        paginator.reset()
        loadPossibleNextPage(isSearchLoad)
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
            let label1TextSize = item.labelText.size(Fonts.verySmallLight)
            
            // For now use same height for all items independently if they have 2nd label or not.
//            let label2TextSize = item.label2Text?.size(Fonts.verySmallLight) ?? CGSizeZero
            let label2TextSize = item.label2Text?.size(Fonts.verySmallLight) ?? "".size(Fonts.verySmallLight)
            
            let label2Size = min(label2TextSize.width, label1TextSize.width + 30) // allow label2 to be max. 30pt wider than label 1
            let cellWidth = max(label1TextSize.width, label2Size) + 6 // the cell has to be as wide as the widest label, and add some inset (6)
            let cellHeight = label1TextSize.height + label2TextSize.height + 6 // 6: add some space
            
            let textSize = CGSizeMake(cellWidth, cellHeight)
            
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
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: filteredQuickAddItems.count - 1, inSection: 0), atScrollPosition: .Top, animated: true)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage(false)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
//        collectionView.editing = editing // TODO! collection view doesn't know this - for what did we need editing with tableview here anyway?
    }
    
    // isSearchLoad: true if load is triggered from search box, false if pagination/first load
    private func loadPossibleNextPage(isSearchLoad: Bool) {
        
        func setLoading(loading: Bool) {
            self.loadingPage = loading
//            self.tableViewFooter.hidden = !loading
        }
        
        func onItemsLoaded(items: [QuickAddItem]) {
            
            if items.isEmpty {
                delegate?.onHasItems(false)

            } else {
                filteredQuickAddItems.appendAll(items)
                
                paginator.update(items.count)
                
                collectionView.reloadData()
                setLoading(false)
                
                delegate?.onHasItems(true)
            }
        }
        
        func loadProducts() {
            let handler: ProviderResult<(substring: String?, products: [Product])> -> Void = resultHandler(onSuccess: {[weak self] tuple in
                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    if tuple.substring == weakSelf.searchText {
                        let quickAddItems = tuple.products.map{QuickAddProduct($0, boldRange: $0.name.range(weakSelf.searchText, caseInsensitive: true))}
                        onItemsLoaded(quickAddItems)
                    } else {
                        setLoading(false)
                    }
                }
            }, onError: {[weak self] result in
                setLoading(false)
                self?.defaultErrorHandler()(providerResult: result)
            })
            
            Providers.productProvider.products(searchText, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), handler)
        }

        func loadGroups() {
            let handler: ProviderResult<(substring: String?, groups: [ListItemGroup])> -> Void = resultHandler(onSuccess: {[weak self] tuple in
                if let weakSelf = self {
                    
                    if tuple.substring == weakSelf.searchText { // See comment about this above in products
                        let quickAddItems = tuple.groups.map{QuickAddGroup($0, boldRange: $0.name.range(weakSelf.searchText, caseInsensitive: true))}
                        onItemsLoaded(quickAddItems)
                    } else {
                        setLoading(false)
                    }
                }
            }, onError: {[weak self] result in
                setLoading(false)
                self?.defaultErrorHandler()(providerResult: result)
            })
            
            Providers.listItemGroupsProvider.groups(searchText, range: paginator.currentPage, sortBy: toGroupSortBy(contentData.sortBy), handler)
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
            if !weakSelf.paginator.reachedEnd || isSearchLoad { // if pagination, load only if we are not at the end, for search load always
                
                if (!weakSelf.loadingPage) {
                    if !isSearchLoad { // block on pagination to avoid loading multiple times on scroll. No blocking on search - here we have to process each key stroke
                        setLoading(true)
                    }
                
                    switch weakSelf.contentData.itemType {
                    case .Product:
                        loadProducts()
                    case .Group:
                        loadGroups()
                    }
                }
            }
        }
    }
}
