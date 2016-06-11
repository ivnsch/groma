//
//  CartListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs


protocol CartListItemsControllerDelegate: class {
    func onCartSendItemsToStash(listItems: [ListItem])
}

class CartListItemsController: ListItemsController, ExpandCollapseButtonDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var totalDonePriceLabel: UILabel!
    @IBOutlet weak var buyView: UIView!
    
    @IBOutlet weak var emptyListView: UIView!

    @IBOutlet weak var buyViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var buyRightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var expandCollapseButton: ExpandCollapseButton!
    
    weak var delegate: CartListItemsControllerDelegate?
    
    override var status: ListItemStatus {
        return .Done
    }
    
    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements

    override func viewDidLoad() {
        super.viewDidLoad()

        onUIReady?()
        
        topBar.setBackVisible(true)
        topBar.positionTitleLabelLeft(true, animated: false, withDot: false)
        
        buyViewHeightConstraint.constant = DimensionsManager.listItemsPricesViewHeight

        listItemsTableViewController.tableView.bottomInset = buyView.frame.height + 10
//            + Constants.tableViewAdditionalBottomInset
        
        expandCollapseButton.delegate = self
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
//    override var tableViewBottomInset: CGFloat {
//        return pricesView.frame.height
//    }
    
    
    // Fixes random, rare freezes when coming back to todo controller. See http://stackoverflow.com/a/28919337/930450
    // Curiously implementing gestureRecognizerShouldBegin and returning always true seemed to fix it (tested a long time after it and the bug didn't happen again - could be of course that this was just luck, though normally it appears after switching todo/cart 100 or so times and tested more than this). Letting the count check anyways, since this seems to be the proper fix.
    // Note: I also tried implementing a UI test for this but swipe doesn't work well so need to test manually.
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let navigationController = navigationController else {QL3("No navigation controller"); return false}
        
        if navigationController.viewControllers.count > 1 {
            return true
        }
        
        // Not really a warning, just curious to see when this actually happens, see method comment.
        QL3("Only info: Navigation controller viewControllers.count: \(navigationController.viewControllers.count)")
        return false
    }
    
    override func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        
        func toggleButtonVisibility() {
            expandCollapseButton.setHiddenAnimated(!editing)
        }
        
        if !editing { // if button has to be hidden, hide it before the price moves right
            toggleButtonVisibility()
        }
        
        // TODO consistent animation with todo - there we have cross fade, because we change the entire view, here we don't change the view. Maybe take the button out of the view and move it like here during the cross fade of the view.
        if animated {
            buyRightConstraint.constant = editing ? 60 : 0
            let delay: NSTimeInterval = editing ? 0 : 0.1 // when price moves right, wait a bit for the button to disappear
            UIView.animateWithDuration(0.3, delay: delay, options: [], animations: {[weak self] in
                self?.view.layoutIfNeeded()
                }) {finished in
                if editing {
                    toggleButtonVisibility() // if button has to be shown, show it after price made space for it
                }
            }
        }
    }
    
    override func onToggleReorderSections(isNowInReorderSections: Bool) {
        expandCollapseButton.expanded = isNowInReorderSections
    }
    
    override var emptyView: UIView {
        return emptyListView
    }
    
    override func updateQuantifiables() {
        totalDonePriceLabel.text = listItemsTableViewController.totalPrice.toLocalCurrencyString()
    }
    
    override func onListItemsOrderChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.updateListItemsOrder(tableViewListItems.map{$0.listItem}, status: status, remote: true, successHandler{result in
        })
    }

    override func topBarTitle(list: List) -> String {
        return trans("title_cart")
    }
    
    private func addAllItemsToInventory() {
        
        func onSizeLimitOk(list: List) {
            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
                if let weakSelf = self {
                    
                    if let controller = UIApplication.sharedApplication().delegate?.window??.rootViewController { // since we change controller on success need root controller in case we show error popup
                        Providers.listItemsProvider.buyCart(weakSelf.listItemsTableViewController.items, list: list, remote: true, controller.successHandler{result in
                            weakSelf.delegate?.onCartSendItemsToStash(weakSelf.listItemsTableViewController.items)
                            weakSelf.close()
                        })
                    } else {
                        QL4("No root view controller, can't handle buy cart success result")
                    }
                }
            }
        }
        
        if let list = currentList {
            Providers.inventoryItemsProvider.countInventoryItems(list.inventory, successHandler {[weak self] count in
                if let weakSelf = self {
                    SizeLimitChecker.checkInventoryItemsSizeLimit(count, controller: weakSelf) {
                        onSizeLimitOk(list)
                    }
                }
            })
        } else {
            QL3("List is not set, can't add to inventory")
        }
        
    }
    
    override func setDefaultLeftButtons() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonIds([.Edit])
    }
    
    private func close() {
        listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
            self?.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func setEmptyUI(visible: Bool, animated: Bool) {
        super.setEmptyUI(visible, animated: animated)
        let hidden = !visible
        if animated {
            emptyListView.setHiddenAnimated(hidden)
        } else {
            emptyListView.hidden = hidden
        }
    }
    
    @IBAction func onAddToInventoryTap(sender: UIBarButtonItem) {
        if let list = currentList {
            if InventoryAuthChecker.checkAccess(list.inventory) {
                ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_buy_will_add_to_history_stats", list.inventory.name), okTitle: trans("popup_button_buy"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {[weak self] in
                    self?.addAllItemsToInventory()
                }, onCancel: nil)
            } else {
                AlertPopup.show(message: trans("popup_you_cant_buy_cart", list.inventory.name), controller: self)
            }
        } else {
            QL3("Warn: DoneViewController.onAddToInventoryTap: list is not set, can't add to inventory")
        }
    }
    
    override func onTopBarBackButtonTap() {
        super.onTopBarBackButtonTap()
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - ExpandCollapseButtonDelegate
    
    func onExpandButton(expanded: Bool) {
        toggleReorderSections()
    }
}

