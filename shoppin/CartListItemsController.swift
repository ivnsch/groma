//
//  CartListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class CartListItemsController: ListItemsController {
    
    @IBOutlet weak var buyLabel: UILabel!
    @IBOutlet weak var totalDonePriceLabel: UILabel!
    @IBOutlet weak var buyView: UIView!
    
    @IBOutlet weak var emptyListView: UIView!

    @IBOutlet weak var buyViewHeightConstraint: NSLayoutConstraint!
    
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
                    let inventoryItemsInput = weakSelf.listItemsTableViewController.items.map{ProductWithQuantityInput(product: $0.product, quantity: $0.doneQuantity)}
                    Providers.inventoryItemsProvider.addToInventory(list.inventory, itemInputs: inventoryItemsInput, remote: true, weakSelf.successHandler{result in
                        weakSelf.sendAllItemToStash {
                            weakSelf.close()
                        }
                    })
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
            // TODO!!!!
//            Providers.listItemsProvider.switchStatus(self.listItemsTableViewController.items, list: list, status1: .Done, status: .Stash, mode: .All, remote: true) {[weak self] result in
//                if result.success {
//                    self?.listItemsTableViewController.setListItems([])
//                    self?.onTableViewChangedQuantifiables()
//                    onFinish()
//                }
//            }
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
            if InventoryAuthChecker.checkAccess(list.inventory, controller: self) {
                ConfirmationPopup.show(title: "Buy", message: "This will add your cart items to the the inventory '\(list.inventory.name)' and the corresponding history and stats", okTitle: "Continue", cancelTitle: "Cancel", controller: self, onOk: {[weak self] in
                    self?.addAllItemsToInventory()
                }, onCancel: nil)
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

