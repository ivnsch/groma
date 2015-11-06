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
import ChameleonFramework

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, AddEditListItemControllerDelegate,ListItemGroupsViewControllerDelegate, QuickAddDelegate, BottonPanelViewDelegate, ReorderSectionTableViewControllerDelegate
//    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    private var addEditItemController: AddEditListItemController?
    // TODO put next vars in a struct
    private var updatingListItem: ListItem?
    private var updatingSelectedCell: UITableViewCell?
    
    private var listItemsTableViewController: ListItemsTableViewController!

    private var currentTopController: UIViewController?
    
    @IBOutlet weak var floatingViews: FloatingViews!
    
    private var gestureRecognizer: UIGestureRecognizer!

    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var stashView: StashView!
    @IBOutlet weak var pricesViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var listNameView: UILabel!
    
    @IBOutlet weak var topBar: UIView!

    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addButton: UIButton!

    private let transition = BlurBubbleTransition()
    
    private var titleLabel: UILabel?
    
    var expandDelegate: Foo?
    
    private let expandButtonModel: ExpandFloatingButtonModel = ExpandFloatingButtonModel()
    
    var currentList: List? {
        didSet {
            updatePossibleList()
        }
    }
    var onViewWillAppear: VoidFunction?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    @IBAction func onBackTap() {
        onExpand(false)
        expandDelegate?.setExpanded(false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()

        setEditing(false, animated: false, tryCloseTopViewController: false)
        
        initTitleLabel()
    }

    private func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.whiteColor()
        topBar.addSubview(label)
        titleLabel = label
    }

    func onExpand(expanding: Bool) {
        animateTitle(expanding)
    }
    
    func setThemeColor(color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.whiteColor()
        
        let colorArray = NSArray(ofColorsWithColorScheme: ColorScheme.Complementary, with: color, flatScheme: true)
        listItemsTableViewController.view.backgroundColor = colorArray[0] as? UIColor // as? to silence warning
        listItemsTableViewController.headerBGColor = colorArray[1] as? UIColor // as? to silence warning
        
        let compl = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
        editButton.setTitleColor(compl, forState: .Normal)
        
        // adjust nav controller for cart & stash (in this controller we use a custom view).
        navigationController?.setColors(color, textColor: compl)

        titleLabel?.textColor = compl
        
        expandButtonModel.bgColor = (colorArray[4] as! UIColor).lightenByPercentage(0.5)
        expandButtonModel.pathColor = UIColor(contrastingBlackOrWhiteColorOn: expandButtonModel.bgColor, isFlat: true)

//        stashView.bgColor = colorArray[3] as? UIColor
//        if let bgColor = stashView.bgColor {
//            stashView.setTextColor(UIColor(contrastingBlackOrWhiteColorOn: bgColor, isFlat: true))
//        } else {
//            print("Error: ViewController.setThemeColor, colorArray[3] is not a color")
//        }
        stashView.setNeedsDisplay()
    }
    
    private func updatePossibleList() {
        if let list = self.currentList {
            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }

    private func setTitleLabelText(text: String) {
        titleLabel?.text = text
        titleLabel?.sizeToFit()
        let center = CGPointMake(view.center.x, topBar.center.y)
        titleLabel?.center = center
    }
    
    private func animateTitle(expanding: Bool) {
        
        if let label = self.titleLabel {
            let left = CGPointMake(14 + label.frame.width / 2, self.topBar.center.y)
            let center = CGPointMake(self.view.center.x, self.topBar.center.y)
            
            label.center = expanding ? left : center
            UIView.animateWithDuration(0.3) { // note: speed has to be same as expand controller anim, otherwise "jump"
                label.center = expanding ? center : left
            }
        } else {
            print("Warn: ViewController.animateTitle: no label")
        }
    }
    
    private func initFloatingViews() {
        floatingViews.setActions(Array<FLoatingButtonAction>())
        floatingViews.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        onViewWillAppear?()
        onViewWillAppear = nil
        
        updateStashView(withDelay: true)
        
        initFloatingViews()
        
        updatePrices()
    }
    
    // Update stash view after a delay. The delay is for design reason, to let user see what's hapenning otherwise not clear together with view controller transition
    // but it ALSO turned to fix bug when user adds to stash and goes back to view controller too fast - count would not be updated (count fetch is quicker than writing items to database). FIXME (not critical) don't depend on this delay to fix this bug.
    func updateStashView(withDelay withDelay: Bool) {
        func f() {
            if let list = currentList {
                Providers.listItemsProvider.listItemCount(ListItemStatus.Stash, list: list, successHandler {[weak self] count in
                    if count != self?.stashView.quantity { // don't animate if there's no change
                        self?.stashView.quantity = count
                        self?.pricesView.setExpanded(count == 0)
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
    
    private func initWithList(list: List) {
        setTitleLabelText(list.name)
        udpateListItems(list)
    }
    
    private func udpateListItems(list: List, onFinish: VoidFunction? = nil) {
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{listItems in
            self.listItemsTableViewController.setListItems(listItems.filter{$0.status == .Todo})
            onFinish?()
        })
    }
    
    // MARK: - AddEditListItemControllerDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, sectionName: sectionName, note: note) {
        }
    }

    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, sectionName: sectionName, note: note) {[weak self] in
            self?.addEditItemController?.clearInputs()
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, sectionName: sectionName, note: note) {
            self.updateItem(self.updatingListItem!, listItemInput: listItemInput) {[weak self] in
            self?.setEditing(false, animated: true, tryCloseTopViewController: true)
            }
        }
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            let names = suggestions.filterMap({$0.name.contains(text, caseInsensitive: true)}){$0.name}
            handler(names)
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestions(successHandler{suggestions in
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
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?, successHandler: VoidFunction? = nil) {
        if !name.isEmpty {
            if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, sectionName: sectionName, note: note) {
                self.addItem(listItemInput, successHandler: successHandler)
                // self.view.endEditing(true)
            }
        }
    }

    // MARK:
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, category: String, sectionName: String, note: String?) -> ListItemInput? {
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
            
            return ListItemInput(name: name, quantity: quantity, price: price, category: category, section: sectionName, note: note)
            
        } else {
            print("TODO validation in processListItemInputs")
            return nil
        }
    }
    
    @IBAction func onEditTap(sender: AnyObject) {
        let editing = !self.listItemsTableViewController.editing
        
        self.setEditing(editing, animated: true, tryCloseTopViewController: true)
    }

    @IBAction func onAddTap(sender: AnyObject) {
        // if any top controller is open, close it
        if quickAddController.open || addEditController.open {
            if quickAddController.open {
                setQuickAddOpen(false)
            }
            if addEditController.open {
                setAddEditListItemOpen(false)
            }
            floatingViews.setActions(Array<FLoatingButtonAction>())  // reset floating actions
            
        } else { // if there's no top controller open, open the quick add controller
            setQuickAddOpen(true)
            floatingViews.setActions(Array<FLoatingButtonAction>())
        }
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }
        
//        addItemView.setVisible(editing, animated: animated)
        // TODO alpha of add button

        if tryCloseTopViewController {
            if quickAddController.open {
                setQuickAddOpen(false)
            } else if addEditController.open {
                setAddEditListItemOpen(false)
            }
        }
        if editing {
            self.floatingViews.setActions([expandButtonModel.collapsedAction])
        } else {
            floatingViews.setActions(Array<FLoatingButtonAction>())
        }
        
//        floatingViews.setActions(editing ? [toggleButtonAvailableAction, FLoatingButtonAttributedAction(action: .Add)] : [toggleButtonInactiveAction]) // remove possible top controller specific action buttons (e.g. on list item update we have a submit button), and set appropiate alpha

        listItemsTableViewController.setEditing(editing, animated: animated)
//        self.gestureRecognizer.enabled = !editing //don't block tap on delete button
        gestureRecognizer.enabled = false //don't block tap on delete button

        let navbarHeight = topBar.frame.height
//        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
//
        let topInset = navbarHeight + CGRectGetHeight(pricesView.frame)
        
        // TODO this makes a very big bottom inset why?
//            let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + addButtonContainer.frame.height
//        let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + 20
        let bottomInset: CGFloat = 0
    
        listItemsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
        listItemsTableViewController.tableView.topOffset = -listItemsTableViewController.tableView.inset.top
        
        if editing {
            editButton.setTitle("Done", forState: .Normal)
        } else {
            editButton.setTitle("Edit", forState: .Normal)
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
    
    // MARK: - ListItemsTableViewDelegate
    
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

    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        if self.editing {
            updatingListItem = tableViewListItem.listItem
            updatingSelectedCell = listItemsTableViewController.tableView.cellForRowAtIndexPath(indexPath)
            
            //            performSegueWithIdentifier("showAddIemSegue", sender: self)
            
            addEditController.updatingListItem = updatingListItem
            addEditController.delegate = self
            
            setAddEditListItemOpen(true)
            
        } else {

            listItemsTableViewController.markOpen(true, indexPath: indexPath, onFinish: {[weak self] in
                // "fake" update of price labels - the update has not been submitted yet to provider, since we just opened the cell and the item is submitted only after "undo" is cleared
                // we do this for simplicity purposes, if we submitted on cell open we would have to revert the update on "undo".
                // Note that after item is submitted we fetch from provider and update the labels again, to "be sure" (this time without animation). There's no real reason for this, just in case.
                // Note also callback onFinish - when there's another undo item it will be submitted automatically, which triggers a provider and price view update
                // so we have to ensure our fake update comes after this possible update, otherwise it's overwritten.
                let updatedPrice = (self?.pricesView.donePrice ?? 0) + tableViewListItem.listItem.totalPrice
                self?.pricesView.setDonePrice(updatedPrice, animated: true)
            })
        }
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // since we do a "fake" update of done price label when item is marked as undo (provider is not updated yet), we have to set label back when undo is reverted
        // this is done by simply reloading the prices from the provider
        updatePrices()
    }

    
    // MARK: -
    
//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    private func getTableViewInset() -> CGFloat {
        return topBar.frame.height
    }

    func loadItems(handler: Try<[String]> -> ()) {
        Providers.productProvider.products(successHandler{products in
            let names = products.map{$0.name}
            handler(Try(names))
        })
    }
    
    func onListItemsChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.update(tableViewListItems.map{$0.listItem}, successHandler{result in
        })
    }
    
    /**
    Update price labels (total, done) using state in provider
    */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {
        if let currentList = self.currentList {
            Providers.listItemsProvider.listItems(currentList, fetchMode: listItemsFetchMode, successHandler{listItems in
                self.pricesView.setTotalPrice(listItems.totalPriceTodoAndCart, animated: false)
                // The reason we exclude stash from total price is that when user is in the store they want to know what they will have to pay at the end (if they buy the complete list - this may not be necessarily the case though), which is todo + stash
                self.pricesView.setDonePrice(listItems.totalPriceDone, animated: false)
            })
        }
    }
    
    private func addItem(listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {

        if let currentList = self.currentList {
            
            self.progressVisible(true)
            
            Providers.listItemsProvider.add(listItemInput, list: currentList, order: nil, possibleNewSectionOrder: listItemsTableViewController.sections.count, successHandler {[weak self] savedListItem in
                self?.onListItemAddedToProvider(savedListItem)
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }

    }
    
    
    private func onListItemAddedToProvider(savedListItem: ListItem) {
        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
        listItemsTableViewController.updateOrAddListItem(savedListItem, increment: true, scrollToSelection: true)
        updatePrices(.MemOnly)
    }
    
    func updateItem(listItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            if let updatingListItem = self.updatingListItem {
                
                let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price, category: listItemInput.category) // possible product update
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
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        Providers.listItemsProvider.remove(tableViewListItem.listItem, successHandler{
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? DoneViewController {
                doneViewController.navigationItemTextColor = titleLabel?.textColor
                listItemsTableViewController.clearPendingSwipeItemIfAny {
                    doneViewController.onUIReady = {
                        doneViewController.list = self.currentList
                    }
                }
            }
        }
//        else if segue.identifier == "showAddIemSegue" {
//            let controller = segue.destinationViewController as! AddEditListItemController
//            controller.delegate = self
//            addEditItemController = controller
//            
//            controller.transitioningDelegate = self
//            controller.modalPresentationStyle = .Custom
//            
//            if let updatingListItem = updatingListItem { // edit (tapped on a list item)
//                addEditItemController?.updatingListItem = updatingListItem
//            }
//
//        }
        else if segue.identifier == "stashSegue" {
            if let stashViewController = segue.destinationViewController as? StashViewController {
                stashViewController.navigationItemTextColor = titleLabel?.textColor
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
    
    
    // MARK: - quick add
    /////////////////////////////////////////////////////////////////////////////////////////////
    /// quick add
    /////////////////////////////////////////////////////////////////////////////////////////////

    private lazy var quickAddController: QuickAddViewController = {
        let controller = UIStoryboard.quickAddViewController()
        controller.delegate = self
        controller.productDelegate = self
        let height: CGFloat = 350
        self.initTopController(controller, height: height)
//        controller.originalViewFrame = CGRectMake(controller.view.frame.origin.x, controller.view.frame.origin.y, controller.view.frame.width, height)
        return controller
    }()
    
    private func setQuickAddOpen(open: Bool) {
        quickAddController.open = open
        animateTopView(quickAddController.view, open: open)
        
        if open {
            currentTopController = quickAddController
        } else {
            currentTopController = nil
        }
        
//        if open {
//            addItemView.setButtonText("Close")
//            addItemView.setButtonColor(UIColor(red: 177/255, green: 177/255, blue: 177/255, alpha: 1))
//        } else {
//            addItemView.setButtonText("Add item")
//            addItemView.setButtonColor(UIColor(red: 244/255, green: 43/255, blue: 139/255, alpha: 1))
//        }
        
        

    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////

    private func initTopController(controller: UIViewController, height: CGFloat) {
        let view = controller.view

        view.frame = CGRectMake(0, CGRectGetHeight(topBar.frame) + CGRectGetHeight(pricesView.frame), self.view.frame.width, height)
        
        // swift anchor
        view.layer.anchorPoint = CGPointMake(0.5, 0)
        view.frame.origin = CGPointMake(0, view.frame.origin.y - height / 2)
        
        let transform: CGAffineTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 0.001) //0.001 seems to be necessary for scale down animation to be visible, with 0 the view just disappears
        view.transform = transform
    }
    
    
    // MARK: - add/edit
    //////////////////////////////////////////////////////////////////////////////////////////////
    /// add edit add
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    private lazy var addEditController: AddEditListItemViewController = {
        let controller = UIStoryboard.addEditListItemViewController()
        self.initTopController(controller, height: 250)
        return controller
    }()
    
    private func setAddEditListItemOpen(open: Bool) {
        addEditController.open = open
        animateTopView(addEditController.view, open: open)
        
        if open {
            currentTopController = quickAddController
            floatingViews.setActions([
                FLoatingButtonAttributedAction(action: .Submit)])

        } else {
            currentTopController = nil
            floatingViews.setActions(Array<FLoatingButtonAction>()) // this is done with setEditing false
        }
        
//        if open {
//            addItemView.setButtonText("Save")
//            addItemView.setButtonColor(UIColor(red: 244/255, green: 43/255, blue: 139/255, alpha: 1))
//        } else {
//            addItemView.setButtonText("Add item")
//            addItemView.setButtonColor(UIColor(red: 244/255, green: 43/255, blue: 139/255, alpha: 1))
//        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    
    private func animateTopView(view: UIView, open: Bool) {
        if open {
            self.view.addSubview(view)
            tableViewOverlay.frame = self.view.frame
            self.view.insertSubview(tableViewOverlay, aboveSubview: listItemsTableViewController.tableView)
        } else {
            tableViewOverlay.removeFromSuperview()
        }
        
        UIView.animateWithDuration(0.3, animations: {
            if open {
                self.tableViewOverlay.alpha = 0.2
            } else {
                self.tableViewOverlay.alpha = 0
            }
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, open ? 1 : 0.001)
            
            let topInset = CGRectGetHeight(self.topBar.frame) + CGRectGetHeight(view.frame) + CGRectGetHeight(self.pricesView.frame)
            let bottomInset = self.navigationController?.tabBarController?.tabBar.frame.height
            self.listItemsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset!, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
            self.listItemsTableViewController.tableView.topOffset = -self.listItemsTableViewController.tableView.inset.top
            
            }) { finished in
        
            if !open {
                view.removeFromSuperview()
            }
        }
    }

    private lazy var tableViewOverlay: UIView = {
        let view = UIButton()
        view.backgroundColor = UIColor.blackColor()
//        view.userInteractionEnabled = true
        view.alpha = 0
//        view.addTarget(self, action: "onQuickAddOverlayTap:", forControlEvents: .TouchUpInside)
        return view
    }()

    // Usability improvement? (Dismiss add view easily, on the other side it also makes it easy to close by mistake)
//    func onQuickAddOverlayTap(sender: UIButton) {
//        setQuickAddOpen(false)
//    }
    


    // MARK: - ListItemGroupsViewControllerDelegate
    
    func onGroupsAdded() {
        if let list = currentList {
            initWithList(list) // refresh list items
        } else {
            print("Invalid state, coming back from groups and no list")
        }
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        setQuickAddOpen(false)
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let list = currentList {

            // TODO save "group list item" don't desintegrate group immediatly
            
            Providers.listItemsProvider.add(group.items, list: list, successHandler {[weak self] addedListItems in
                self?.onGroupsAdded()
                onFinish?()
                
            })
        } else {
            print("Error: Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onAddProduct(product: Product) {
        if let list = currentList {
            Providers.listItemsProvider.addListItem(product, sectionName: product.category, quantity: 1, list: list, note: nil, order: nil, successHandler {[weak self] savedListItem in
                self?.onListItemAddedToProvider(savedListItem)
            })
        } else {
            print("Error: Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onQuickListOpen() {
        floatingViews.setActions(Array<FLoatingButtonAction>())
    }
    
    func onAddProductOpen() {
        floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit)])
    }
    
    func onAddGroupOpen() {
        floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit), FLoatingButtonAttributedAction(action: .Add)])
    }
    
    func onAddGroupItemsOpen() {
        floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit), FLoatingButtonAttributedAction(action: .Back)])
    }
    
    
    // was used to expand the quick add embedded view controller to fill available space when adding group items. Maybe will be used again in the future.
//    func setContentViewExpanded(expanded: Bool, myTopOffset: CGFloat, originalFrame: CGRect) {
//        
//        let topOffset = myTopOffset + pricesView.frame.height
//        
//        UIView.animateWithDuration(0.3) {[weak self] in
//            if let weakSelf = self {
//                if expanded {
//                    weakSelf.quickAddController.view.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y - topOffset, originalFrame.width, weakSelf.view.frame.height)
////                    weakSelf.quickAddController.view.frame.origin = CGPointMake(originalFrame.origin.x, originalFrame.origin.y - topOffset)
////                    weakSelf.quickAddController.view.transform = CGAffineTransformMakeScale(1, 1.5)
//                } else {
//                    weakSelf.quickAddController.view.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y, originalFrame.width, originalFrame.height)
////                    weakSelf.quickAddController.view.frame.origin = CGPointMake(originalFrame.origin.x, originalFrame.origin.y)
////                    weakSelf.quickAddController.view.transform = CGAffineTransformMakeScale(1, 1.0)
//                }
////                            self?.view.layoutIfNeeded()
//            }
//        }
//    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        handleFloatingViewAction(action)
    }
    
    private func handleFloatingViewAction(action: FLoatingButtonAction) {
        switch action {
        case .Toggle:
            // if any top controller is open, close it
            if quickAddController.open || addEditController.open {
                if quickAddController.open {
                    setQuickAddOpen(false)
                }
                if addEditController.open {
                    setAddEditListItemOpen(false)
                }
                floatingViews.setActions(Array<FLoatingButtonAction>())  // reset floating actions
                
            } else { // if there's no top controller open, open the quick add controller
                setQuickAddOpen(true)
                floatingViews.setActions(Array<FLoatingButtonAction>())
            }
        case .Expand: // expand / collapse sections in edit mode
            toggleReorderSections()
            
        case .Back, .Submit, .Add: sendActionToTopController(action)
        }
    }
    
    private func sendActionToTopController(action: FLoatingButtonAction) {
        if let quickAddViewController = currentTopController as? QuickAddViewController { // quick add case
            quickAddViewController.handleFloatingButtonAction(action) // delegate dispatching to quick add controller
            
        } else if let addEditListItemViewController = currentTopController as? AddEditListItemViewController { // update case
            // here we do dispatching in place as it's relatively simple and don't want to contaminate to many view controllers with floating button code
            // there should be a separate component to do all this but no time now. TODO improve
            
            switch action {
            case .Submit:
                addEditListItemViewController.submit(AddEditListItemViewControllerAction.Update)
            case .Back, .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(addEditListItemViewController) instance")
            }
        }
    }
    
    // MARK: - Reorder sections
    
    private var sectionsTableViewController: ReorderSectionTableViewController?
    private var lockToggleSectionsTableView: Bool = false // prevent condition in which user presses toggle too quickly many times and sectionsTableViewController doesn't go away
    
    
    // Toggles between expanded and collapsed section mode. For this a second tableview with only sections is added or removed from foreground. Animates floating button.
    private func toggleReorderSections() {
        
        if !lockToggleSectionsTableView {
            lockToggleSectionsTableView = true
            
            if let sectionsTableViewController = sectionsTableViewController { // collapse
                
                sectionsTableViewController.setCellHeight(30, animated: true)
                sectionsTableViewController.setEdit(false, animated: true) {
                    sectionsTableViewController.removeFromParentViewController()
                    sectionsTableViewController.view.removeFromSuperview()
                    self.sectionsTableViewController = nil
                    self.listItemsTableViewController.setAllSectionsExpanded(!self.listItemsTableViewController.sectionsExpanded, animated: true)
                    self.lockToggleSectionsTableView = false
                    
                    self.floatingViews.setActions([self.expandButtonModel.collapsedAction])
                }
            } else {
                
                listItemsTableViewController.setAllSectionsExpanded(!listItemsTableViewController.sectionsExpanded, animated: true, onComplete: { // expand
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewController()
                    
                    sectionsTableViewController.cellBgColor = self.listItemsTableViewController.headerBGColor
                    sectionsTableViewController.textColor = UIColor(contrastingBlackOrWhiteColorOn: self.listItemsTableViewController.headerBGColor, isFlat: true)
                    sectionsTableViewController.sections = self.listItemsTableViewController.sections
                    sectionsTableViewController.delegate = self
                    
                    sectionsTableViewController.onViewDidLoad = {
                        let navbarHeight = self.topBar.frame.height
                        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
                        let topInset = navbarHeight + CGRectGetHeight(self.pricesView.frame) - statusBarHeight
                        // TODO this makes a very big bottom inset why?
                        //            let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + addButtonContainer.frame.height
                        //        let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + 20
                        let bottomInset: CGFloat = 0
                        sectionsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
                        //                sectionsTableViewController.tableView.topOffset = -self.listItemsTableViewController.tableView.inset.top
                        
                        sectionsTableViewController.view.backgroundColor = self.listItemsTableViewController.view.backgroundColor
                        sectionsTableViewController.tableView.backgroundColor = self.listItemsTableViewController.view.backgroundColor
                        
                        self.lockToggleSectionsTableView = false
                    }
                    
                    sectionsTableViewController.view.frame = self.listItemsTableViewController.view.frame
                    self.addChildViewControllerAndView(sectionsTableViewController, viewIndex: 1)
                    self.sectionsTableViewController = sectionsTableViewController
                    
                    self.floatingViews.setActions([self.expandButtonModel.expandedAction])
                })
            }
        }
    }
    
    // MARK: - ReorderSectionTableViewControllerDelegate
    
    func onSectionsUpdated() {
        if let list = currentList {
            self.udpateListItems(list) {
                self.listItemsTableViewController.setAllSectionsExpanded(false, animated: false) // set back background tableview to to closed state (update re-adds everything - expanded). This is necessary for consistency tableview rows/models
            }
        } else {
            print("Error: ViewController.onSectionOrderUpdated: Invalid state, reordering sections and no list")
        }
    }
}