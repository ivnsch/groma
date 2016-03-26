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
    func onPageChanged(newIndex: Int)
}


class QuickAddPageController: UIViewController, SwipeViewDataSource, SwipeViewDelegate, SlidingTabsViewDelegate {

    @IBOutlet weak var slidingTabsView: SlidingTabsView!
    @IBOutlet weak var swipeView: SwipeView!
    
    var delegate: QuickAddPageControllerDelegate?
    var quickAddListItemDelegate: QuickAddListItemDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        slidingTabsView.delegate = self
        swipeView.delegate = self
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
        
        delegate?.onPageChanged(index)
        
        if quickAddListItemDelegate == nil {
            QL3("delegate is nil")
        }
        
        if index == 0 {
            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.onViewDidLoad = {
                productsController.contentData = (.Product, .Fav)
            }
            currentSwipeController = productsController
            addChildViewController(productsController)
            return productsController.view
            
        } else {
            let productsController = UIStoryboard.quickAddListItemViewController()
            productsController.delegate = quickAddListItemDelegate
            productsController.onViewDidLoad = {
                productsController.contentData = (.Group, .Fav)
            }
            currentSwipeController = productsController
            addChildViewController(productsController)
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