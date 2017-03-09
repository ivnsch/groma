//
//  CartListItemsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 02/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

//protocol CartListItemsControllerDelegate: class {
//    func onCartSendItemsToStash(_ listItems: [ListItem])
//}

protocol CartListItemsControllerDelegate: class {
    var priceViewHeight: CGFloat {get}
    
    func onCloseCartAfterBuy()
    func onCartUpdatedQuantifiables()
    func onCartPullToAdd()
}

class CartListItemsControllerNew: SimpleListItemsController, UIGestureRecognizerDelegate {

    @IBOutlet weak var totalDonePriceButton: UIButton!
    @IBOutlet weak var buyViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: CartListItemsControllerDelegate?
    
    fileprivate var currentNotePopup: MyAlertWrapper?
    
    override var status: ListItemStatus {
        return .done
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buyViewHeightConstraint.constant = DimensionsManager.listItemsPricesViewHeight

        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func updateQuantifiables() {
        guard let list = currentList else {QL4("No list"); return}

        Prov.listItemsProvider.calculateCartStashAggregate(list: list, successHandler {[weak self] aggregate in
            self?.totalDonePriceButton.setTitle(aggregate.cartPrice.toLocalCurrencyString(), for: .normal)
            self?.delegate?.onCartUpdatedQuantifiables()
        })
    }
    
    // Fixes random, rare freezes when coming back to todo controller. See http://stackoverflow.com/a/28919337/930450
    // Curiously implementing gestureRecognizerShouldBegin and returning always true seemed to fix it (tested a long time after it and the bug didn't happen again - could be of course that this was just luck, though normally it appears after switching todo/cart 100 or so times and tested more than this). Letting the count check anyways, since this seems to be the proper fix.
    // Note: I also tried implementing a UI test for this but swipe doesn't work well so need to test manually.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let navigationController = navigationController else {QL3("No navigation controller"); return false}
        
        if navigationController.viewControllers.count > 1 {
            return true
        }
        
        // Not really a warning, just curious to see when this actually happens, see method comment.
        QL3("Only info: Navigation controller viewControllers.count: \(navigationController.viewControllers.count)")
        return false
    }
    
    override func topBarTitle(_ list: List) -> String {
        return trans("title_cart")
    }
    
    override func onPullToAdd() {
        delegate?.onCartPullToAdd()
    }
    
    
    
    override func showPopup(text: String, cell: UITableViewCell, button: UIView) {
        guard let delegate = delegate else {QL4("No delegate - can't retrive prices view height to show popup"); return}
        
        let topOffset: CGFloat = -delegate.priceViewHeight
        let frame = view.bounds.copy(y: topOffset, height: view.bounds.height - topOffset)
        
        let noteButtonPointParentController = view.convert(CGPoint(x: button.center.x, y: button.center.y), from: cell)
        // adjust the anchor point also for topOffset
        let buttonPointWithOffset = noteButtonPointParentController.copy(y: noteButtonPointParentController.y - topOffset)
        
        currentNotePopup = AlertPopup.showCustom(message: text, controller: self, frame: frame, rootControllerStartPoint: buttonPointWithOffset)
    }
    
    fileprivate func addAllItemsToInventory() {
        
        guard let realmData = realmData else {QL4("No realm data"); return}
        guard let list = currentList else {QL4("No list"); return}
        
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
                        QL4("No root view controller, can't handle buy cart success result")
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
    
    fileprivate func butCartAnimation() {
        if let tabBarController = UIApplication.shared.delegate?.window??.rootViewController as? MyTabBarController {
            tabBarController.buyAnimation()
        } else {
            QL4("Couldn't get tab bar controller, can't perform tab bar cart animation!")
        }
    }

    @IBAction func onAddToInventoryTap(_ sender: UIBarButtonItem) {
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
    
    override func clearPossibleNotePopup() {
        super.clearPossibleNotePopup()
        
        currentNotePopup?.dismiss()
        currentNotePopup = nil
    }
}
