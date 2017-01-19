//
//  QuickAddListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

// TODO rename this controller in only groups controller and remove the old groups controller. Also delegate methods not with "Add" but simply "Tap" - the implementation of this delegate decides what the tap means.

protocol QuickAddListItemDelegate: class {
    func onAddProduct(_ product: QuantifiableProduct)
    func onAddGroup(_ group: ProductGroup)
    func onCloseQuickAddTap()
    func onHasItems(_ hasItems: Bool)
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
}

enum QuickAddItemType {
    case product, group, productForList
}

enum QuickAddContent {
    case items, addProduct
}


class QuickAddListItemViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    
    weak var delegate: QuickAddListItemDelegate?
    
    fileprivate var filteredQuickAddItems: [QuickAddItem] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var open: Bool = false
    
    var contentData: (itemType: QuickAddItemType, sortBy: QuickAddItemSortBy) = (.product, .fav) {
        didSet {
//            if contentData.itemType != oldValue.itemType || contentData.sortBy != oldValue.sortBy {
                clearAndLoadFirstPage(false)
                
//            }
        }
    }
    
    // The search for which items are filtered
    var searchText: String = "" {
        didSet {
            if searchText != oldValue {
                clearAndLoadFirstPage(true)
            } else {
                QL2("Search text is equal to last value: \(searchText) - doing nothing")
            }
        }
    }
    
    var onViewDidLoad: VoidFunction? // ensure called after outlets set
    
    fileprivate let paginator = Paginator(pageSize: 100)
    fileprivate var loadingPage: Bool = false
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        clearAndLoadFirstPage(false)
    }
    
    fileprivate func clearAndLoadFirstPage(_ isSearchLoad: Bool) {
        filteredQuickAddItems = []
        paginator.reset()
        loadPossibleNextPage(isSearchLoad)
    }

    fileprivate func toGroupSortBy(_ sortBy: QuickAddItemSortBy) -> GroupSortBy {
        switch sortBy {
        case .alphabetic: return .alphabetic
        case .fav: return .fav
        }
    }
    
    fileprivate func toProductSortBy(_ sortBy: QuickAddItemSortBy) -> ProductSortBy {
        switch sortBy {
        case .alphabetic: return .alphabetic
        case .fav: return .fav
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredQuickAddItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = filteredQuickAddItems[(indexPath as NSIndexPath).row]
        
        var cell: UICollectionViewCell
        if let productItem = item as? QuickAddProduct {
            let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! QuickAddItemCell
            itemCell.item = productItem
            cell = itemCell
            
        } else if let groupItem = item as? QuickAddGroup {
            let groupCell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupCell", for: indexPath) as! QuickAddGroupCell
            groupCell.item = groupItem
            cell = groupCell
            
        } else {
            print("Error: invalid model type in quickAddItems: \(item)")
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) // assign something so it compiles
            cell.contentView.backgroundColor = UIColor.flatGrayDark
        }
     
        if !item.didAnimateAlready { // show cell grow animation while scrolling down
            cell.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            let delay = TimeInterval(Double((indexPath as NSIndexPath).row) * 0.4 / Double(filteredQuickAddItems.count))
            UIView.animate(withDuration: 0.2, delay: delay, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                cell.transform = CGAffineTransform(scaleX: 1, y: 1)
                }, completion: {finished in
                    item.didAnimateAlready = true
            })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let item = filteredQuickAddItems[(indexPath as NSIndexPath).row]
        
        if let textSize = item.textSize {
            return textSize
        } else {
            let label1TextSize = item.labelText.size(UIFont.systemFont(ofSize: LabelMore.mapToFontSize(30) ?? 12))
            
            // For now use same height for all items independently if they have 2nd label or not.
//            let label2TextSize = item.label2Text?.size(Fonts.verySmallLight) ?? CGSizeZero
            let label2TextSize = item.label2Text.size(Fonts.verySmallLight)
            
            let label3TextSize = item.label3Text.isEmpty ? CGSize.zero : item.label3Text.size(UIFont.systemFont(ofSize: LabelMore.mapToFontSize(20) ?? 12))
            
            let label2Size = min(label2TextSize.width, label1TextSize.width + 30) // allow label2 to be max. 30pt wider than label 1
            let cellWidth = max(label1TextSize.width, label2Size) + DimensionsManager.quickAddCollectionViewCellHPadding // the cell has to be as wide as the widest label, and add some inset (20)
            let finalCellWidth = max(cellWidth, 50) // don't allow cell to have less width than 50pt otherwise shape looks weird
            let cellHeight = label1TextSize.height + label2TextSize.height + label3TextSize.height + DimensionsManager.quickAddCollectionViewCellVPadding // 6: add some space
            
            let textSize = CGSize(width: finalCellWidth, height: cellHeight)
            
            filteredQuickAddItems[(indexPath as NSIndexPath).row].textSize = textSize // cache calculated text size
            
            return textSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = filteredQuickAddItems[(indexPath as NSIndexPath).row]

        // Comment for product and group items: Increment items immediately in memory, then do db update with the incremented items. We could do the increment in database (which is a bit more reliable), but this requires us to fetch first the item which makes the operation relatively slow. We also have to add list items at the same time and this operation should not slow others. And for favs reliability is not very important.
        // TODO!!! review when testing server sync that - when adding many items quickly - the list item count in server is the same. In the simulator it's visible how the updateFav operation for some reason "cuts" the adding of items, that is if we tap a product 20 times very quickly normally it will continue adding until 20 after we stop tapping. But with updateFav, it just adds until we stop tapping. This operation touches only the product, which makes this weird, as the increment list items affects the listitem but shouldn't affect the product. But for some reason it seems to "cut" the pending listitem increments (?). So problem is, maybe when we tap 20 times - we send 20 request to the server, which processes it correctly and adds 20 items, but due to the "cut" we add less than 20 in the client. So when we do sync we suddenly see more items than what we thought we added.
        // One possible solution for this is to store the favs in this class, and do a batch update / fav increment only when the user exists quick add.
        
        if let productItem = item as? QuickAddProduct {
//            productItem.product.fav += 1
//            Prov.productProvider.incrementFav(quantifiableProductUuid: productItem.product.uuid, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
            delegate?.onAddProduct(productItem.product)
            
        } else if let groupItem = item as? QuickAddGroup {
//            groupItem.group.fav += 1
            Prov.listItemGroupsProvider.incrementFav(groupItem.group.uuid, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
            delegate?.onAddGroup(groupItem.group)
            
        } else {
            print("Error: invalid model type in quickAddItems, select cell. \(item)")
        }
    }
    
    func scrollToBottom() {
        collectionView.scrollToItem(at: IndexPath(row: filteredQuickAddItems.count - 1, section: 0), at: .top, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (maximumOffset - currentOffset) <= 40 {
            loadPossibleNextPage(false)
        }
    }
    
    func setEmptyViewVisible(_ visible: Bool) {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.emptyView.isHidden = !visible
        }) 
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
//        collectionView.editing = editing // TODO! collection view doesn't know this - for what did we need editing with tableview here anyway?
    }
    
    // isSearchLoad: true if load is triggered from search box, false if pagination/first load
    fileprivate func loadPossibleNextPage(_ isSearchLoad: Bool) {
        
//        QL1("Called loadPossibleNextPage, isSearchLoad: \(isSearchLoad)")
        
        func setLoading(_ loading: Bool) {
            self.loadingPage = loading
//            self.tableViewFooter.hidden = !loading
        }
        
        func onItemsLoaded(_ items: [QuickAddItem]) {
            
            QL1("onItemsLoaded: \(items.count)")
            
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
            
            Prov.productProvider.quantifiableProducts(searchText, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                QL1("Loaded products, current search: \(self?.searchText), range: \(self?.paginator.currentPage), sortBy: \(self?.contentData.sortBy), result search: \(tuple.substring), results: \(tuple.products.count)")

                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    if tuple.substring == weakSelf.searchText {
                        let quickAddItems = tuple.products.map{QuickAddProduct($0, boldRange: $0.product.name.range(weakSelf.searchText, caseInsensitive: true))}
                        onItemsLoaded(quickAddItems)
                    } else {
                        setLoading(false)
                    }
                }
                }, onError: {[weak self] result in
                    setLoading(false)
                    self?.defaultErrorHandler()(result)
                })
            )
        }
        
        func loadProductsForList() {
            
            guard let list = list else {QL4("Can't load products for list, no list set"); return}
            
            Prov.productProvider.productsWithPosibleSections(searchText, list: list, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                // TODO bug: some times (rarely) it shows nothing after opening quickly and typing (maybe first time?). Log showed 23 results last time is happened. It shows nothing after this line, meaning that onListItems is not called, meaning tuple.substring == weakSelf.searchText is false?
                QL1("Loaded products, current search: \(self?.searchText), range: \(self?.paginator.currentPage), sortBy: \(self?.contentData.sortBy), result search: \(tuple.substring), results: \(tuple.productsWithMaybeSections.count)")
                
                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    QL1("Comparing: #\(tuple.substring)# with #\(weakSelf.searchText)#")
                    if tuple.substring == weakSelf.searchText {
                        let quickAddItems = tuple.productsWithMaybeSections.map{QuickAddProduct($0.product, colorOverride: $0.section.map{$0.color}, boldRange: $0.product.product.name.range(weakSelf.searchText, caseInsensitive: true))}
                        onItemsLoaded(quickAddItems)
                    } else {
                        setLoading(false)
                    }
                }
                }, onError: {[weak self] result in
                    setLoading(false)
                    self?.defaultErrorHandler()(result)
                })
            )
        }
        
        func loadGroups() {
            
            Prov.listItemGroupsProvider.groups(searchText, range: paginator.currentPage, sortBy: toGroupSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
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
                    self?.defaultErrorHandler()(result)
                })
            )
        }
        
        synced(self) {[weak self] in
            let weakSelf = self!
            
//            QL1("Trying to load: \(weakSelf.contentData.itemType) current page: \(weakSelf.paginator.currentPage), reachedEnd: \(weakSelf.paginator.reachedEnd), isSearchLoad: \(isSearchLoad)")

            if !weakSelf.paginator.reachedEnd || isSearchLoad { // if pagination, load only if we are not at the end, for search load always
                
                if (!weakSelf.loadingPage) {
                    if !isSearchLoad { // block on pagination to avoid loading multiple times on scroll. No blocking on search - here we have to process each key stroke
                        setLoading(true)
                    }
                
                    switch weakSelf.contentData.itemType {
                    case .product:
                        loadProducts()
                    case .group:
                        loadGroups()
                    case .productForList:
                        loadProductsForList()
                    }
                }
            }
        }
    }
    
    @IBAction func onEmptyViewTap(_ sender: UIButton) {
        tabBarController?.selectedIndex = Constants.tabGroupsIndex
    }
    
    deinit {
        QL1("Deinit quick add item controller")
    }
}
