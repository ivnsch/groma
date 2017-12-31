//
//  QuickAddListItemViewController.swift
//  shoppin
//
//  Created by ischuetz on 19/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

struct QuickAddAddProductResult {
    public let isNewItem: Bool
}


// TODO rename this controller in only groups controller and remove the old groups controller. Also delegate methods not with "Add" but simply "Tap" - the implementation of this delegate decides what the tap means.

protocol QuickAddListItemDelegate: class {
    func onAddProduct(_ product: QuantifiableProduct, quantity: Float, note: String?, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void)
    
    func onAddItem(_ item: Item)


    func onAddGroup(_ group: ProductGroup)
    func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickListController: QuickAddListItemViewController)
    func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void)
    
    func onCloseQuickAddTap()
    func onHasItems(_ hasItems: Bool)
    //    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect)

    // Ingredients screen specific
    func onAddedIngredientsSubviews()
    var ingredientCellAnimationNameLabelTargetX: CGFloat { get }
    func onAddIngredient(item: Item, ingredientInput: SelectIngredientDataControllerInputs)

    func parentViewForAddButton() -> UIView?
    
    func endEditing()

    // addedItem can be QuantifiableProduct or Item, depending on where we use quick add (in e.g. list/inventory items, we add q.products and in ingredients, items).
    func onFinishAddCellAnimation(addedItem: AnyObject)
    var offsetForAddCellAnimation: CGFloat {get}
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
//            collectionView.reloadData()
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
                logger.d("Search text is equal to last value: \(searchText) - doing nothing")
            }
        }
    }
    
    var onViewDidLoad: VoidFunction? // ensure called after outlets set
    
    fileprivate let paginator = Paginator(pageSize: 100)
    fileprivate var loadingPage: Bool = false
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?
    
    fileprivate var recipeControllerAnimator: GromFromViewControlerAnimator?
    fileprivate var selectQuantifiablePopup: MyPopup?

    // For now only recipes controller sets this (it's needed for the add ingredient scroller)
    var topConstraint: NSLayoutConstraint?
    weak var topController: UIViewController?
    weak var topParentController: UIViewController?

    // Ingredients specific
    fileprivate(set) var scrollableBottomAttacher: ScrollableBottomAttacher<IngredientDataController>?
    fileprivate var lockAddBottomController = false // prevent issues when tapping item fast multiple times
    fileprivate var lockRemoveBottomController = false // prevent issues when tapping item fast multiple times

    override func viewDidLoad() {
        super.viewDidLoad()
        onViewDidLoad?()
        
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.sectionInset = UIEdgeInsetsMake(0, 20, 0, 20)
        } else {
            logger.e("Invalid collection view layout - can't set insets")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        clearAndLoadFirstPage(false)
        
        initAddRecipeAnimator()
    }
    
    fileprivate func initAddRecipeAnimator() {
        
        guard let parent = parent?.parent?.parent?.parent else {logger.e("Parent is not set"); return} // parent until view shows on top of quick view + list but not navigation/tab bar
        //guard let parent = parent?.parent?.parent else {logger.e("Parent is not set"); return} // parent until view shows on top of quick view + list but not navigation/tab bar
        
        recipeControllerAnimator = recipeControllerAnimator ?? GromFromViewControlerAnimator(parent: parent, currentController: self, animateButtonAtEnd: false)
    }
    
    fileprivate func clearAndLoadFirstPage(_ isSearchLoad: Bool) {
        filteredQuickAddItems = []
        collectionView.reloadData()
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
            logger.e("Error: invalid model type in quickAddItems: \(item)")
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
        let item = filteredQuickAddItems[indexPath.row]
        
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
        
        let item = filteredQuickAddItems[indexPath.row]

        // Comment for product and group items: Increment items immediately in memory, then do db update with the incremented items. We could do the increment in database (which is a bit more reliable), but this requires us to fetch first the item which makes the operation relatively slow. We also have to add list items at the same time and this operation should not slow others. And for favs reliability is not very important.
        // TODO!!! review when testing server sync that - when adding many items quickly - the list item count in server is the same. In the simulator it's visible how the updateFav operation for some reason "cuts" the adding of items, that is if we tap a product 20 times very quickly normally it will continue adding until 20 after we stop tapping. But with updateFav, it just adds until we stop tapping. This operation touches only the product, which makes this weird, as the increment list items affects the listitem but shouldn't affect the product. But for some reason it seems to "cut" the pending listitem increments (?). So problem is, maybe when we tap 20 times - we send 20 request to the server, which processes it correctly and adds 20 items, but due to the "cut" we add less than 20 in the client. So when we do sync we suddenly see more items than what we thought we added.
        // One possible solution for this is to store the favs in this class, and do a batch update / fav increment only when the user exists quick add.
        
        if let productItem = item as? QuickAddProduct {
//            productItem.product.fav += 1 // TODO!!!!!!!!!!!!!!!!!!
//            Prov.productProvider.incrementFav(quantifiableProductUuid: productItem.product.uuid, remote: true, successHandler{})
            // don't wait for db incrementFav - this operation is not critical
            
            // TODO!!!!!!! show popup with units if more than 1 quantifiable product for this product!
            
            func onRetrievedQuantifiableProduct(quantifiableProduct: QuantifiableProduct, quantity: Float) {

                delegate?.onAddProduct(quantifiableProduct, quantity: quantity, note: nil) {[weak self] result in
                    if result.isNewItem {
                        self?.animateItemToCell(indexPath: indexPath, quantifiableProduct: quantifiableProduct, quantity: 1)
                    }
                }
            }
            
            retrieveQuantifiableProduct(product: productItem.product, indexPath: indexPath) {(quantifiableProduct, quantity) in
                onRetrievedQuantifiableProduct(quantifiableProduct: quantifiableProduct, quantity: quantity)
            }
            
        } else if let recipeItem = item as? QuickAddRecipe {
//            groupItem.group.fav += 1 // TODO!!!!!!!!!!!!!!!!!!
//            don't wait for db incrementFav - this operation is not critical
            Prov.recipeProvider.incrementFav(recipeItem.recipe.uuid, successHandler{})
            
            guard let cell = collectionView.cellForItem(at: indexPath) else {logger.e("Unexpected: No cell for index path: \(indexPath)"); return}

            delegate?.endEditing()

            recipeControllerAnimator?.open (button: cell, inset: (left: 0, top: 0, right: 0, bottom: 0), controllerCreator: {[weak self] in guard let weakSelf = self else {return nil}
                let controller = AddRecipeController()
                _ = controller.view // Load view / outlets
//                controller.delegate = weakSelf
//                controller.list = weakSelf.list
//                controller.recipe = recipeItem.recipe
                controller.config(recipe: recipeItem.recipe, delegate: weakSelf)
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
    
    fileprivate func animateItemToCell(indexPath: IndexPath, quantifiableProduct: QuantifiableProduct, quantity: Float) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuickAddItemCell else {logger.e("Unexpected: No cell for index path: \(indexPath)"); return}

        let copy = cell.copyCell(quantifiableProduct: quantifiableProduct, quantity: quantity)
        let categoryColorViewWidth: CGFloat = 4
        let targetNameLabelX = DimensionsManager.leftRightPaddingConstraint + categoryColorViewWidth
        animateItemToCell(indexPath: indexPath, addedItem: quantifiableProduct, copy: copy, targetFrameX: categoryColorViewWidth, targetNameLabelX: targetNameLabelX, targetFrameHeight: DimensionsManager.defaultCellHeight)
    }

    fileprivate func animateItemToCell(indexPath: IndexPath, ingredient: Item, targetNameLabelX: CGFloat) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuickAddItemCell else {logger.e("Unexpected: No cell for index path: \(indexPath)"); return}

        let copy = cell.copyCell(ingredient: ingredient)
        animateItemToCell(indexPath: indexPath, addedItem: ingredient, copy: copy, targetFrameX: 0, targetNameLabelX: targetNameLabelX, targetFrameHeight: DimensionsManager.ingredientsCellHeight)
    }

    fileprivate func animateItemToCell(indexPath: IndexPath, addedItem: AnyObject, copy: UIView & QuickAddItemAnimatableCellCopy, targetFrameX: CGFloat, targetNameLabelX: CGFloat, targetFrameHeight: CGFloat) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuickAddItemCell else {logger.e("Unexpected: No cell for index path: \(indexPath)"); return}
        guard let windowMaybe = UIApplication.shared.delegate?.window, let window = windowMaybe else {logger.e("No window: can't animate cell"); return}

        let cellPointInWindow = window.convert(cell.center, from: collectionView)
        window.addSubview(copy)
        copy.center = cellPointInWindow
        
        
        let quickAddFrameRelativeToWindow = window.convert(view.frame, from: view.superview!)
        
        let categoryColorViewWidth: CGFloat = 4

        let targetCellFrame = CGRect(x: targetFrameX, y: quickAddFrameRelativeToWindow.maxY + (delegate?.offsetForAddCellAnimation ?? 0), width: view.width - categoryColorViewWidth, height: targetFrameHeight)

        copy.animateAddToList(targetFrame: targetCellFrame, targetNameLabelX: targetNameLabelX) {[weak self] in
            self?.delegate?.onFinishAddCellAnimation(addedItem: addedItem)
        }
    }

    fileprivate func retrieveQuantifiableProduct(product: Product, indexPath: IndexPath,
                                                 onRetrieved: @escaping (QuantifiableProduct, Float) -> Void) {
        Prov.productProvider.quantifiableProducts(product: product, successHandler{quantifiableProducts in
            
            if let first = quantifiableProducts.first, quantifiableProducts.count == 1 {
                onRetrieved(first, 1)
                
            } else if quantifiableProducts.count > 1 {

                guard let cell = self.collectionView.cellForItem(at: indexPath) else {logger.e("Unexpected: No cell for index path: \(indexPath)"); return}
                
                // TODO!!!!!!!!!!!!!!!!!!!!!!!! bottom inset different varies for different screen sizes - bottom border has to be slightly about keyboard

                let leftRightInset: CGFloat = 50
                let contentFrame = CGRect(
                    x: leftRightInset,
                    y: 30,
                    width: self.view.frame.width - (leftRightInset * 2),
                    height: 220
                )

                guard let parent = self.parent?.parent?.parent?.parent else { logger.e("Parent is not set"); return } // parent until view shows on top of quick view + list but not navigation/tab bar

                let popup = MyPopup(parent: parent.view)
                let selectQuantifiableProductController = UIStoryboard.selectQuantifiableController()
                parent.addChildViewController(selectQuantifiableProductController)

                selectQuantifiableProductController.onSelected = { [weak self, weak popup] tuple in
                    let quantifiableProduct = tuple.0
                    let quantity = tuple.1

                    popup?.hide(onFinish: {
                        self?.selectQuantifiablePopup = nil
                        //                            cell.scaleUpAndDown(scale: 1.1) {
                        onRetrieved(quantifiableProduct, quantity)
                        //                            }
                    })
                }

                selectQuantifiableProductController.onViewDidLoad = {[weak selectQuantifiableProductController] in
                    selectQuantifiableProductController?.quantifiableProducts = quantifiableProducts
                }

                selectQuantifiableProductController.view.size = contentFrame.size

                popup.backgroundAlpha = 0.3
                popup.backgroundFadeDuration = 0.3
                popup.cornerRadius = Theme.popupCornerRadius

                popup.contentView = selectQuantifiableProductController.view

                popup.onTapBackground = { [weak self, weak popup] in
                    self?.selectQuantifiablePopup = nil
                    popup?.hide()
                }

                self.selectQuantifiablePopup = popup

                popup.show(from: cell)

            } else {
                logger.i("No quantifiable product for product: \(product.uuid)::\(product.item.name). Creating a new quantifiable product.") // This state can happen if user deleted a unit or base quantity, which deletes all quantifiable products referencing them.

                // Since there's no quantifiable product for this product, we don't know which unit to use - use default unit.
                Prov.unitProvider.units(buyable: nil, self.successHandler { [weak self] units in guard let wealSelf = self else { return }

                    func onHasDefaultUnit(_ defaultUnit: Providers.Unit) {
                        let newQuantifiableProduct = QuantifiableProduct(uuid: UUID().uuidString, baseQuantity: 1, unit: defaultUnit, product: product)
                        Prov.productProvider.add(newQuantifiableProduct, wealSelf.successHandler {
                            onRetrieved(newQuantifiableProduct, 1)
                        })
                    }

                    if let defaultUnit = units.findFirst({$0.id == .none}) {
                        onHasDefaultUnit(defaultUnit)
                    } else { // The app shouldn't make possible to delete the default unit - so this is an invalid state. But just in case, don't let the app crash, send an error message.
                        logger.e("Invalid state: The default unit was deleted! - recreating.")
                        Prov.unitProvider.addUnit(unitId: .none, name: trans(""), buyable: true, wealSelf.successHandler { addedUnit in
                            onHasDefaultUnit(addedUnit)
                        })
                    }
                })
            }
        })
    }


    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////


    class MyTableViewController : UITableViewController {

        weak var controller: QuickAddListItemViewController?

        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 3
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.selectionStyle = .none
            cell.backgroundColor = {
                switch indexPath.row {
                case 0: return UIColor.flatGreen
                case 1: return UIColor.yellow
                case 2: return UIColor.flatBlue
                default: fatalError("Only 3 cells supported")
                }
            }()
            return cell
        }

        override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            switch indexPath.row {
            case 0: return 400
            case 1: return 300
            case 2: return 300
            default: fatalError("Only 3 cells supported")
            }
        }

        var lockShowTop = false
        var lockHideTop = false

        override func scrollViewDidScroll(_ scrollView: UIScrollView) {
            controller?.scrollableBottomAttacher?.onBottomViewDidScroll(scrollView)
        }
    }

    fileprivate func retrieveQuickAddIngredient(item: Item, indexPath: IndexPath, onRetrieved: @escaping (QuickAddIngredientInput, Float) -> Void) {

        guard let topConstraint = topConstraint else {
            logger.e("Invalid state: no top constraint - can't show add ingredient", .ui)
            return
        }

        guard let topController = topController else {
            logger.e("Invalid state: no top controller - can't show add ingredient", .ui)
            return
        }

        guard let topParentController = topParentController else {
            logger.e("Invalid state: no topParentController - can't show add ingredient", .ui)
            return
        }

        let tableViewController = IngredientDataController()

        func showScrollableBottomAttacher() {
            guard !lockAddBottomController else { return }
            lockAddBottomController = true
            scrollableBottomAttacher = ScrollableBottomAttacher(parent: topParentController, top: topController,
                                                                bottom: tableViewController,
                                                                topViewTopConstraint: topConstraint,
                                                                onAddedSubview: { [weak self] in
                                                                    self?.delegate?.onAddedIngredientsSubviews()
                },
                                                                onExpandBottom: { [weak self] in
                                                                    // if user focused the search box
                                                                    self?.topControllersDelegate?.hideKeyboard()
                }
            )

            scrollableBottomAttacher?.hideTop(onFinish: {
                self.lockAddBottomController = false
            })
        }

        func removeScrollableBottomAttacher(_ scrollableBottomAttacher: ScrollableBottomAttacher<IngredientDataController>,
                                            onFinish: @escaping () -> Void) {
            guard !lockRemoveBottomController else { return }
            lockRemoveBottomController = true
            scrollableBottomAttacher.removeBottom(onFinish: {
                self.lockRemoveBottomController = false
                onFinish()
            })
        }

        topControllersDelegate?.hideKeyboard()

        tableViewController.productName = item.name
        tableViewController.controller = self
        tableViewController.onSubmitInputs = { [weak self] result in guard let weakSelf = self else { return }
            let inputsForDelegate = SelectIngredientDataControllerInputs(
                unitName: result.unitName,
                quantity: Float(result.whole),
                fraction: result.fraction ?? Fraction.zero
            )
            self?.delegate?.onAddIngredient(item: item, ingredientInput: inputsForDelegate)
            self?.topControllersDelegate?.restoreKeyboard()
            if let scrollableBottomAttacher = weakSelf.scrollableBottomAttacher {
                self?.scrollableBottomAttacher?.bottom.removeSubmitButton {}
                removeScrollableBottomAttacher(scrollableBottomAttacher, onFinish: { [weak self] in guard let weakSelf = self else { return }
                    // After remove bottom animation finishes, animate the collection item cell to the ingredients table view
                    if let targetNameLabelX = weakSelf.delegate?.ingredientCellAnimationNameLabelTargetX {
                        weakSelf.animateItemToCell(indexPath: indexPath, ingredient: item, targetNameLabelX: targetNameLabelX)
                    } else {
                        logger.e("No delegate! Can't animate to cell.", .ui)
                    }
                })
            } else {
                logger.e("Invalid state - submitted an item using bottom - bottom should be attached!", .ui)
            }
            self?.scrollableBottomAttacher = nil // when tap item it should display again

        }
        tableViewController.submitButtonParent = { [weak self] in
            return self?.delegate?.parentViewForAddButton()
        }
        tableViewController.onDidScroll = { [weak self] scrollView in
            self?.scrollableBottomAttacher?.onBottomViewDidScroll(scrollView)
        }

        tableViewController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        if #available(iOS 11.0, *) {
            tableViewController.tableView.contentInsetAdjustmentBehavior = .never
        }
        tableViewController.view.backgroundColor = Theme.lightGreyBackground

        if let scrollableBottomAttacher = scrollableBottomAttacher {
            removeScrollableBottomAttacher(scrollableBottomAttacher, onFinish: {
                showScrollableBottomAttacher() // TODO review memory - does the old bottom attacher release everything?
            })
        } else {
            showScrollableBottomAttacher()
        }
    }

    func onShowAddEditItemForm() {
        scrollableBottomAttacher?.bottom.removeSubmitButton(onFinish: {})
        scrollableBottomAttacher?.removeBottom(onFinish: { [weak self] in
            self?.scrollableBottomAttacher = nil
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
    
    // TODO refactor this, it was implemented without time and motivation
    // The whole workflow here has to be rewritten, probably a problem of quick add controller in general
    // We shouldn't have to cast quickAddItem to know in which (main) controller we are/which delegate method to call, the main controller shouldn't have to instantiate directly quick add items, etc. etc.
    func showAddedItem(quickAddItem: QuickAddItem, quantity: Float, note: String?) {
        
        let myDelay: Double = 0.3
        
        delay(myDelay) {[weak self] in guard let weakSelf = self else {return}
            
            // 1. Insert the item in the collection view (at this point the item/product was already added to the database, before calling showAddedOrUpdatedItem). Note that at this point, as we just were in an input form the items count is 0 (if there were items, meaning there were results for the current search, we wouldn't be in the input form, with the current logic). So we don't have to worry about pagination and "scrollToItem" doesn't has an effect - letting it here for correctness only.
            
            let newItemIndexPath = IndexPath(row: weakSelf.filteredQuickAddItems.count, section: 0)
            
            weakSelf.collectionView.performBatchUpdates({[weak self] in
                self?.filteredQuickAddItems.append(quickAddItem)
                self?.collectionView.insertItems(at: [newItemIndexPath])
            }, completion: nil)
            
            weakSelf.collectionView.scrollToItem(at: newItemIndexPath, at: .top, animated: false)
            
            
            // 2. Insert the item from the collection view into the main controller table view. This only triggers the same operation as when we tap on a quick list item. In the case of list or inventory items, this adds the item to the table view (may show a popup to select base quantity), in case of ingredients it opens the controller to select the ingredient data. Etc.
            
            if let quickAddProduct = quickAddItem as? QuickAddProduct {
                
                if let quantifiableProduct = quickAddProduct.quantifiableProduct { // list or inventory item

                    delay(myDelay) {[weak self] in
                        self?.delegate?.onAddProduct(quantifiableProduct, quantity: quantity, note: note) {[weak self] result in
                            if result.isNewItem {
                                self?.animateItemToCell(indexPath: newItemIndexPath, quantifiableProduct: quantifiableProduct, quantity: quantity)
                            }
                        }
                    }
                }
                
            } else if let quickAddDBItem = quickAddItem as? QuickAddDBItem { // ingredient
                delay(myDelay) {[weak self] in
                    self?.retrieveQuickAddIngredient(item: quickAddDBItem.item, indexPath: newItemIndexPath) {[weak self] (quantifiableProduct, quantity) in
                        self?.delegate?.onAddItem(quickAddDBItem.item)
                    }
                }
            }
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
        
//        logger.v("Called loadPossibleNextPage, isSearchLoad: \(isSearchLoad)")
        
        func setLoading(_ loading: Bool) {
            self.loadingPage = loading
//            self.tableViewFooter.hidden = !loading
        }
        
        func onItemsLoaded(_ items: [QuickAddItem]) {
            
            logger.v("onItemsLoaded: \(items.count)")
            
            if items.isEmpty {
                delegate?.onHasItems(false)

            } else {
                filteredQuickAddItems.appendAll(items)
                collectionView.reloadData()
                paginator.update(items.count)
                
                collectionView.reloadData()
                setLoading(false)
                
                delegate?.onHasItems(true)
            }
        }
        
        func loadItems() {
            // onlyEdibles: true - loadItems() is used only for recipes
            Prov.itemsProvider.items(searchText, onlyEdible: true, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                logger.v("Loaded items, current search: \(String(describing: self?.searchText)), range: \(String(describing: self?.paginator.currentPage)), sortBy: \(String(describing: self?.contentData.sortBy)), result search: \(String(describing: tuple.substring)), results: \(tuple.items.count)")
                
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
                
                logger.v("Loaded products, current search: \(String(describing: self?.searchText)), range: \(String(describing: self?.paginator.currentPage)), sortBy: \(String(describing: self?.contentData.sortBy)), result search: \(String(describing: tuple.substring)), results: \(tuple.products.count)")

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
            
            guard let list = list else {logger.e("Can't load products for list, no list set"); return}
            
            Prov.productProvider.productsWithPosibleSections(searchText, list: list, range: paginator.currentPage, sortBy: toProductSortBy(contentData.sortBy), resultHandler(onSuccess: {[weak self] tuple in
                
                // TODO bug: some times (rarely) it shows nothing after opening quickly and typing (maybe first time?). Log showed 23 results last time is happened. It shows nothing after this line, meaning that onListItems is not called, meaning tuple.substring == weakSelf.searchText is false?
                logger.v("Loaded products, current search: \(String(describing: self?.searchText)), range: \(String(describing: self?.paginator.currentPage)), sortBy: \(String(describing: self?.contentData.sortBy)), result search: \(String(describing: tuple.substring)), results: \(tuple.productsWithMaybeSections.count)")
                
                if let weakSelf = self {
                    // ensure we use only results for the string we have currently in the searchbox - the reason this check exists is that concurrent requests can cause problems,
                    // e.g. search that returns less results returns quicker, so if we type a word very fast, the results for the first letters (which are more than the ones when we add more letters) come *after* the results for more letters overriding the search results for the current text.
                    logger.v("Comparing: #\(String(describing: tuple.substring))# with #\(weakSelf.searchText)#")
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
            
//            logger.v("Trying to load: \(weakSelf.contentData.itemType) current page: \(weakSelf.paginator.currentPage), reachedEnd: \(weakSelf.paginator.reachedEnd), isSearchLoad: \(isSearchLoad)")

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

    // Returns if any child controller was showing (was closed)
    func closeChildControllers() -> Bool {
        
        var isAnyShowing: Bool = false
        
        if recipeControllerAnimator?.isShowing ?? false {
            // TODO use generics
            if
                let controller = recipeControllerAnimator?.controller,
                let addRecipeController = controller as? AddRecipeController {
                let anyChildWasShowing = addRecipeController.closeAddedNonChildren()

                // Allow to close only the unit/base popup
                // So if unit/base popup is open: first x -> close unit/base popup, second x -> close add recipe controller, third x -> close quick add
                if !anyChildWasShowing {
                    recipeControllerAnimator?.close()
                }
            } else {
                logger.e("No controller / couldn't be casted", .ui)
            }

            isAnyShowing = true
        }

        if selectQuantifiablePopup != nil {
            selectQuantifiablePopup?.hide()
            selectQuantifiablePopup = nil
            isAnyShowing = true
        }

        if let scrollableBottomAttacher = scrollableBottomAttacher {
            isAnyShowing = true
            scrollableBottomAttacher.bottom.removeSubmitButton {
            }
            scrollableBottomAttacher.removeBottom(onFinish: {
            })
            self.scrollableBottomAttacher = nil
        }

        return isAnyShowing
    }
    
    func closeRecipeController() {
        recipeControllerAnimator?.close()
    }
    
    deinit {
        logger.v("Deinit quick add item controller")
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
