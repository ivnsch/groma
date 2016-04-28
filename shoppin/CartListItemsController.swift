//
//  CartListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs


protocol CartListItemsControllerDelegate {
    func onCartSendItemsToStash(listItems: [ListItem])
}

class CartListItemsController: ListItemsController {
    
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var totalDonePriceLabel: UILabel!
    @IBOutlet weak var buyView: UIView!
    
    @IBOutlet weak var emptyListView: UIView!

    @IBOutlet weak var buyViewHeightConstraint: NSLayoutConstraint!
    
    var delegate: CartListItemsControllerDelegate?
    
    override var status: ListItemStatus {
        return .Done
    }
    
    var onUIReady: VoidFunction? // avoid crash trying to access not yet initialized ui elements

    override func viewDidLoad() {
        super.viewDidLoad()
    
        onUIReady?()
        
        topBar.setBackVisible(true)
        topBar.positionTitleLabelLeft(true, animated: false, withDot: true)
        
        buyViewHeightConstraint.constant = DimensionsManager.listItemsPricesViewHeight

        listItemsTableViewController.tableView.bottomInset = buyView.frame.height
//            + Constants.tableViewAdditionalBottomInset
    }
    
//    override var tableViewBottomInset: CGFloat {
//        return pricesView.frame.height
//    }
    
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
        return "Cart"
    }
    
    private func addAllItemsToInventory() {
        
        func onSizeLimitOk(list: List) {
            listItemsTableViewController.clearPendingSwipeItemIfAny(true) {[weak self] in
                if let weakSelf = self {
                    
                    if let controller = UIApplication.sharedApplication().delegate?.window??.rootViewController { // since we change controller on success need root controller in case we show error popup
                        Providers.listItemsProvider.buyCart(weakSelf.listItemsTableViewController.items, list: list, remote: true, controller.successHandler{result in
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
    
    private func sendAllItemToStash(onFinish: VoidFunction) {
        if let list = currentList {
            Providers.listItemsProvider.switchAllToStatus(listItemsTableViewController.items, list: list, status1: .Done, status: .Stash, remote: true) {[weak self] result in guard let weakSelf = self else {return}
                if result.success {
                    weakSelf.delegate?.onCartSendItemsToStash(weakSelf.listItemsTableViewController.items)
                    weakSelf.listItemsTableViewController.setListItems([])
                    weakSelf.onTableViewChangedQuantifiables()
                    onFinish()
                }
            }
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
    
    override func setEmptyViewVisible(visible: Bool, animated: Bool) {
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
                ConfirmationPopup.show(title: "Confirm", message: "This will add your cart items to the the inventory '\(list.inventory.name)' and the corresponding history and stats", okTitle: "Buy", cancelTitle: "Cancel", controller: self, onOk: {[weak self] in
                    self?.addAllItemsToInventory()
                }, onCancel: nil)
            } else {
                AlertPopup.show(message: "You can't move items to the inventory '\(list.inventory.name)'\nAsk a user with access to this inventory to share it with you.", controller: self)
            }
        } else {
            QL3("Warn: DoneViewController.onAddToInventoryTap: list is not set, can't add to inventory")
        }
    }
    
    override func onTopBarBackButtonTap() {
        super.onTopBarBackButtonTap()
        navigationController?.popViewControllerAnimated(true)
    }
}

