////
////  StashListItemsController.swift
////  shoppin
////
////  Created by ischuetz on 23/04/16.
////  Copyright © 2016 ivanschuetz. All rights reserved.
////
//
//import UIKit
//import QorumLogs
//import Providers
//
//class StashListItemsController: ListItemsController, UIGestureRecognizerDelegate {
//    
//    @IBOutlet weak var emptyListView: UIView!
//
//    override var status: ListItemStatus {
//        return .stash
//    }
//    
//    override var isPullToAddEnabled: Bool {
//        return false
//    }
//    
//    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        onUIReady?()
//        
//        topBar.setBackVisible(true)
//        topBar.positionTitleLabelLeft(true, animated: false, withDot: false)
//        
//        navigationController?.interactivePopGestureRecognizer?.delegate = self
//    }
//    
//    // Fixes random, rare freezes when coming back to todo controller. See http://stackoverflow.com/a/28919337/930450
//    // Curiously implementing gestureRecognizerShouldBegin and returning always true seemed to fix it (tested a long time after it and the bug didn't happen again - could be of course that this was just luck, though normally it appears after switching todo/cart 100 or so times and tested more than this). Letting the count check anyways, since this seems to be the proper fix.
//    // Note: I also tried implementing a UI test for this but swipe doesn't work well so need to test manually.
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        
//        guard let navigationController = navigationController else {QL3("No navigation controller"); return false}
//        
//        if navigationController.viewControllers.count > 1 {
//            return true
//        }
//        
//        // Not really a warning, just curious to see when this actually happens, see method comment.
//        QL3("Only info: Navigation controller viewControllers.count: \(navigationController.viewControllers.count)")
//        return false
//    }
//    
//    override var emptyView: UIView {
//        return emptyListView
//    }
//    
//    
//    override func onListItemsOrderChangedSection(_ tableViewListItems: [TableViewListItem]) {
//        Prov.listItemsProvider.updateListItemsOrder(tableViewListItems.map{$0.listItem}, status: status, remote: true, successHandler{result in
//        })
//    }
//    
//    override func topBarTitle(_ list: List) -> String {
//        return trans("title_stash")
//    }
//    
//    fileprivate func resetAllItems() {
//        if let list = currentList {
//            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
//                if let weakSelf = self {
//                    Prov.listItemsProvider.switchAllToStatus(weakSelf.listItemsTableViewController.items, list: list, status1: .stash, status: .todo, remote: true) {result in
//                        if result.success {
//                            weakSelf.listItemsTableViewController.setListItems([])
//                            weakSelf.close()
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    override func setDefaultLeftButtons() {
//        topBar.setBackVisible(true)
//    }
//    
//    fileprivate func close() {
//        listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
//            _ = self?.navigationController?.popViewController(animated: true)
//        }
//    }
//    
//    override func setEmptyUI(_ visible: Bool, animated: Bool) {
//        super.setEmptyUI(visible, animated: animated)
//        let hidden = !visible
//        if animated {
//            emptyListView.setHiddenAnimated(hidden)
//        } else {
//            emptyListView.isHidden = hidden
//        }
//    }
//
//    override func onTopBarBackButtonTap() {
//        super.onTopBarBackButtonTap()
//        _ = navigationController?.popViewController(animated: true)
//    }
//    
//    override func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
//        switch buttonId {
//        case .submit:
//            resetAllItems()
//        default: super.onTopBarButtonTap(buttonId)
//        }
//    }
//    
//    // MARK: - Right buttons
//    
//    override func rightButtonsDefault() -> [TopBarButtonModel] {
//        return [TopBarButtonModel(buttonId: .submit)]
//    }
//    
//    override func rightButtonsOpeningQuickAdd() -> [TopBarButtonModel] {
//        return [TopBarButtonModel(buttonId: .submit)]
//    }
//    
//    override func rightButtonsClosingQuickAdd() -> [TopBarButtonModel] {
//        return [TopBarButtonModel(buttonId: .submit)]
//    }
//    
//    override func rightButtonsClosing() -> [TopBarButtonModel] {
//        return []
//    }
//}
