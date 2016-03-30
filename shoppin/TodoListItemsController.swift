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
    
    
    override var status: ListItemStatus {
        return .Todo
    }
    
    override var tableViewBottomInset: CGFloat {
        return pricesView.frame.height
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
                    if count != self?.stashView.quantity { // don't animate if there's no change
                        self?.stashView.quantity = count
                        self?.pricesView.setExpandedHorizontal(count == 0)
                        self?.pricesView.stashQuantity = count
                        self?.stashView.setOpen(count > 0)
                    }
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
        Providers.listItemsProvider.updateListItemsTodoOrder(tableViewListItems.map{$0.listItem}, remote: true, successHandler{result in
        })
    }
    
}
