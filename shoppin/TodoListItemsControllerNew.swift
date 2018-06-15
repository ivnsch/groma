//
//  TodoListItemsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 31/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

import Providers



class TodoListItemsControllerNew: ListItemsControllerNew, CartListItemsControllerDelegate, TodoListItemsEditBottomViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var pricesView: PricesView!
    @IBOutlet weak var stashView: StashView!
    @IBOutlet weak var pricesViewBottomConstraint: NSLayoutConstraint!

    fileprivate weak var todoListItemsEditBottomView: TodoListItemsEditBottomView?
    
    fileprivate var cartController: CartListItemsControllerNew?

    private var pricesViewBottomConstraintConstantInExpandedState: CGFloat? // FIXME

    override var status: ListItemStatus {
        return .todo
    }

    override var statusForUpdate: ListItemStatus {
        return isCartOpen ? .done : .todo
    }

    override var realmData: RealmData? {
        didSet {
            if let tokens = realmData?.tokens {
                cartController?.additionalAddQuickAddItemToListTokens = tokens
            }
        }
    }

    fileprivate var isCartOpen: Bool {
        return pricesView.expandedNew
    }
    
    override var isEmpty: Bool {
        return super.isEmpty && !isCartOpen // if cart is open it means there must be at least one item (when cart is empty it closes automatically)
    }
    
    override var tableViewBottomInset: CGFloat {
        //        return pricesView.frame.height // can be open or closed, for now just return fixed height of prices view - when it's closed we have a bigger inset
        return DimensionsManager.listItemsPricesViewHeight
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        todoListItemsEditBottomView?.delegate = self
        
        addPinch()
    }
    
    fileprivate func addPinch() {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
        pinchRecognizer.delegate = self
        view.addGestureRecognizer(pinchRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStashView()
    }
    
    fileprivate func initPriceCart() {
        pricesView.todoController = self
        pricesView.bottomConstraint = pricesViewBottomConstraint
        // For now 70 hardcoded because pricesView hasn't animated in yet
        // NOTE this calculation works only in viewDidAppear, in viewDidLoad view includes tab bar height (but tab controller isn't set) and willAppear has a very small view height, probably because of the expand animation
        pricesView.bottomConstraintMax = view.height - topBar.height - 70 /*pricesView.height*/
        addCartController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if todoListItemsEditBottomView == nil {
            initBottomEditView()
        }
        
        if cartController == nil {
            initPriceCart()
        }
    }
    
    override func onExpand(_ expanding: Bool) {
        super.onExpand(expanding)
        
        if !expanding {
            pricesView.isHidden = true
            stashView.isHidden = true
            todoListItemsEditBottomView?.isHidden = true
        }
    }
    
    fileprivate func initBottomEditView() {
        let view = Bundle.loadView("TodoListItemsEditBottomView", owner: self) as! TodoListItemsEditBottomView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        todoListItemsEditBottomView = view
        view.isHidden = true
        self.view.addSubview(view)
        view.fillSuperviewWidth()
        _ = view.alignBottom(self.view)
        _ = view.heightConstraint(60) // must be same as price view
        view.setNeedsLayout()
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        view.updateConstraintsIfNeeded()
        
        updateTodoEditBottomViewVisibility()
    }
    
    fileprivate func updateTodoEditBottomViewVisibility() {
        let show = !isEmpty && isEditing
        todoListItemsEditBottomView?.isHidden = !show
    }
    
    override func toggleTopAddController(_ rotateTopBarButton: Bool = true) -> Bool {
        let open = super.toggleTopAddController(rotateTopBarButton)
        
        if open { // opened quick add
            // don't show the reorder sections button during quick add is open because it stand in the way
            todoListItemsEditBottomView?.setHiddenAnimated(true)
        } else { // closed quick add
            if isEditing {
                // if we are in edit mode, show the reorder sections button again (we hide it when we open the top controller)
                todoListItemsEditBottomView?.setHiddenAnimated(false)
            }
        }
        return open
    }
    
    override func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        
        todoListItemsEditBottomView?.setHiddenAnimated(!editing)
        
        cartController?.setEditing(editing, animated: animated)
    }

    override func editingLeftButtonids() -> [ListTopBarViewButtonId] {
        return [.edit, .expandSections]
    }
    
    override func onToggleReorderSections(_ isNowInReorderSections: Bool) {
//        self.todoListItemsEditBottomView?.expandCollapseButtonExpanded = isNowInReorderSections
    }
    
//    override func onGetListItems(_ listItems: [ListItem]) {
//        super.onGetListItems(listItems)
//        
//        // timing issues - when we query list items it may be that the server items are updated which causes the handler to be called again. In these cases, the updateStashView we call in view did appear doesn't get the server update as this only calls the local db. So now each time the handler is called (which calls onGetListItems) we do the stash call again. We could here just count the stash items from listItems (which contain list items for all status) but for now we keep the changes minimal and just call updateStashView() again.
//        updateStashView()
//    }
    
    override func updateQuantifiables() {
        guard let list = currentList else {logger.e("No list"); return}
        
        Prov.listItemsProvider.calculateCartStashAggregate(list: list, successHandler {[weak self] aggregate in guard let weakSelf = self else {return}
            
            let stashQuantity = aggregate.stashQuantity
            
            weakSelf.pricesView.setQuantities(cart: aggregate.cartQuantity, stash: stashQuantity, closeIfZero: !weakSelf.isCartOpen) // when the cart is expanded and the quantity becomes zero we don't want to hide the prices view (since it's on the upper part of the controller).
            
            // If we are currently showing the cart and it's empty (i.e. was just emptied), close the cart
            if aggregate.cartQuantity == 0 && weakSelf.isCartOpen {
                delay(0.2) {
                    weakSelf.pricesView.setExpanded(expanded: false) {
                        weakSelf.pricesView.setQuantities(cart: aggregate.cartQuantity, stash: stashQuantity, closeIfZero: true) // now that we are back in todo, close the cart bottom view
                        weakSelf.updateTodoEditBottomViewVisibility()
                    }
                }
            }
            
            weakSelf.pricesView.setDonePrice(aggregate.cartPrice, animated: true)
            weakSelf.stashView.updateOpenStateForQuantities(aggregate.cartQuantity, stashQuantity: stashQuantity)
            
            weakSelf.todoListItemsEditBottomView?.setTotalPrice(aggregate.todoPrice)
            
            weakSelf.cartController?.showQuantifiables(aggregate: aggregate)
        })
        
//        if let list = currentList {
//            Prov.listItemsProvider.listItems(list, sortOrderByStatus: ListItemStatus.todo, fetchMode: .first, successHandler {listItems in
//                let (totalCartQuantity, totalCartPrice) = listItems.totalQuanityAndPrice(.done)
//                //                let itemsStr = listItems.reduce("") {str, item in
//                //                    str + item.quantityDebugDescription + ","
//                //                }
//                
//                let stashQuantity = listItems.totalQuanityAndPrice(.stash).quantity
//                
//                self.pricesView.quantities = (cart: totalCartQuantity, stash: stashQuantity)
//                
//                //                logger.d("updating price, items: \(itemsStr), total cart quantity: \(totalCartQuantity), done price: \(totalCartPrice), stash quantity: \(stashQuantity)")
//                
//                self.pricesView.setDonePrice(totalCartPrice, animated: true)
//                self.stashView.updateOpenStateForQuantities(totalCartQuantity, stashQuantity: stashQuantity)
//                
//                
//                self.todoListItemsEditBottomView?.setTotalPrice(listItems.totalPriceTodoAndCart)
//            })
//            
//        } else {
//            logger.w("No list")
//        }
    }
    
    override func onTableViewChangedQuantifiables() {
        super.onTableViewChangedQuantifiables()
        updateTodoEditBottomViewVisibility()
    }
    
    func updateStashView() {
        if let list = currentList {
            Prov.listItemsProvider.listItemCount(.stash, list: list, fetchMode: .memOnly, successHandler {[weak self] count in guard let weakSelf = self else {return}
                //                    if count != self?.stashView.quantity { // don't animate if there's no change
                // TODO maybe we should show total quantity instead of items (rows) quantity
//                weakSelf.stashView.quantity = Float(count)
//                weakSelf.pricesView.allowOpen = count > 0
//                if count == 0 {
//                    weakSelf.pricesView.setOpen(false, animated: true)
//                }
                weakSelf.pricesView.setQuantities(cart: weakSelf.pricesView.cartQuantity, stash: Float(count))
                
                //                    logger.d("Set stash quantity: \(count), cart quantity: \(weakSelf.pricesView.quantities.cart)")
                
//                weakSelf.stashView.updateOpenStateForQuantities(weakSelf.pricesView.quantities.cart, stashQuantity: Float(count))
            })
        }
    }
    
    // TODO!!!!!!!!!!!!!!!!
    //override func onListItemsOrderChangedSection(_ tableViewListItems: [TableViewListItem]) {
    //    Prov.listItemsProvider.updateListItemsOrder(tableViewListItems.map{$0.listItem}, status: status, remote: true, successHandler{result in
    //    })
    //}
    
    override func onTopBarTitleTap() {
        back()
    }

    override func clearPossibleNotePopup() {
        super.clearPossibleNotePopup()
        cartController?.clearPossibleNotePopup()
    }
    
    @IBAction func onCartTap(_ sender: UIButton) {
        pricesView.toggleExpanded(todoController: self)
        
        setDefaultLeftButtons() // update edit button visibility in case there's an empty state difference between todo and cart

    }
    
    func setCartExpanded(expanded: Bool, onFinishAnim: (() -> Void)?) {
        pricesView.setExpanded(expanded: expanded, onFinishAnim: onFinishAnim)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "stashSegue" {
//            if let stashViewController = segue.destination as? StashListItemsController {
//                //                stashViewController.navigationItemTextColor = titleLabel?.textColor
//                stashViewController.onUIReady = {[weak stashViewController] in
//                    stashViewController?.currentList = self.currentList
//                }
//                stashViewController.onViewWillAppear = {[weak self, weak stashViewController] in guard let weakSelf = self else {return}
//                    if let dotColor = weakSelf.topBar.dotColor {
//                        stashViewController?.topBar.showDot()
//                        stashViewController?.setThemeColor(dotColor) // TODO rename theme color, we don't have themes anymore. So it's only the dot color and the other things need correct default color
//                    } else {
//                        logger.e("Invalid state: top bar has no dot color")
//                    }
//                }
//                // TODO!!!!!!!!!!!!!!!!
//                //self.listItemsTableViewController.clearPendingSwipeItemIfAny(true) {}
//                
//            }
//            
//        } else {
//            print("Invalid segue: \(segue.identifier)")
//        }
//    }
    
    // MARK: - CartListItemsControllerDelegate
    
    var priceViewHeight: CGFloat {
        return pricesView.height
    }
    
    func onCloseCartAfterBuy() {
        topQuickAddControllerManager = updateTopQuickAddControllerManager(tableView: tableView)
        pricesView.closeFull() {[weak self] in
            // trigger hiding of prices view by setting quantity to 0
            // we just bought so we know that cart quantity is 0 - no need to re-fetch anything here. We don't use stash for now, so we just pass stash 0.
            self?.pricesView.setQuantities(cart: 0, stash: 0)
        }
    }

    func onCartUpdatedQuantifiables() {
        updateQuantifiables()
        updateTodoEditBottomViewVisibility()
    }
    
    func onCartPullToAdd() {
        beforeToggleTopAddController(willExpand: true)
        super.onPullToAdd()
    }
    
//    // for now not used. This functionality needs to be reviewed anyway
//    func onCartSendItemsToStash(_ listItems: [ListItem]) {
//        // Open quickly the stash view to show/remind users they can open it by swiping.
//        // Note: Assumes the cart controller is closing when this is called otherwise the user will not see anything.
//        if listItems.count > 0 {
//            let alreadyShowedAnim: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.shownCanSwipeToOpenStash) ?? false
//            if !alreadyShowedAnim {
//                PreferencesManager.savePreference(PreferencesManagerKey.shownCanSwipeToOpenStash, value: true)
//                delay(0.4) {[weak self] in
//                    self?.pricesView.setOpen(true)
//                    delay(0.8) {
//                        self?.pricesView.setOpen(false)
//                    }
//                }
//            }
//        }
//    }
    
    func onCartSelectListItem(listItem: ListItem, indexPath: IndexPath) {
        // We just open the top controller - when the data is submitted it will call onSubmitAddEditItem on this controller, which forwards the result to the cart (if it's open, which is assumed to be still the case at that point since the UI doesn't allow to close the cart controller while the add/edit controller is open)
        onListItemSelected(listItem, indexPath: indexPath)
    }
    
    var cartParentForAddButton: UIView {
        return view
    }
    
    func cartCloseTopControllers() {
        closeTopControllers()
    }

    func showBuyPopup(list: List, onOk: @escaping () -> Void) {
        if InventoryAuthChecker.checkAccess(list.inventory) {
            let message = trans("popup_buy_will_add_to_history_stats", list.inventory.name)
            // Show inventory name in blue
            let ranges = message.range(list.inventory.name).map { [$0] } ?? {
                logger.e("Invalid state inventory name not contained in: \(message)", .ui)
                return []
            } ()

            MyPopupHelper.showPopup(parent: self, type: .confirmCartBuy, message: trans("popup_buy_will_add_to_history_stats", list.inventory.name), highlightRanges: ranges, centerYOffset: 20, onOk: {
                delay(0.3) { // give a little time for dismiss animation to finish (there's an animation to add the items to inventory/history/stats after it, so we don't want these animations to overlap)
                    onOk()
                }
            })
        } else {
            let message = trans("popup_you_cant_buy_cart", list.inventory.name)
            let ranges = message.range(list.inventory.name).map { [$0] } ?? {
                logger.e("Invalid state inventory name not contained in: \(message)", .ui)
                return []
            } ()

            MyPopupHelper.showPopup(parent: self, type: .error, message: message, highlightRanges: ranges, centerYOffset: 20)
        }
    }
    
    // MARK: - TodoListItemsEditBottomViewDelegate
    
    func onExpandSections(_ expand: Bool) {
        toggleReorderSections()
    }
    
    fileprivate func addCartController() {

        let cartController = UIStoryboard.cartViewControllerNew()
        self.cartController = cartController

        if let tokens = realmData?.tokens {
            cartController.additionalAddQuickAddItemToListTokens = tokens
        }
        
        cartController.onViewWillAppear = {[weak self, weak cartController] in guard let weakSelf = self else {return}
            cartController?.currentList = weakSelf.currentList
        }
        
        cartController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewControllerAndView(cartController)
        
        cartController.delegate = self
        
        _ = cartController.view.positionBelowView(pricesView)
        _ = cartController.view.heightConstraint(view.height - topBar.height - cartController.buyViewHeightConstraint.constant)
        _ = cartController.view.alignLeft(view)
        _ = cartController.view.alignRight(view)
    }

    // Re-initialized top controller referencing todo / cart table view (TODO re-use initializer of top class instead - this is implemented in a rush)
    fileprivate func updateTopQuickAddControllerManager(tableView: UITableView) -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, animateTableViewInset: false, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            if let weakSelf = self {
                controller.itemType = weakSelf.quickAddItemType
            }
            controller.list = self?.list
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    // TODO optimize this, re-initializing top controller each time may not be best performance
    override func beforeToggleTopAddController(willExpand: Bool) {
        if willExpand {
            if isCartOpen {
                if let cartController = cartController {
                    topQuickAddControllerManager = updateTopQuickAddControllerManager(tableView: cartController.tableView)
                } else {
                    logger.e("Illegal state: prices view expanded but no cart controller")
                }
            } else {
                topQuickAddControllerManager = updateTopQuickAddControllerManager(tableView: tableView)
            }
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    
    override func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        
        if isCartOpen {
            
            // Implemented in a rush - hold the max constraint value here - if we don't store it, it doesn't work correctly (heights change during the animation) and in viewDidLoad there's a diffent height, don't have time to check why.
            if pricesViewBottomConstraintConstantInExpandedState == nil {
                pricesViewBottomConstraintConstantInExpandedState = self.view.height - topBar.height - pricesView.height
            }
//            let maxBottomConstraint: CGFloat = 553
            
            let pricesViewMinimizedHeight: CGFloat = 30
            
            let bottomConstraintHeightDelta = pricesView.originalHeight - pricesViewMinimizedHeight
            
            pricesViewBottomConstraint.constant = (pricesViewBottomConstraintConstantInExpandedState ?? 0) - view.frame.height + (expand ? bottomConstraintHeightDelta : 0)
            pricesView.heightConstraint.constant = expand ? pricesViewMinimizedHeight : pricesView.originalHeight

            pricesView.cartImgCenterConstraint.constant = 0

            self.view.layoutIfNeeded()
            
        } else {
            tableViewTopConstraint?.constant = view.frame.height < 0.1 ? 0 : view.frame.height
            reorderSectionsTableViewTopConstraint?.constant = view.frame.height < 0.1 ? 0 : view.frame.height

            pricesView.cartImgCenterConstraint.constant = 5 // NOTE has to match initial offset in storyboard (ListItemsControllers.storyboard)
        }
    }
    
    
    // MARK: - QuickAddDelegate
    // IMPORTANT: Make sure all the QuickAddDelegate methods are overriden here, since the cart has to consume everything while it's open. With more time we can think about a better solution for this.

    override func getRealmDataForAddEditItem() -> RealmData? {
        if isCartOpen {
            return cartController?.realmData
        } else {
            return super.getRealmDataForAddEditItem()
        }
    }

    override func onAddProduct(_ product: QuantifiableProduct, quantity: Float, note: String?, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        if isCartOpen {
            cartController?.onAddProduct(product, quantity: quantity, note: note, onAddToProvider: onAddToProvider)
        } else {
            super.onAddProduct(product, quantity: quantity, note: note, onAddToProvider: onAddToProvider)
        }
    }
    
    override func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        if isCartOpen {
            cartController?.onAddGroup(group, onFinish: onFinish)
        } else {
            super.onAddGroup(group, onFinish: onFinish)
        }
    }
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], recipeData: RecipeData, quickAddController: QuickAddViewController) {
        if isCartOpen {
            cartController?.onAddRecipe(ingredientModels: ingredientModels, recipeData: recipeData, quickAddController: quickAddController)
        } else {
            super.onAddRecipe(ingredientModels: ingredientModels, recipeData: recipeData, quickAddController: quickAddController)
        }
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        if isCartOpen {
            cartController?.getAlreadyHaveText(ingredient: ingredient, handler)
        } else {
            super.getAlreadyHaveText(ingredient: ingredient, handler)
        }
    }

    
    override func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        if isCartOpen {
            cartController?.onSubmitAddEditItem(input, editingItem: editingItem)
        } else {
            super.onSubmitAddEditItem(input, editingItem: editingItem)
        }
    }
    
    override func onCloseQuickAddTap() {
        if isCartOpen {
            cartController?.onCloseQuickAddTap()
        } else {
            super.onCloseQuickAddTap()
        }
    }
    
    override func onQuickListOpen() {
        if isCartOpen {
            cartController?.onQuickListOpen()
        } else {
            super.onQuickListOpen()
        }
    }
    
    override func onAddProductOpen() {
        if isCartOpen {
            cartController?.onAddProductOpen()
        } else {
            super.onAddProductOpen()
        }
    }
    
    override func onAddGroupOpen() {
        if isCartOpen {
            cartController?.onAddGroupOpen()
        } else {
            super.onAddGroupOpen()
        }
    }
    
    override func onAddGroupItemsOpen() {
        if isCartOpen {
            cartController?.onAddGroupItemsOpen()
        } else {
            super.onAddGroupItemsOpen()
        }
    }
    
    override func parentViewForAddButton() -> UIView {
        var view: UIView?
        if isCartOpen {
            view = cartController?.parentViewForAddButton()
        } else {
            view = super.parentViewForAddButton()
        }
        return view ?? {
            logger.e("Invalid state: price view expanded but no cart controller - returning a dummy view")
            return UIView()
        }()
    }
    
    override func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        if isCartOpen {
            cartController?.addEditSectionOrCategoryColor(name, handler: handler)
        } else {
            super.addEditSectionOrCategoryColor(name, handler: handler)
        }
    }
    
    override func onRemovedSectionCategoryName(_ name: String) {
        if isCartOpen {
            cartController?.onRemovedSectionCategoryName(name)
        } else {
            super.onRemovedSectionCategoryName(name)
        }
    }
    
    override func onRemovedBrand(_ name: String) {
        if isCartOpen {
            cartController?.onRemovedBrand(name)
        } else {
            super.onRemovedBrand(name)
        }
    }
    
    
    
    fileprivate var zoomStartYDistance: CGFloat = 0
    fileprivate var consumedPinch = false

    @objc func onPinch(_ sender: UIPinchGestureRecognizer) {
        
        switch sender.state {
            
        case .began:
            zoomStartYDistance = abs(sender.location(in: view).y - sender.location(ofTouch: 1, in: view).y)
            consumedPinch = false
            fallthrough
            
        case .changed:
            
            guard sender.numberOfTouches > 1 else {return}
            let x = abs(sender.location(in: view).x - sender.location(ofTouch: 1, in: view).x)
            let y = abs(sender.location(in: view).y - sender.location(ofTouch: 1, in: view).y)
            
            let isVertical = y > x
            
            if isVertical {
                let delta = y - zoomStartYDistance
                if abs(delta) > 30 {
                    if delta < 0 && !consumedPinch { // negative - contract
                        consumedPinch = true
                        setReorderSections(true)

                    } else if !consumedPinch { // positive - expand
                        consumedPinch = true
                        setReorderSections(false)
                    }
                }
            }
            
        case .ended: fallthrough
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .possible: break
        }
        
        sender.scale = 1.0
    }
    
}
