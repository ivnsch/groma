//
//  QuickAddPageController.swift
//  shoppin
//
//  Created by ischuetz on 26/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import SwipeView
import Providers

protocol QuickAddPageControllerDelegate: class {
//    func onPagerScroll(xOffset: CGFloat)
    func onPageChanged(_ newIndex: Int, pageType: QuickAddItemType)
    func hideKeyboard()
    func restoreKeyboard()
}


class QuickAddPageController: UIViewController, SwipeViewDataSource, SwipeViewDelegate, SlidingTabsViewDelegate, QuickAddListItemTopControllersDelegate {

    @IBOutlet weak var slidingTabsView: SlidingTabsView!
    @IBOutlet weak var swipeView: SwipeView!
    
    weak var delegate: QuickAddPageControllerDelegate?
    weak var quickAddListItemDelegate: QuickAddListItemDelegate?
    
    var itemTypeForFirstPage: QuickAddItemType = .product // TODO improve this, no time now
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?

    var addProductController: QuickAddListItemViewController?
    var addGroupController: QuickAddListItemViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slidingTabsView.delegate = self
        swipeView.delegate = self
        
        swipeView.isPagingEnabled = true
        swipeView.defersItemViewLoading = true
        
        slidingTabsView.onViewsReady = {[weak self] in
            self?.slidingTabsView.setSelected(0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        slidingTabsView.onFinishLayout() // only here the bounds width is correct (maybe also in didMoveToParentViewController, which is called a bit earlier? - didn't test that one)
    }
    
    // MARK: - SwipeViewDataSource
    
    func numberOfItems(in swipeView: SwipeView!) -> Int {
        return 2
    }
    
    fileprivate var currentSwipeController: QuickAddListItemViewController?
    
    func swipeView(_ swipeView: SwipeView!, viewForItemAt index: Int, reusing view: UIView!) -> UIView! {
        
        if quickAddListItemDelegate == nil {
            logger.w("delegate is nil")
        }
        
        logger.v("viewForItemAtIndex: index: \(index)")
        
        if index == 0 {

            // Sometimes swipeView called multiple times for same index - ensure initialize only one controller
            if let controller = addProductController { return controller.view }

            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.topControllersDelegate = self
            productsController.onViewDidLoad = {
                productsController.contentData = (self.itemTypeForFirstPage, .fav)
            }
            productsController.list = list
            currentSwipeController = productsController
            addChildViewController(productsController)
            
            addProductController = productsController
            
            return productsController.view

        } else {
            // Sometimes swipeView called multiple times for same index - ensure initialize only one controller
            if let controller = addGroupController { return controller.view }

            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.topControllersDelegate = self
            productsController.onViewDidLoad = {
                productsController.contentData = (.recipe, .fav)
            }
            currentSwipeController = productsController
            addChildViewController(productsController)

            addGroupController = productsController
            
            return productsController.view
        }
    }
    
    func search(_ text: String) {
        if let controller = currentSwipeController {
            controller.searchText = text
        } else {
            logger.w("No controller/failed: \(String(describing: currentSwipeController))")
        }
    }
    
    func setEmptyViewVisible(_ visible: Bool) {
        if let currentSwipeController = currentSwipeController {
            currentSwipeController.setEmptyViewVisible(visible)
        } else {
            logger.w("setEmptyViewVisible: no controller")
        }
        
    }
    
    func onTapNavBarCloseTap() -> Bool {
        return currentSwipeController?.onTapNavBarCloseTap() ?? false
    }
    
    // MARK: - SwipeViewDelegate
    
    func swipeViewCurrentItemIndexDidChange(_ swipeView: SwipeView!) {
        let index = swipeView.currentItemIndex
        slidingTabsView.setSelected(index)
        
        if index == 0 {
            currentSwipeController = addProductController
            delegate?.onPageChanged(index, pageType: .product)
        } else {
            currentSwipeController = addGroupController
            delegate?.onPageChanged(index, pageType: .group)
        }
    }
    
    func swipeViewItemSize(_ swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
    
    func swipeViewDidScroll(_ swipeView: SwipeView!) {
        slidingTabsView.moveLine(swipeView.scrollOffset)
    }
    
    // MARK: - SlidingTabsViewDelegate
    
    func onSlidingViewButtonTap(_ index: Int, button: UIButton) {
        swipeView.scroll(toPage: index, duration: 0.5)
    }
    
    // MARK: - QuickAddPageControllerDelegate
    
    func onPagerScroll(_ xOffset: CGFloat) {
        slidingTabsView.moveLine(xOffset)
    }
    
    // MARK: - QuickAddListItemTopControllersDelegate
    
    func hideKeyboard() {
        delegate?.hideKeyboard()
    }
    
    func restoreKeyboard() {
        delegate?.restoreKeyboard()
    }
    
    deinit {
        logger.v("Deinit quick add page controller")
    }
    
    // MARK: - 

    // Returns if any child controller was showing
    func closeChildControllers() -> Bool {
        let anyChildShowingProductController = addProductController?.closeChildControllers() ?? false
        let anyChildShowingRecipesController = addGroupController?.closeChildControllers() ?? false
        
        return anyChildShowingProductController || anyChildShowingRecipesController
    }
}
