//
//  TodoListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class TodoListItemsController: ListItemsController, CartListItemsControllerDelegate {

    @IBOutlet weak var pricesView: PricesView!
    @IBOutlet weak var stashView: StashView!
    
    // TODO 1 custom view for empty
    @IBOutlet weak var emptyListView: UIView!
    @IBOutlet weak var emptyListViewImg: UIImageView!
    @IBOutlet weak var emptyListViewLabel1: UILabel!
    @IBOutlet weak var emptyListViewLabel2: UILabel!
    
    override var status: ListItemStatus {
        return .Todo
    }
    
    override var tableViewBottomInset: CGFloat {
        return pricesView.frame.height
    }
    
    override var emptyView: UIView {
        return emptyListView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateStashView()
    }
    
    override func onGetListItems(listItems: [ListItem]) {
        super.onGetListItems(listItems)
        
        // timing issues - when we query list items it may be that the server items are updated which causes the handler to be called again. In these cases, the updateStashView we call in view did appear doesn't get the server update as this only calls the local db. So now each time the handler is called (which calls onGetListItems) we do the stash call again. We could here just count the stash items from listItems (which contain list items for all status) but for now we keep the changes minimal and just call updateStashView() again.
        updateStashView()
    }
    
    override func updateQuantifiables() {
        if let list = currentList {
            Providers.listItemsProvider.listItems(list, sortOrderByStatus: ListItemStatus.Todo, fetchMode: .First, successHandler {listItems in
                let (totalCartQuantity, totalCartPrice) = listItems.totalQuanityAndPrice(.Done)
//                let itemsStr = listItems.reduce("") {str, item in
//                    str + item.quantityDebugDescription + ","
//                }
//                QL2("updating price, items: \(itemsStr), total cart quantity: \(totalCartQuantity), done price: \(totalCartPrice)")
                self.pricesView.cartQuantity = totalCartQuantity
                self.pricesView.setDonePrice(totalCartPrice, animated: true)
            })
            
        } else {
            QL3("No list")
        }
    }
    
    // Update stash view after a delay. The delay is for design reason, to let user see what's hapenning otherwise not clear together with view controller transition
    // but it ALSO turned to fix bug when user adds to stash and goes back to view controller too fast - count would not be updated (count fetch is quicker than writing items to database). FIXME (not critical) don't depend on this delay to fix this bug.
    func updateStashView() {
        if let list = currentList {
            Providers.listItemsProvider.listItemCount(ListItemStatus.Stash, list: list, fetchMode: .MemOnly, successHandler {[weak self] count in
//                    if count != self?.stashView.quantity { // don't animate if there's no change
                    self?.stashView.quantity = count
                    self?.pricesView.allowOpen = count > 0
                    if count == 0 {
                        self?.pricesView.setOpen(false, animated: true)
                    }
                    self?.pricesView.stashQuantity = count
//                        self?.stashView.setOpen(count > 0)
                    
//                    }
            })
        }
    }
    
    override func onListItemsOrderChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.updateListItemsOrder(tableViewListItems.map{$0.listItem}, status: status, remote: true, successHandler{result in
        })
    }
    
    override func setEmptyViewVisible(visible: Bool, animated: Bool) {
        let hidden = !visible
        if animated {
            emptyListView.setHiddenAnimated(hidden)
        } else {
            emptyListView.hidden = hidden
        }
    }
    
    override func onTopBarTitleTap() {
        back()
    }
    
    @IBAction func onCartTap(sender: UIButton) {
        if pricesView.open {
            pricesView.setOpen(false, animated: true)
        } else {
            performSegueWithIdentifier("doneViewControllerSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? CartListItemsController {
//                doneViewController.navigationItemTextColor = titleLabel?.textColor
                doneViewController.delegate = self
                doneViewController.onUIReady = {
                    doneViewController.currentList = self.currentList
                    if let dotColor = self.topBar.dotColor {
                        doneViewController.setThemeColor(dotColor) // TODO rename theme color, we don't have themes anymore. So it's only the dot color and the other things need correct default color
                    } else {
                        QL4("Invalid state: top bar has no dot color")
                    }
                }
                self.listItemsTableViewController.clearPendingSwipeItemIfAny(true) {}
            }
            
        } else if segue.identifier == "stashSegue" {
            if let stashViewController = segue.destinationViewController as? StashListItemsController {
//                stashViewController.navigationItemTextColor = titleLabel?.textColor
                stashViewController.onUIReady = {
                    stashViewController.currentList = self.currentList
                    if let dotColor = self.topBar.dotColor {
                        stashViewController.setThemeColor(dotColor) // TODO rename theme color, we don't have themes anymore. So it's only the dot color and the other things need correct default color
                    } else {
                        QL4("Invalid state: top bar has no dot color")
                    }
                }
                self.listItemsTableViewController.clearPendingSwipeItemIfAny(true) {}

            }
            
        } else {
            print("Invalid segue: \(segue.identifier)")
        }
    }
    
    // MARK: - CartListItemsControllerDelegate
    
    func onCartSendItemsToStash(listItems: [ListItem]) {
        // Open quickly the stash view to show/remind users they can open it by swiping.
        // Note: Assumes the cart controller is closing when this is called otherwise the user will not see anything.
        if listItems.count > 0 {
            let alreadyShowedAnim: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.shownCanSwipeToOpenStash) ?? false
            if !alreadyShowedAnim {
                PreferencesManager.savePreference(PreferencesManagerKey.shownCanSwipeToOpenStash, value: true)
                delay(0.4) {[weak self] in
                    self?.pricesView.setOpen(true)
                    delay(0.8) {
                        self?.pricesView.setOpen(false)
                    }
                }
            }
        }
    }
}
