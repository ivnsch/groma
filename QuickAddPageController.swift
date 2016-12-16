//
//  QuickAddPageController.swift
//  shoppin
//
//  Created by ischuetz on 26/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import SwipeView
import Providers

protocol QuickAddPageControllerDelegate: class {
//    func onPagerScroll(xOffset: CGFloat)
    func onPageChanged(_ newIndex: Int, pageType: QuickAddItemType)
}


class QuickAddPageController: UIViewController, SwipeViewDataSource, SwipeViewDelegate, SlidingTabsViewDelegate {

    @IBOutlet weak var slidingTabsView: SlidingTabsView!
    @IBOutlet weak var swipeView: SwipeView!
    
    weak var delegate: QuickAddPageControllerDelegate?
    weak var quickAddListItemDelegate: QuickAddListItemDelegate?
    
    var itemTypeForFirstPage: QuickAddItemType = .product // TODO improve this, no time now
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?

    fileprivate var addProductController: QuickAddListItemViewController?
    fileprivate var addGroupController: QuickAddListItemViewController?
    
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
        
        if currentSwipeController?.parent != nil {
            currentSwipeController?.removeFromParentViewController()
        }
        

        
        if quickAddListItemDelegate == nil {
            QL3("delegate is nil")
        }
        
        QL1("viewForItemAtIndex: index: \(index)")
        
        if index == 0 {
            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.onViewDidLoad = {
                productsController.contentData = (self.itemTypeForFirstPage, .fav)
            }
            productsController.list = list
            currentSwipeController = productsController
            addChildViewController(productsController)
            
            addProductController = productsController
            
            return productsController.view
            
        } else {
            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.onViewDidLoad = {
                productsController.contentData = (.group, .fav)
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
            QL3("No controller/failed: \(currentSwipeController)")
        }
    }
    
    func setEmptyViewVisible(_ visible: Bool) {
        if let currentSwipeController = currentSwipeController {
            currentSwipeController.setEmptyViewVisible(visible)
        } else {
            QL3("setEmptyViewVisible: no controller")
        }
        
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
    
    deinit {
        QL1("Deinit quick add page controller")
    }
}
