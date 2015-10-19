//
//  ViewController.swift
//  shoppin
//
//  Created by ischuetz on 06.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import SwiftValidator

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, AddEditListItemControllerDelegate, AddItemViewDelegate, UIViewControllerTransitioningDelegate, ListItemGroupsViewControllerDelegate
//    , UIBarPositioningDelegate
{
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    private var addEditItemController: AddEditListItemController?
    // TODO put next vars in a struct
    private var updatingListItem: ListItem?
    private var updatingSelectedCell: UITableViewCell?
    
    private var listItemsTableViewController: ListItemsTableViewController!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    private var gestureRecognizer: UIGestureRecognizer!
    
    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var stashLabel: UILabel!
    @IBOutlet weak var stashView: UIView!
    @IBOutlet weak var pricesViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var listNameView: UILabel!

    @IBOutlet weak var addItemView: AddItemView!
    @IBOutlet weak var addButtonContainerBottomConstraint: NSLayoutConstraint!
    
    private let transition = BlurBubbleTransition()

    var currentList: List? {
        didSet {
            if let list = self.currentList {
                self.navigationItem.title = list.name
                self.initWithList(list)
            }
        }
    }
    var onViewWillAppear: VoidFunction?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()

        addItemView.delegate = self
        addItemView.bottomConstraint = addButtonContainerBottomConstraint
        
        setEditing(false, animated: false)
        updatePrices()
        FrozenEffect.apply(self.pricesView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        onViewWillAppear?()
        
        updateStashView(withDelay: true)
    }
    
    // Update stash view after a delay. The delay is for design reason, to let user see what's hapenning otherwise not clear together with view controller transition
    // but it ALSO turned to fix bug when user adds to stash and goes back to view controller too fast - count would not be updated (count fetch is quicker than writing items to database). FIXME (not critical) don't depend on this delay to fix this bug.
    func updateStashView(withDelay withDelay: Bool) {
        func f() {
            if let list = currentList {
                Providers.listItemsProvider.listItemCount(ListItemStatus.Stash, list: list, successHandler {[weak self] count in
                    let countText = String(count)
                    if countText != self?.stashLabel.text { // don't animate if there's no change
                        self?.stashLabel.text = countText
                        self?.setStashViewOpen(count > 0, withDelay: true)
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
    
    // TODO constraint constant to show exact width of stash view (depends on label length)
    private func setStashViewOpen(open: Bool, withDelay: Bool) {
        if open {
            stashView.alpha = 0
            pricesViewWidthConstraint.constant = -100
            
        } else {
            stashView.alpha = 1
            pricesViewWidthConstraint.constant = 0
        }
        UIView.animateWithDuration(0.5) {[weak self] in
            self?.view.layoutIfNeeded()
            self?.stashView.alpha = self?.stashView.alpha == 0 ? 1 : 0
        }
    }
    
    private func initWithList(list: List) {
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{listItems in
            self.listItemsTableViewController.setListItems(listItems.filter{$0.status == .Todo})
        })
    }
    
    // MARK: - AddEditListItemControllerDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String, note: String?) {
        submitInputs(name, price: priceText, quantity: quantityText, sectionName: sectionName, note: note) {
            addEditItemController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String, note: String?) {
        submitInputs(name, price: priceText, quantity: quantityText, sectionName: sectionName, note: note) {[weak self] in
            self?.addEditItemController?.clearInputs()
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, sectionName: String, note: String?) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName, note: note) {
            self.updateItem(self.updatingListItem!, listItemInput: listItemInput) {[weak self] in
                self?.view.endEditing(true)
                self?.addEditItemController?.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.listItemsProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.listItemsProvider.sectionSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    func onCancelTap() {
        addEditItemController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, sectionName: String, note: String?, successHandler: VoidFunction? = nil) {
        if !name.isEmpty {
            if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, sectionName: sectionName, note: note) {
                self.addItem(listItemInput, successHandler: successHandler)
                // self.view.endEditing(true)
            }
        }
    }
    
    // MARK:
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, sectionName: String, note: String?) -> ListItemInput? {
        //TODO?
        //        if !price {
        //            price = 0
        //        }
        //        if !quantity {
        //            quantity = 0
        //        }
        
        if let price = priceText.floatValue {
            let quantity = Int(quantityText) ?? 1
            let sectionName = sectionName ?? defaultSectionIdentifier
            
            return ListItemInput(name: name, quantity: quantity, price: price, section: sectionName, note: note)
            
        } else {
            print("TODO validation in processListItemInputs")
            return nil
        }
    }
    
    @IBAction func onEditTap(sender: AnyObject) {
        let editing = !self.listItemsTableViewController.editing
        
        self.setEditing(editing, animated: true)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        addItemView.setVisible(editing, animated: animated)

        listItemsTableViewController.setEditing(editing, animated: animated)
//        self.gestureRecognizer.enabled = !editing //don't block tap on delete button
        gestureRecognizer.enabled = false //don't block tap on delete button

        let navbarHeight = navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)

        let topInset = navbarHeight + statusBarHeight + CGRectGetHeight(pricesView.frame)
        
        // TODO this makes a very big bottom inset why?
//            let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + addButtonContainer.frame.height
        let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + 20
    
        listItemsTableViewController.tableViewInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
        listItemsTableViewController.tableViewTopOffset = -listItemsTableViewController.tableViewInset.top
        
        if editing {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
//    func itemsChanged() {
//        self.initList()
//    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        
        self.gestureRecognizer = UITapGestureRecognizer(target: self, action: "clearThings")
        self.listItemsTableViewController.view.addGestureRecognizer(gestureRecognizer)
        self.listItemsTableViewController.scrollViewDelegate = self
        self.listItemsTableViewController.listItemsTableViewDelegate = self
        self.listItemsTableViewController.listItemsEditTableViewDelegate = self
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearThings()
    }
    
    func clearThings() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny()
    }
    
    func onListItemClear(tableViewListItem: TableViewListItem, onFinish: VoidFunction) {
        tableViewListItem.listItem.status = .Done
        
        if let list = self.currentList {
            
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status: .Done) {[weak self] result in
                if result.success {
                    self!.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
                    self!.updatePrices(.MemOnly)
                }
                onFinish()
            }
        } else {
            onFinish()
        }
    }

//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    private func getTableViewInset() -> CGFloat {
        let navbarHeight = self.navigationController!.navigationBar.frame.height
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        return navbarHeight + statusBarHeight
    }

    func loadItems(handler: Try<[String]> -> ()) {
        Providers.listItemsProvider.products(successHandler{products in
            let names = products.map{$0.name}
            handler(Try(names))
        })
    }
    
    func onListItemsChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.update(tableViewListItems.map{$0.listItem}, successHandler{result in
        })
    }
    
    /**
    
    */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {

        func calculatePrice(listItems:[ListItem]) -> Float {
            return listItems.reduce(0, combine: {(price:Float, listItem:ListItem) -> Float in
                return price + (listItem.product.price * Float(listItem.quantity))
            })
        }
        
        if let currentList = self.currentList {
            Providers.listItemsProvider.listItems(currentList, fetchMode: listItemsFetchMode, successHandler{listItems in
                    
                //        let allListItems = self.tableViewSections.map {
                //            $0.listItems
                //        }.reduce([], combine: +)
                
                let totalPrice:Float = calculatePrice(listItems)
                
                let doneListItems = listItems.filter{$0.status == .Done}
                let donePrice:Float = calculatePrice(doneListItems)
                
                self.pricesView.totalPrice = totalPrice
                self.pricesView.donePrice = donePrice
            })
        }
    }

    private func addItem(listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {

        if let currentList = self.currentList {
            
            self.progressVisible(true)
            
            Providers.listItemsProvider.add(listItemInput, list: currentList, order: nil, possibleNewSectionOrder: self.listItemsTableViewController.sections.count, successHandler {savedListItem in
                // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
                self.listItemsTableViewController.updateOrAddListItem(savedListItem, increment: true)
                self.updatePrices(.MemOnly)
                
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }

    }
    
    func updateItem(listItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            if let updatingListItem = self.updatingListItem {
                
                let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price) // possible product update
                let section = Section(uuid: updatingListItem.section.uuid, name: listItemInput.section, order: listItem.section.order) // possible section update
                
                let listItem = ListItem(uuid: updatingListItem.uuid, status: updatingListItem.status, quantity: listItemInput.quantity, product: product, section: section, list: currentList, order: updatingListItem.order, note: listItemInput.note)
                
                Providers.listItemsProvider.update([listItem], successHandler {
                    self.listItemsTableViewController.updateListItem(listItem)
                    self.updatePrices(.MemOnly)
                    
                    handler?()
                })
                
            } else {
                print("Error: Invalid state: trying to update list item without updatingListItem")
            }

        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }

    }
    

    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        if self.editing {
            updatingListItem = tableViewListItem.listItem
            updatingSelectedCell = listItemsTableViewController.tableView.cellForRowAtIndexPath(indexPath)
            
            performSegueWithIdentifier("showAddIemSegue", sender: self)
            
        } else {
            listItemsTableViewController.markOpen(true, indexPath: indexPath)
        }
    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        Providers.listItemsProvider.remove(tableViewListItem.listItem, successHandler{
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? DoneViewController {
                listItemsTableViewController.clearPendingSwipeItemIfAny {
                    doneViewController.onUIReady = {
                        doneViewController.list = self.currentList
                    }
                }
            }
        } else if segue.identifier == "showAddIemSegue" {
            let controller = segue.destinationViewController as! AddEditListItemController
            controller.delegate = self
            addEditItemController = controller
            
            controller.transitioningDelegate = self
            controller.modalPresentationStyle = .Custom
            
            if let updatingListItem = updatingListItem { // edit (tapped on a list item)
                addEditItemController?.updatingListItem = updatingListItem
            }

        } else if segue.identifier == "stashSegue" {
            if let stashViewController = segue.destinationViewController as? StashViewController {
                listItemsTableViewController.clearPendingSwipeItemIfAny {
                    stashViewController.onUIReady = {
                        stashViewController.list = self.currentList
                    }
                }
            }
            
        } else {
            print("Invalid segue: \(segue.identifier)")
        }
    }
    
    func onAddTap() {
        performSegueWithIdentifier("showAddIemSegue", sender: self)
    }
    
    @IBAction func onAddGroupTap(sender: UIButton) {
        let controller = UIStoryboard.listItemsGroupsNavigationController()
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .Custom
        
        controller.navigationBar.translucent = true
        controller.navigationBar.shadowImage = UIImage()
        controller.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        controller.navigationBar.backgroundColor = UIColor.clearColor()
        controller.view.backgroundColor = UIColor.clearColor()
        
        for v in controller.view.subviews {
            v.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        }
        
        if let groupsController = controller.viewControllers.first as? ListItemGroupsViewController {

            groupsController.list = currentList
            groupsController.delegate = self
            
            presentViewController(controller, animated: true, completion: nil)
            
        } else {
            print("Error: The groups navigation controller doesn't have a controller or it has wrong class")
        }
    }
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        transition.duration = 0.2
        
        if let updatingSelectedCell = updatingSelectedCell {
            transition.startingPoint = view.convertPoint(updatingSelectedCell.center, fromView: listItemsTableViewController.tableView)
        } else {
            transition.startingPoint = view.convertPoint(addItemView.addButtonCenter, fromView: addItemView)
        }
        FrozenEffect.apply(transition.bubble)
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.duration = 0.2
        if let updatingSelectedCell = updatingSelectedCell {
            transition.startingPoint = view.convertPoint(updatingSelectedCell.center, fromView: listItemsTableViewController.tableView)
            
            // TODO side effects in this method, not pretty - use completion block or something?
            self.updatingSelectedCell = nil
            updatingListItem = nil
            
        } else {
            transition.startingPoint = view.convertPoint(addItemView.addButtonCenter, fromView: addItemView)
        }
        FrozenEffect.apply(transition.bubble)
        return transition
    }
    
    // MARK: - ListItemGroupsViewControllerDelegate
    
    func onGroupsAdded() {
        if let list = currentList {
            initWithList(list) // refresh list items
        } else {
            print("Invalid state, coming back from groups and no list")
        }
    }
    
}