//
//  TodoListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class TodoListItemsController: ListItemsController {

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
        
        updateStashView(withDelay: true)
    }
    
    override func updateQuantifiables() {
        if let list = currentList {
            Providers.listItemsProvider.listItems(list, sortOrderByStatus: ListItemStatus.Todo, fetchMode: .First, successHandler {listItems in
                let (totalCartQuantity, totalCartPrice) = listItems.totalQuanityAndPrice(.Done)
                self.pricesView.cartQuantity = totalCartQuantity
                self.pricesView.setDonePrice(totalCartPrice, animated: true)
            })
            
        } else {
            QL3("No list")
        }
    }
    
    // Update stash view after a delay. The delay is for design reason, to let user see what's hapenning otherwise not clear together with view controller transition
    // but it ALSO turned to fix bug when user adds to stash and goes back to view controller too fast - count would not be updated (count fetch is quicker than writing items to database). FIXME (not critical) don't depend on this delay to fix this bug.
    func updateStashView(withDelay withDelay: Bool) {
        func f() {
            if let list = currentList {
                Providers.listItemsProvider.listItemCount(ListItemStatus.Stash, list: list, fetchMode: .MemOnly, successHandler {[weak self] count in
//                    if count != self?.stashView.quantity { // don't animate if there's no change
                        self?.stashView.quantity = count
                        self?.pricesView.allowOpen = count > 0
                        if count == 0 {
                            self?.pricesView.close()
                        }
                        self?.pricesView.setExpandedHorizontal(count == 0)
                        self?.pricesView.stashQuantity = count
//                        self?.stashView.setOpen(count > 0)
                        
//                    }
                })
            }
        }
        
        if withDelay {
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_main_queue()) {
                f()
            }
        } else {
            f()
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
            pricesView.close()
        } else {
            performSegueWithIdentifier("doneViewControllerSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? CartListItemsController {
//                doneViewController.navigationItemTextColor = titleLabel?.textColor
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
            if let stashViewController = segue.destinationViewController as? StashViewController {
                stashViewController.navigationItemTextColor = titleLabel?.textColor
                listItemsTableViewController.clearPendingSwipeItemIfAny(true) {
                    stashViewController.onUIReady = {
                        stashViewController.list = self.currentList
                        stashViewController.backgroundColor = self.listItemsTableViewController.view.backgroundColor
                    }
                }
            }
            
        } else {
            print("Invalid segue: \(segue.identifier)")
        }
    }
}
