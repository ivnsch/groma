//
//  CartListItemsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 02/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers


//protocol CartListItemsControllerDelegate: class {
//    func onCartSendItemsToStash(_ listItems: [ListItem])
//}

protocol CartListItemsControllerDelegate: class {
    var priceViewHeight: CGFloat {get}
    
    func onCloseCartAfterBuy()
    func onCartUpdatedQuantifiables()
    func onCartPullToAdd()
    
    func cartCloseTopControllers()

    func showBuyPopup(list: List, onOk: @escaping () -> Void)

    var cartParentForAddButton: UIView {get}
    
    func onCartSelectListItem(listItem: ListItem, indexPath: IndexPath)
    func onCartDeepTouchListItem(listItem: ListItem, indexPath: IndexPath)
}

class CartListItemsControllerNew: SimpleListItemsController, UIGestureRecognizerDelegate {

    @IBOutlet weak var totalDonePriceButton: UIButton!
    @IBOutlet weak var buyViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: CartListItemsControllerDelegate?
    
    fileprivate var currentNotePopup: MyPopup?

    override var status: ListItemStatus {
        return .done
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buyViewHeightConstraint.constant = DimensionsManager.listItemsPricesViewHeight

        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func updateQuantifiables() {
        // The Todo controller calculates the aggregates (based on the current list, which is shared by Todo and cart) and updates all the views, including the cart
        delegate?.onCartUpdatedQuantifiables()
    }
    
    func showQuantifiables(aggregate: ListItemsCartStashAggregate) {
        totalDonePriceButton.setTitle(aggregate.cartPrice.toLocalCurrencyString(), for: .normal)
    }

    // Fixes random, rare freezes when coming back to todo controller. See http://stackoverflow.com/a/28919337/930450
    // Curiously implementing gestureRecognizerShouldBegin and returning always true seemed to fix it (tested a long time after it and the bug didn't happen again - could be of course that this was just luck, though normally it appears after switching todo/cart 100 or so times and tested more than this). Letting the count check anyways, since this seems to be the proper fix.
    // Note: I also tried implementing a UI test for this but swipe doesn't work well so need to test manually.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let navigationController = navigationController else {logger.w("No navigation controller"); return false}
        
        if navigationController.viewControllers.count > 1 {
            return true
        }
        
        // Not really a warning, just curious to see when this actually happens, see method comment.
        logger.w("Only info: Navigation controller viewControllers.count: \(navigationController.viewControllers.count)")
        return false
    }
    
    override func topBarTitle(_ list: List) -> String {
        return trans("title_cart")
    }
    
    override func onPullToAdd() {
        delegate?.onCartPullToAdd()
    }
    
    override func parentViewForAddButton() -> UIView {
        return delegate?.cartParentForAddButton ?? view
    }
    
    override func showPopup(text: String, cell: UITableViewCell, button: UIView) {
        guard let parent = parent else { logger.e("No superview"); return }
        currentNotePopup = NoteViewController.show(parent: parent, text: text, from: button)
    }
    
    fileprivate func addAllItemsToInventory() {
        
        guard let realmData = realmData else {logger.e("No realm data"); return}
        guard let list = currentList else {logger.e("No list"); return}
        
        func onSizeLimitOk(_ list: List) {
//            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
//                if let weakSelf = self {
            
                    if let controller = UIApplication.shared.delegate?.window??.rootViewController { // since we change controller on success need root controller in case we show error popup
                        
                        Prov.listItemsProvider.buyCart(list: list, realmData: realmData, controller.successHandler{[weak self] in
                            // TODO!!!!!!!!!!!!!!!! is this still necessary?
//                            self?.delegate?.onCartSendItemsToStash(weakSelf.listItemsTableViewController.items)
                            self?.tableView.reloadData() // Update table view (the cart controller continues being active after buy and should be in a valid state to process notifications from todo)
                            self?.butCartAnimation()
                            self?.delegate?.onCloseCartAfterBuy()
                        })
                    } else {
                        logger.e("No root view controller, can't handle buy cart success result")
                    }
//                }
//            }
        }
        
//        Prov.inventoryItemsProvider.countInventoryItems(list.inventory, successHandler {count in
//                if let weakSelf = self {
//                    SizeLimitChecker.checkInventoryItemsSizeLimit(count, controller: weakSelf) {
            onSizeLimitOk(list)
//                    }
//                }
//        })
    }
    
    override func afterUpdatedItem() {
        super.afterUpdatedItem()
        
        delegate?.cartCloseTopControllers()
    }
    
    fileprivate func butCartAnimation() {
        if let tabBarController = UIApplication.shared.delegate?.window??.rootViewController as? MyTabBarController {
            tabBarController.buyAnimation()
        } else {
            logger.e("Couldn't get tab bar controller, can't perform tab bar cart animation!")
        }
    }

    @IBAction func onAddToInventoryTap(_ sender: UIBarButtonItem) {

        if let list = currentList {

            // We do this in delegate (i.e. todo controller) since the price view on top doesn't belong to this controller, so the popup will show behind it
            delegate?.showBuyPopup(list: list, onOk: { [weak self] in
                self?.addAllItemsToInventory()
            })

        } else {
            logger.w("Warn: DoneViewController.onAddToInventoryTap: list is not set, can't add to inventory")
        }
    }
    
    override func clearPossibleNotePopup() {
        super.clearPossibleNotePopup()
        
        currentNotePopup?.hide()
        currentNotePopup = nil
    }
    
    override func onListItemSelected(_ tableViewListItem: ListItem, indexPath: IndexPath) {
        super.onListItemSelected(tableViewListItem, indexPath: indexPath)
        delegate?.onCartSelectListItem(listItem: tableViewListItem, indexPath: indexPath)
    }

    override func onListItemDeepTouch(tableViewListItem: ListItem, indexPath: IndexPath) {
        super.onListItemDeepTouch(tableViewListItem: tableViewListItem, indexPath: indexPath)
        delegate?.onCartDeepTouchListItem(listItem: tableViewListItem, indexPath: indexPath)
    }
}
