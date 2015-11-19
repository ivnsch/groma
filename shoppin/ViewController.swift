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

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, AddEditListItemViewControllerDelegate,ListItemGroupsViewControllerDelegate, QuickAddDelegate, BottonPanelViewDelegate, ReorderSectionTableViewControllerDelegate, CartViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate
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

    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var stashView: StashView!
    @IBOutlet weak var pricesViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var listNameView: UILabel!
    
    @IBOutlet weak var topBar: ListTopBarView!

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
    
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    private var topAddEditListItemControllerManager: ExpandableTopViewController<AddEditListItemViewController>?
    private var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()

        setEditing(false, animated: false, tryCloseTopViewController: false)
        
        initTitleLabel()
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()
        topAddEditListItemControllerManager = initAddEditListItemControllerManager()
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        topBar.delegate = self
        
        floatingViews.userInteractionEnabled = false
    }
    
    private func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = CGRectGetHeight(topBar.frame) + pricesView.frame.height
        let openInset = CGRectGetHeight(topBar.frame) + pricesView.minimizedHeight
        let closedInset = top
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: 290, openInset: openInset, closeInset: closedInset, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.productDelegate = self
            if let backgroundColor = self?.view.backgroundColor {
                controller.addProductsOrGroupBgColor = UIColor.opaqueColorByApplyingTransparentColorOrBackground(backgroundColor.colorWithAlphaComponent(0.3), backgroundColor: UIColor.whiteColor())
            }
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    private func initAddEditListItemControllerManager() -> ExpandableTopViewController<AddEditListItemViewController> {
        let top = CGRectGetHeight(topBar.frame) + pricesView.frame.height
        let openInset = CGRectGetHeight(topBar.frame) + pricesView.minimizedHeight
        let closedInset = top
        let manager: ExpandableTopViewController<AddEditListItemViewController> =  ExpandableTopViewController(top: top, height: 240, openInset: openInset, closeInset: closedInset, parentViewController: self, tableView: listItemsTableViewController.tableView) {
            return UIStoryboard.addEditListItemViewController()
        }
        manager.delegate = self
        return manager
    }

    private func initEditSectionControllerManager() -> ExpandableTopViewController<EditSectionViewController> {
        let top = CGRectGetHeight(topBar.frame) + CGRectGetHeight(pricesView.frame)
        return ExpandableTopViewController(top: top, height: 60, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = EditSectionViewController()
            controller.delegate = self
            return controller
        }
    }
    
    private func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.whiteColor()
        topBar.addSubview(label)
        titleLabel = label
    }

    func onExpand(expanding: Bool) {
        if !expanding {
            clearPossibleUndo()
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
        }
        topBar.positionTitleLabelLeft(expanding, animated: true)
    }
    
    func setThemeColor(color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.whiteColor()
        
        let colorArray = NSArray(ofColorsWithColorScheme: ColorScheme.Complementary, with: color, flatScheme: true)
        view.backgroundColor = colorArray[0] as? UIColor // as? to silence warning
        listItemsTableViewController.view.backgroundColor = colorArray[0] as? UIColor // as? to silence warning
        listItemsTableViewController.headerBGColor = colorArray[1] as? UIColor // as? to silence warning
        
        let compl = UIColor(contrastingBlackOrWhiteColorOn: color, isFlat: true)
        
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
        
        topBar.fgColor = compl
            
        stashView.setNeedsDisplay()
    }
    
    private func updatePossibleList() {
        if let list = self.currentList {
            self.navigationItem.title = list.name
            self.initWithList(list)
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
                        self?.pricesView.setExpandedHorizontal(count == 0)
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
        topBar.title = list.name
        udpateListItems(list)
    }
    
    private func udpateListItems(list: List, onFinish: VoidFunction? = nil) {
        Providers.listItemsProvider.listItems(list, fetchMode: .MemOnly, successHandler{listItems in
            self.listItemsTableViewController.setListItems(listItems.filter{$0.status == .Todo})
            onFinish?()
        })
    }
    
    // MARK: - AddEditListItemViewControllerDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit) {
        }
    }

    // TODO remove this, not used
    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit) {[weak self] in
            self?.addEditItemController?.clearInputs()
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit) {
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
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, successHandler: VoidFunction? = nil) {
        if !name.isEmpty {
            if let listItemInput = processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit) {
                addItem(listItemInput, successHandler: successHandler)
                // self.view.endEditing(true)
            }
        }
    }

    // MARK:
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, category: String, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit) -> ListItemInput? {
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
            
            return ListItemInput(name: name, quantity: quantity, price: price, category: category, section: sectionName, note: note, baseQuantity: baseQuantity, unit: unit)
            
        } else {
            print("TODO validation in processListItemInputs")
            return nil
        }
    }
    
    private func toggleTopAddController() {
        
        clearPossibleUndo()
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || topAddEditListItemControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            topAddEditListItemControllerManager?.expand(false)
            
            pricesView.setExpandedVertical(true)

            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            floatingViews.setActions(Array<FLoatingButtonAction>())  // reset floating actions
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            
            pricesView.setExpandedVertical(false)

            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
            floatingViews.setActions(Array<FLoatingButtonAction>())
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        clearPossibleUndo()
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing == false {
            view.endEditing(true)
        }

        if tryCloseTopViewController {
            topQuickAddControllerManager?.expand(false)
            topAddEditListItemControllerManager?.expand(false)
            pricesView.setExpandedVertical(true)
        }
        if editing {
            floatingViews.setActions([expandButtonModel.collapsedAction])
        } else {
            topBar.setRightButtonIds([.ToggleOpen])
            floatingViews.setActions(Array<FLoatingButtonAction>())
        }

        listItemsTableViewController.setEditing(editing, animated: animated)

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
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
//    func itemsChanged() {
//        self.initList()
//    }
    
    private func initTableViewController() {
        self.listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        self.addChildViewControllerAndView(self.listItemsTableViewController, viewIndex: 0)
        
        self.listItemsTableViewController.scrollViewDelegate = self
        self.listItemsTableViewController.listItemsTableViewDelegate = self
        self.listItemsTableViewController.listItemsEditTableViewDelegate = self
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearPossibleUndo()
    }
    
    func clearPossibleUndo() {
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
            
            
            topAddEditListItemControllerManager?.controller?.updatingListItem = updatingListItem
            topAddEditListItemControllerManager?.controller?.delegate = self
            topAddEditListItemControllerManager?.expand(true)
            pricesView.setExpandedVertical(false)
//            addEditController.updatingListItem = updatingListItem
//            addEditController.delegate = self
//            
//            setAddEditListItemOpen(true)
            
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
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        if editing {
            topEditSectionControllerManager?.tableView = listItemsTableViewController.tableView
            topEditSectionControllerManager?.controller?.section = section.section
            topEditSectionControllerManager?.expand(true)
        }
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
                
                let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price, category: listItemInput.category, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit) // possible product update
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
    
    @IBAction func onCartTap(sender: UIButton) {
        performSegueWithIdentifier("doneViewControllerSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneViewControllerSegue" {
            if let doneViewController = segue.destinationViewController as? DoneViewController {
                doneViewController.navigationItemTextColor = titleLabel?.textColor
                doneViewController.delegate = self
                doneViewController.onUIReady = {
                    self.listItemsTableViewController.clearPendingSwipeItemIfAny {
                        doneViewController.list = self.currentList
                        doneViewController.backgroundColor = self.view.backgroundColor
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
                        stashViewController.backgroundColor = self.view.backgroundColor
                    }
                }
            }
            
        } else {
            print("Invalid segue: \(segue.identifier)")
        }
    }

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
        topQuickAddControllerManager?.expand(false)
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
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
    }
    
    func onAddProductOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Add),
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Submit),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
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
        case .Expand: // expand / collapse sections in edit mode
            toggleReorderSections()
        default: break
        }
    }
    
    // MARK: - EditSectionViewControllerDelegate
    
    func onSectionUpdated(section: Section) {
        // use table view of controller which is showing
        let tableView: UITableView = sectionsTableViewController?.tableView ?? listItemsTableViewController.tableView
        topEditSectionControllerManager?.tableView = tableView
        topEditSectionControllerManager?.expand(false)
        listItemsTableViewController.updateSection(section)
    }
    
    private func sendActionToTopController(action: FLoatingButtonAction) {
        
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        } else if topAddEditListItemControllerManager?.expanded ?? false {
            // here we do dispatching in place as it's relatively simple and don't want to contaminate to many view controllers with floating button code
            // there should be a separate component to do all this but no time now. TODO improve
            
            switch action {
            case .Submit:
                topAddEditListItemControllerManager?.controller?.submit(AddEditListItemViewControllerAction.Update)
            case .Back, .Add, .Toggle, .Expand: print("QuickAddViewController.handleFloatingButtonAction: Invalid action: \(action) for \(topAddEditListItemControllerManager?.controller) instance")
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
            
            if let sectionsTableViewController = sectionsTableViewController { // expand - remove sections table view
                
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
                
                listItemsTableViewController.setAllSectionsExpanded(!listItemsTableViewController.sectionsExpanded, animated: true, onComplete: { // collapse - add sections table view
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewController()
                    
                    sectionsTableViewController.cellBgColor = self.listItemsTableViewController.headerBGColor
                    sectionsTableViewController.selectedCellBgColor = self.expandButtonModel.bgColor
                    sectionsTableViewController.textColor = UIColor(contrastingBlackOrWhiteColorOn: self.listItemsTableViewController.headerBGColor, isFlat: true)
                    sectionsTableViewController.sections = self.listItemsTableViewController.sections
                    sectionsTableViewController.delegate = self
                    
                    sectionsTableViewController.onViewDidLoad = {
                        let navbarHeight = self.topBar.frame.height
                        let topInset = navbarHeight + CGRectGetHeight(self.pricesView.frame)
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
    
    func onSectionSelected(section: Section) {
        if let sectionsTableViewController = sectionsTableViewController {
            topEditSectionControllerManager?.tableView = sectionsTableViewController.tableView
            topEditSectionControllerManager?.expand(true)
            topEditSectionControllerManager?.controller?.section = section
        } else {
            print("Error: ViewController.onSectionSelected: Invalid state: onSectionSelected called but there's no sectionsTableViewController")
        }
    }
    
    // MARK: - CartViewControllerDelegate
    
    func onEmptyCartTap() {
        navigationController?.popViewControllerAnimated(true)
        performSegueWithIdentifier("stashSegue", sender: self)
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        if controller is QuickAddViewController || controller is AddEditListItemViewController {
            if expand {
                view.frame.origin.y = CGRectGetHeight(topBar.frame) + pricesView.minimizedHeight
            } else {
                view.frame.origin.y = CGRectGetHeight(topBar.frame) + pricesView.originalHeight
            }
        }
    }
    
    func onExpandableClose() {
        pricesView.setExpandedVertical(true)
        topBar.setBackVisible(false)
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.Back)
    }
    
    func onTopBarTitleTap() {
        onExpand(false)
        expandDelegate?.setExpanded(false)
    }
    
    func onTopBarButtonTap(buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .Add:
            sendActionToTopController(.Add)
        case .Submit:
            if topEditSectionControllerManager?.expanded ?? false {
                topEditSectionControllerManager?.controller?.submit()
            } else {
                sendActionToTopController(.Submit)
            }
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            clearPossibleUndo()
            let editing = !self.listItemsTableViewController.editing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        }
    }
    
    func onCenterTitleAnimComplete(center: Bool) {
        if center {
            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonIds([.ToggleOpen])
        }
    }
}