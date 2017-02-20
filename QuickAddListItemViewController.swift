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
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float)
    
    func onAddItem(_ item: Item)

    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs)
    
    func onAddGroup(_ group: ProductGroup)
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickListController: QuickAddListItemViewController)
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onCloseQuickAddTap()
    func onHasItems(_ hasItems: Bool)
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)
    
    func parentViewForAddButton() -> UIView?
}

/// For internal communication with other top controllers
protocol QuickAddListItemTopControllersDelegate: class {
    func hideKeyboard()
    func restoreKeyboard()
}

enum QuickAddItemType {
    case product, group, recipe, productForList, ingredients
}

enum QuickAddContent {
    case items, addProduct
}


class QuickAddListItemViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    
    weak var delegate: QuickAddListItemDelegate?
    weak var topControllersDelegate: QuickAddListItemTopControllersDelegate?
    
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
    
    fileprivate var recipeControllerAnimator: GromFromViewControlerAnimator?
    fileprivate var selectQuantifiableAnimator: GromFromViewControlerAnimator?
    fileprivate var selectIngredientAnimator: GromFromViewControlerAnimator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
        
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.sectionInset = UIEdgeInsetsMake(0, 12, 0, 12)
        } else {
            QL4("Invalid collection view layout - can't set insets")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        clearAndLoadFirstPage(false)
        
        initAddRecipeAnimator()
    }
    
    fileprivate func initAddRecipeAnimator() {
        guard let parent = parent?.parent?.parent?.parent else {QL4("Parent is not set"); return} // parent until view shows on top of quick view + list but not navigation/tab bar
        
        recipeControllerAnimator = GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
        selectQuantifiableAnimator = GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
        selectIngredientAnimator = GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
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
    
    fileprivate func toRecipeSortBy(_ sortBy: QuickAddItemSortBy) -> RecipeSortBy {
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
            
        } else if let recipe = item as? QuickAddRecipe {
            let groupCell = collectionView.dequeueReusableCell(withReuseIdentifier: "groupCell", for: indexPath) as! QuickAddGroupCell
            groupCell.item = recipe
            cell = groupCell
            
        } else if let dbItemItem = item as? QuickAddDBItem {
            let dbItemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! QuickAddItemCell
            dbItemCell.item = dbItemItem
            cell = dbItemCell
            
        } else {
            QL4("Error: invalid model type in quickAddItems: \(item)")
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
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
    
    // Doesn't work
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return UIEdgeInsetsMake(0, 12, 0, 12)
//    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = filteredQuickAddItems[(indexPath as NSIndexPath).row]

        // Comment for product and group items: Increment items immediately in memory, then do db update with the incremented items. We could do the increment in database (which is a bit more reliable), but this requires us to fetch first the item which makes the operation relatively slow. We also have to add list items at the same time and this operation should not slow others. And for favs reliability is not very important.
        // TODO!!! review when testing server sync that - when adding many items quickly - the list item count in server is the same. In the simulator it's visible how the updateFav operation for some reason "cuts" the adding of items, that is if we tap a product 20 times very quickly normally it will continue adding until 20 after we stop tapping. But with updateFav, it just adds until we stop tapping. This operation touches only the product, which makes this weird, as the increment list items affects the listitem but shouldn't affect the product. But for some reason it seems to "cut" the pending listitem increments (?). So problem is, maybe when we tap 20 times - we send 20 request to the server, which processes it correctly and adds 20 items, but due to the "cut" we add less than 20 in the client. So when we do sync we suddenly see more items than what we thought we added.
        // One possible solution for this is to store the favs in this class, and do a batch update / fav increment only when the user exists quick add.
        
        if let productItem = item as? QuickAddProduct {
//            productItem.product.fav += 1 // TODO!!!!!!!!!!!!!!!!!!
//            Prov.productProvider.incrementFav(quantifiableProductUuid: productItem.product.uuid, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
            
            // TODO!!!!!!! show popup with units if more than 1 quantifiable product for this product!
            
            retrieveQuantifiableProduct(product: productItem.product, indexPath: indexPath) {[weak self] (quantifiableProduct, quantity) in
                self?.delegate?.onAddProduct(quantifiableProduct, quantity: quantity)
            }
            
        } else if let recipeItem = item as? QuickAddRecipe {
//            groupItem.group.fav += 1 // TODO!!!!!!!!!!!!!!!!!!
//            don't wait for db incrementFav - this operation is not critical
            Prov.recipeProvider.incrementFav(recipeItem.recipe.uuid, successHandler{})
            
            guard let cell = collectionView.cellForItem(at: indexPath) else {QL4("Unexpected: No cell for index path: \(indexPath)"); return}

            recipeControllerAnimator?.open (button: cell, inset: (left: 0, top: 0, right: 0, bottom: 0), controllerCreator: {[weak self] in guard let weakSelf = self else {return nil}
                let controller = AddRecipeController()
                controller.delegate = weakSelf
                controller.list = weakSelf.list
                controller.recipe = recipeItem.recipe
                return controller
            })
            
        } else if let dbItemItem = item as? QuickAddDBItem {
            retrieveQuickAddIngredient(item: dbItemItem.item, indexPath: indexPath) {[weak self] (quantifiableProduct, quantity) in
                self?.delegate?.onAddItem(dbItemItem.item)
            }
            
        } else {
            print("Error: invalid model type in quickAddItems, select cell. \(item)")
        }
    }
    
    fileprivate func retrieveQuantifiableProduct(product: Product, indexPath: IndexPath, onRetrieved: @escaping (QuantifiableProduct, Float) -> Void) {
        Prov.productProvider.quantifiableProducts(product: product, successHandler{quantifiableProducts in
            
            if let first = quantifiableProducts.first, quantifiableProducts.count == 1 {
                onRetrieved(first, 1)
                
            } else if quantifiableProducts.count > 1 {

                guard let cell = self.collectionView.cellForItem(at: indexPath) else {QL4("Unexpected: No cell for index path: \(indexPath)"); return}
                
                // TODO!!!!!!!!!!!!!!!!!!!!!!!! bottom inset different varies for different screen sizes - bottom border has to be slightly about keyboard
                self.selectQuantifiableAnimator?.open (button: cell, inset: Insets(left: 50, top: 60, right: 50, bottom: 360), scrollOffset: self.collectionView.contentOffset.y, controllerCreator: {[weak self] in guard let weakSelf = self else {return nil}
                    let selectQuantifiableProductController = UIStoryboard.selectQuantifiableController()
                    
                    selectQuantifiableProductController.onSelected = {(quantifiableProduct, quantity) in
                        onRetrieved((quantifiableProduct, quantity))
                        weakSelf.selectQuantifiableAnimator?.close()
                    }
                    
                    selectQuantifiableProductController.onViewDidLoad = {[weak selectQuantifiableProductController] in
                        selectQuantifiableProductController?.quantifiableProducts = quantifiableProducts
                    }
                    
                    selectQuantifiableProductController.view.layer.cornerRadius = Theme.popupCornerRadius

                    return selectQuantifiableProductController
                })

            } else {
                QL3("Invalid state?: No quantifiable product for product: \(product.uuid)::\(product.item.name). Creating a new quantifiable product.") // we create a new one as "emergency solution". TODO review this - maybe this is not an invalid state - if a user e.g. deletes all the quantifiable products in product manager (this isn't possible yet but it may be implemented in the future), it's possible that we keep only the product but no quantifiable products for it. So we either have to ensure there's always a quantifiable product for a product or allow to create them "lazily" here.

                Prov.unitProvider.units(self.successHandler {units in
                    
                    guard let noneUnit = units.findFirst({$0.id == .none}) else {
                        let errorMsg = "2 Invalid states: (1) Didn't find a quantifiable product for a product, (2) couldn't retrieve .none unit -crash!"
                        QL4(errorMsg)
                        fatalError(errorMsg)
                    }
                    
                    let newQuantifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantityFloat: 1, unit: noneUnit, product: product)
                    Prov.productProvider.add(newQuantifiableProduct, self.successHandler {
                        onRetrieved(newQuantifiableProduct, 1)
                    })
                })
            }
        })
    }
    
    fileprivate func retrieveQuickAddIngredient(item: Item, indexPath: IndexPath, onRetrieved: @escaping (QuickAddIngredientInput, Float) -> Void) {
        
        guard let cell = collectionView.cellForItem(at: indexPath) else {QL4("Unexpected: No cell for index path: \(indexPath)"); return}

        view.endEditing(true)
        topControllersDelegate?.hideKeyboard()
        
        // Note: the height of the quick add is somewhere up in hierarchy, we pass the hardcoded DimensionsManager value because it's quicker to implement
        selectIngredientAnimator?.open (button: cell, frame: CGRect(x: 0, y: 0, width: view.width, height: DimensionsManager.quickAddHeight), scrollOffset: self.collectionView.contentOffset.y, addOverlay: false, controllerCreator: {[weak self] in
            let selectQuantifiableProductController = UIStoryboard.selectIngredientDataController()
            
            selectQuantifiableProductController.onViewDidLoad = {[weak selectQuantifiableProductController] in
                selectQuantifiableProductController?.item = item
            }
        
            selectQuantifiableProductController.delegate = self
            
            return selectQuantifiableProductController
        })
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
        
        func loadItems() {
            
            Prov.itemsProvider.items(searchText, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                QL1("Loaded items, current search: \(self?.searchText), range: \(self?.paginator.currentPage), sortBy: \(self?.contentData.sortBy), result search: \(tuple.substring), results: \(tuple.items.count)")
                
                // TODO!!!!!!!!!!!!!!!!!!!!!!!!! review if pagination is working (in loadProductsForList and loadItems as well) - either way we should be using Realm's Results instead
                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    if tuple.substring == weakSelf.searchText {
                        let quickAddItems = tuple.items.toArray().map{QuickAddDBItem($0, boldRange: $0.name.range(weakSelf.searchText, caseInsensitive: true))} // TODO don't map to array...
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
        
        
        func loadProducts() {
            
            Prov.productProvider.products(searchText, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                QL1("Loaded products, current search: \(self?.searchText), range: \(self?.paginator.currentPage), sortBy: \(self?.contentData.sortBy), result search: \(tuple.substring), results: \(tuple.products.count)")

                // TODO!!!!!!!!!!!!!!!!!!!!!!!!! review if pagination is working (in loadProductsForList and loadItems as well) - either way we should be using Realm's Results instead
                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    if tuple.substring == weakSelf.searchText {
                        let quickAddItems = tuple.products.map{QuickAddProduct($0, boldRange: $0.item.name.range(weakSelf.searchText, caseInsensitive: true))}
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
                        let quickAddItems = tuple.productsWithMaybeSections.map{QuickAddProduct($0.product, colorOverride: $0.section.map{$0.color}, boldRange: $0.product.item.name.range(weakSelf.searchText, caseInsensitive: true))}
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
        
        func loadRecipes() {
            
            Prov.recipeProvider.recipes(substring: searchText, range: paginator.currentPage, sortBy: toRecipeSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                if let weakSelf = self {
                    
                    if tuple.substring == weakSelf.searchText { // See comment about this above in products
                        let quickAddItems = tuple.recipes.map{QuickAddRecipe($0, boldRange: $0.name.range(weakSelf.searchText, caseInsensitive: true))}
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
                    case .recipe:
                        loadRecipes()
                    case .productForList:
                        loadProductsForList()
                    case .ingredients:
                        loadItems()
                    }
                }
            }
        }
    }
    
    @IBAction func onEmptyViewTap(_ sender: UIButton) {
        tabBarController?.selectedIndex = Constants.tabGroupsIndex
    }
 
    /// Return true to consume the event (i.e. prevent closing of this controller)
    func onTapNavBarCloseTap() -> Bool {
        return closeChildControllers()
    }
    
    func closeChildControllers() -> Bool {
        
        var isAnyShowing: Bool = false
        
        if recipeControllerAnimator?.isShowing ?? false {
            recipeControllerAnimator?.close()
            isAnyShowing = true
        }
        if selectQuantifiableAnimator?.isShowing ?? false {
            selectQuantifiableAnimator?.close()
            isAnyShowing = true
        }
        if selectIngredientAnimator?.isShowing ?? false {
            selectIngredientAnimator?.close()
            (selectIngredientAnimator?.controller as? SelectIngredientDataController)?.onClose() // important to remove the submit button, that is added to parent
            topControllersDelegate?.restoreKeyboard()
            isAnyShowing = true
        }
        
        return isAnyShowing
    }
    
    func closeRecipeController() {
        recipeControllerAnimator?.close()
    }
    
    deinit {
        QL1("Deinit quick add item controller")
    }
}

// MARK: - AddRecipeControllerDelegate

extension QuickAddListItemViewController: AddRecipeControllerDelegate {
    
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], addRecipeController: AddRecipeController) {
        delegate?.onAddRecipe(ingredientModels: ingredientModels, quickListController: self)
    }
    
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        delegate?.getAlreadyHaveText(ingredient: ingredient, handler)
    }
}


// MARK: - SelectIngredientDataControllerDelegate

extension QuickAddListItemViewController: SelectIngredientDataControllerDelegate {
    
    func onSubmitIngredientInputs(item: Item, inputs: SelectIngredientDataControllerInputs) {
        delegate?.onAddIngredient(item: item, ingredientInput: inputs)
        (selectIngredientAnimator?.controller as? SelectIngredientDataController)?.onClose()
        topControllersDelegate?.restoreKeyboard()
        selectIngredientAnimator?.close()
    }
    
    func parentViewForAddButton() -> UIView? {
        return delegate?.parentViewForAddButton()
    }
}
