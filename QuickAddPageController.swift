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

protocol QuickAddPageControllerDelegate {
//    func onPagerScroll(xOffset: CGFloat)
    func onPageChanged(newIndex: Int, pageType: QuickAddItemType)
}


class QuickAddPageController: UIViewController, SwipeViewDataSource, SwipeViewDelegate, SlidingTabsViewDelegate {

    @IBOutlet weak var slidingTabsView: SlidingTabsView!
    @IBOutlet weak var swipeView: SwipeView!
    
    var delegate: QuickAddPageControllerDelegate?
    var quickAddListItemDelegate: QuickAddListItemDelegate?
    
    var itemTypeForFirstPage: QuickAddItemType = .Product // TODO improve this, no time now
    
    var list: List? // this is only used when quick add is used in list items, in order to use the section colors when available instead of category colors. TODO cleaner solution?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slidingTabsView.delegate = self
        swipeView.delegate = self
        
        swipeView.pagingEnabled = true
        swipeView.defersItemViewLoading = true
        
        slidingTabsView.onViewsReady = {[weak self] in
            self?.slidingTabsView.setSelected(0)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        slidingTabsView.onFinishLayout() // only here the bounds width is correct (maybe also in didMoveToParentViewController, which is called a bit earlier? - didn't test that one)
    }
    
    // MARK: - SwipeViewDataSource
    
    func numberOfItemsInSwipeView(swipeView: SwipeView!) -> Int {
        return 2
    }
    
    private var currentSwipeController: QuickAddListItemViewController?
    
    func swipeView(swipeView: SwipeView!, viewForItemAtIndex index: Int, reusingView view: UIView!) -> UIView! {
        
        if currentSwipeController?.parentViewController != nil {
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
                productsController.contentData = (self.itemTypeForFirstPage, .Fav)
            }
            productsController.list = list
            currentSwipeController = productsController
            addChildViewController(productsController)
            
            delegate?.onPageChanged(index, pageType: .Product)
            
            return productsController.view
            
        } else {
            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.onViewDidLoad = {
                productsController.contentData = (.Group, .Fav)
            }
            currentSwipeController = productsController
            addChildViewController(productsController)
            
            delegate?.onPageChanged(index, pageType: .Group)

            return productsController.view
        }
    }
    
    func search(text: String) {
        if let controller = currentSwipeController {
            controller.searchText = text
        } else {
            QL3("No controller/failed: \(currentSwipeController)")
        }
    }
    
    func setEmptyViewVisible(visible: Bool) {
        if let currentSwipeController = currentSwipeController {
            currentSwipeController.setEmptyViewVisible(visible)
        } else {
            QL3("setEmptyViewVisible: no controller")
        }
        
    }
    
    // MARK: - SwipeViewDelegate
    
    func swipeViewCurrentItemIndexDidChange(swipeView: SwipeView!) {
        slidingTabsView.setSelected(swipeView.currentItemIndex)
    }
    
    func swipeViewItemSize(swipeView: SwipeView!) -> CGSize {
        return swipeView.frame.size
    }
    
    func swipeViewDidScroll(swipeView: SwipeView!) {
        slidingTabsView.moveLine(swipeView.scrollOffset)
    }
    
    // MARK: - SlidingTabsViewDelegate
    
    func onSlidingViewButtonTap(index: Int, button: UIButton) {
        swipeView.scrollToPage(index, duration: 0.5)
    }
    
    // MARK: - QuickAddPageControllerDelegate
    
    func onPagerScroll(xOffset: CGFloat) {
        slidingTabsView.moveLine(xOffset)
    }
}