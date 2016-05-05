//
//  TodoListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class TodoListItemsController: ListItemsController, CartListItemsControllerDelegate, TodoListItemsEditBottomViewDelegate {

    @IBOutlet weak var pricesView: PricesView!
    @IBOutlet weak var stashView: StashView!
    
    // TODO 1 custom view for empty
    @IBOutlet weak var emptyListView: UIView!
    @IBOutlet weak var emptyListViewImg: UIImageView!
    @IBOutlet weak var emptyListViewLabel1: UILabel!
    @IBOutlet weak var emptyListViewLabel2: UILabel!
    
    private var todoListItemsEditBottomView: TodoListItemsEditBottomView?
    
    override var status: ListItemStatus {
        return .Todo
    }
    
    override var tableViewBottomInset: CGFloat {
        return pricesView.frame.height
    }
    
    override var emptyView: UIView {
        return emptyListView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        todoListItemsEditBottomView?.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateStashView()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if todoListItemsEditBottomView == nil {
            initBottomEditView()
        }
    }
    
    override func onExpand(expanding: Bool) {
        super.onExpand(expanding)
        
        if !expanding {
            pricesView.hidden = true
            stashView.hidden = true
            todoListItemsEditBottomView?.hidden = true
        }
    }
    
    private func initBottomEditView() {
        let view = NSBundle.loadView("TodoListItemsEditBottomView", owner: self) as! TodoListItemsEditBottomView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        todoListItemsEditBottomView = view
        view.hidden = true
        self.view.addSubview(view)
        view.fillSuperviewWidth()
        view.alignBottom(self.view)
        view.heightConstraint(60)
        view.setNeedsLayout()
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        view.updateConstraintsIfNeeded()
    }
    
    override func toggleTopAddController(rotateTopBarButton: Bool = true) -> Bool {
        let open = super.toggleTopAddController(rotateTopBarButton)
        
        if open { // opened quick add
            // don't show the reorder sections button during quick add is open because it stand in the way
            todoListItemsEditBottomView?.setHiddenAnimated(true)
        } else { // closed quick add
            if editing {
                // if we are in edit mode, show the reorder sections button again (we hide it when we open the top controller)
                todoListItemsEditBottomView?.setHiddenAnimated(false)
            }
        }
        return open
    }
    
    override func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        
        todoListItemsEditBottomView?.setHiddenAnimated(!editing)
    }
    
    override func onToggleReorderSections(isNowInReorderSections: Bool) {
        self.todoListItemsEditBottomView?.expandCollapseButtonExpanded = isNowInReorderSections
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

                let stashQuantity = listItems.totalQuanityAndPrice(.Stash).quantity
                
                self.pricesView.quantities = (cart: totalCartQuantity, stash: stashQuantity)
                
//                QL2("updating price, items: \(itemsStr), total cart quantity: \(totalCartQuantity), done price: \(totalCartPrice), stash quantity: \(stashQuantity)")
                
                self.pricesView.setDonePrice(totalCartPrice, animated: true)
                self.stashView.updateOpenStateForQuantities(totalCartQuantity, stashQuantity: stashQuantity)
                
                
                self.todoListItemsEditBottomView?.setTotalPrice(listItems.totalPriceTodoAndCart)
            })
            
        } else {
            QL3("No list")
        }
    }
    
    func updateStashView() {
        if let list = currentList {
            Providers.listItemsProvider.listItemCount(ListItemStatus.Stash, list: list, fetchMode: .MemOnly, successHandler {[weak self] count in guard let weakSelf = self else {return}
//                    if count != self?.stashView.quantity { // don't animate if there's no change
                    weakSelf.stashView.quantity = count
                    weakSelf.pricesView.allowOpen = count > 0
                    if count == 0 {
                        weakSelf.pricesView.setOpen(false, animated: true)
                    }
                    weakSelf.pricesView.quantities = (cart: weakSelf.pricesView.quantities.cart, stash: count)

//                    QL2("Set stash quantity: \(count), cart quantity: \(weakSelf.pricesView.quantities.cart)")
                
                    weakSelf.stashView.updateOpenStateForQuantities(weakSelf.pricesView.quantities.cart, stashQuantity: count)
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
    
    // MARK: - TodoListItemsEditBottomViewDelegate
    
    func onExpandSections(expand: Bool) {
        toggleReorderSections()
    }
}
