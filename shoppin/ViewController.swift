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

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, AddEditListItemViewControllerDelegate, QuickAddDelegate, ReorderSectionTableViewControllerDelegate, CartViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate, ExpandCollapseButtonDelegate
//    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    // TODO put next vars in a struct
    private var updatingListItem: ListItem?
    private var updatingSelectedCell: UITableViewCell?
    
    private var listItemsTableViewController: ListItemsTableViewController!

    private var currentTopController: UIViewController?
    
    @IBOutlet weak var expandCollapseButton: ExpandCollapseButton!
    
    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var stashView: StashView!
    @IBOutlet weak var pricesViewWidthConstraint: NSLayoutConstraint!
    
    // TODO 1 custom view for empty
    @IBOutlet weak var emptyListView: UIView!
    @IBOutlet weak var emptyListViewImg: UIImageView!
    @IBOutlet weak var emptyListViewLabel1: UILabel!
    @IBOutlet weak var emptyListViewLabel2: UILabel!
    
    @IBOutlet weak var listNameView: UILabel!
    
    @IBOutlet weak var topBar: ListTopBarView!

    private let transition = BlurBubbleTransition()
    
    private var titleLabel: UILabel?
    
    var expandDelegate: Foo?
    
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

        expandCollapseButton.delegate = self

        topQuickAddControllerManager = initTopQuickAddControllerManager()
        topAddEditListItemControllerManager = initAddEditListItemControllerManager()
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        topBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItems:", name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItem:", name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSection:", name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        let manager: ExpandableTopViewController<EditSectionViewController> = ExpandableTopViewController(top: top, height: 60, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = EditSectionViewController()
            controller.delegate = self
            return controller
        }
        manager.delegate = self
        return manager
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
            emptyListView.hidden = true
            clearPossibleUndo()
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
            // Clear list item memory cache when we leave controller. This is not really necessary but just "in case". The list item memory cache is there to smooth things *inside* a list, that is transitions between todo/done/stash, and adding/incrementing items. Causing a db-reload when we load the controller is totally ok.
            Providers.listItemsProvider.invalidateMemCache()
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
        
        expandCollapseButton.backgroundColor = (colorArray[4] as! UIColor).lightenByPercentage(0.5)
        expandCollapseButton.strokeColor = UIColor(contrastingBlackOrWhiteColorOn: expandCollapseButton.backgroundColor, isFlat: true)
        
//        stashView.bgColor = colorArray[3] as? UIColor
//        if let bgColor = stashView.bgColor {
//            stashView.setTextColor(UIColor(contrastingBlackOrWhiteColorOn: bgColor, isFlat: true))
//        } else {
//            print("Error: ViewController.setThemeColor, colorArray[3] is not a color")
//        }
        
        topBar.fgColor = compl
        
        emptyListViewImg.tintColor = compl
        emptyListViewLabel1.textColor = compl
        emptyListViewLabel2.textColor = compl
        
        stashView.setNeedsDisplay()
    }
    
    private func updatePossibleList() {
        if let list = self.currentList {
//            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)

        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        onViewWillAppear?()
        onViewWillAppear = nil
        
        updateStashView(withDelay: true)
        
        updatePrices(.First)
     
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyListViewTap:"))
        emptyListView.addGestureRecognizer(tapRecognizer)
    }
    
    func onEmptyListViewTap(sender: UITapGestureRecognizer) {
        toggleTopAddController() // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
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
        Providers.listItemsProvider.listItems(list, sortOrderByStatus: .Todo, fetchMode: .MemOnly, successHandler{[weak self] listItems in
            self?.listItemsTableViewController.setListItems(listItems.filter{$0.hasStatus(.Todo)})
            self?.updateEmptyView()
            onFinish?()
        })
    }
    
    // MARK: - AddEditListItemViewControllerDelegate

    func onValidationErrors(errors: [UITextField: ValidationError]) {
        // TODO validation errors in the add/edit popup. Or make that validation popup comes in front of add/edit popup, which is added to window (possible?)
        self.presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        submitInputs(name, price: priceText, quantity: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand) {
        }
    }

    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) {
        if let listItemInput = self.processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand) {
            
            // set normal (.Note) mode in advance - with updateItem the table view calls reloadData, but the change to .Note mode happens after (in setEditing), which doesn't reload the table so the cells will appear without notes.
            listItemsTableViewController.cellMode = .Note
            updateItem(updatingListItem!, listItemInput: listItemInput) {[weak self] in
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
        Providers.sectionProvider.sectionSuggestionsContainingText(text, successHandler{suggestions in
            handler(suggestions)
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        Providers.planProvider.planItem(productName, successHandler {planItemMaybe in
            handler(planItemMaybe)
        })
    }
    
    private func submitInputs(name: String, price priceText: String, quantity quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String, successHandler: VoidFunction? = nil) {
        if !name.isEmpty {
            if let listItemInput = processListItemInputs(name, priceText: priceText, quantityText: quantityText, category: category, categoryColor: categoryColor, sectionName: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand) {
                addItem(listItemInput, successHandler: successHandler)
                // self.view.endEditing(true)
            }
        }
    }

    // MARK:
    
    private func processListItemInputs(name: String, priceText: String, quantityText: String, category: String, categoryColor: UIColor, sectionName: String, note: String?, baseQuantity: Float, unit: ProductUnit, brand: String) -> ListItemInput? {
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
            
            return ListItemInput(name: name, quantity: quantity, price: price, category: category, categoryColor: categoryColor, section: sectionName, note: note, baseQuantity: baseQuantity, unit: unit, brand: brand)
            
        } else {
            print("TODO validation in processListItemInputs")
            return nil
        }
    }
    
    private func toggleTopAddController() {
        
        clearPossibleUndo()
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || topAddEditListItemControllerManager?.expanded ?? false || topEditSectionControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            topAddEditListItemControllerManager?.expand(false)
            topEditSectionControllerManager?.expand(false)
            
            pricesView.setExpandedVertical(true)

            topBar.setLeftButtonIds([.Edit])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            
            if editing {
                // if we are in edit mode, show the reorder sections button again (we hide it when we open the top controller)
                expandCollapseButton.setHiddenAnimated(false)
            }
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            
            pricesView.setExpandedVertical(false)

            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
            
            // in case we are in reorder sections mode, come back to normal. This mode doesn't make sense while adding list items as we can't see the list items.
            setReorderSections(false)
            // don't show the reorder sections button during quick add is open because it stand in the way
            expandCollapseButton.setHiddenAnimated(true)
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
        
        expandCollapseButton.setHiddenAnimated(!editing)
        
        if !editing {
            // in case we are in reorder sections mode, come back to normal. This is an edit specific mode.
            setReorderSections(false)
            expandCollapseButton.setHiddenAnimated(true)
            
            topBar.setRightButtonIds([.ToggleOpen])
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
        
        listItemsTableViewController.cellMode = editing ? .Increment : .Note
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
//    func itemsChanged() {
//        self.initList()
//    }
    
    private func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.status = .Todo
        listItemsTableViewController.scrollViewDelegate = self
        listItemsTableViewController.listItemsTableViewDelegate = self
        listItemsTableViewController.listItemsEditTableViewDelegate = self
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearPossibleUndo()
    }
    
    func clearPossibleUndo() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    // MARK: - ListItemsTableViewDelegate
    
    func onListItemClear(tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        tableViewListItem.listItem.switchStatusQuantityMutable(.Todo, targetStatus: .Done)
        
        if let list = self.currentList {
            
            Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: list, status1: .Todo, status: .Done, remote: notifyRemote) {[weak self] result in
                if result.success {
                    self?.listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
                    self?.updatePrices(.MemOnly)
                    self?.updateEmptyView()
                }
                onFinish()
            }
        } else {
            onFinish()
        }
    }
    
    private func updateEmptyView() {
        emptyListView.setHiddenAnimated(!listItemsTableViewController.items.isEmpty)
    }

    func onListItemSelected(tableViewListItem: TableViewListItem, indexPath: NSIndexPath) {
        if self.editing {
            updatingListItem = tableViewListItem.listItem
            updatingSelectedCell = listItemsTableViewController.tableView.cellForRowAtIndexPath(indexPath)

            topAddEditListItemControllerManager?.expand(true)
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
            pricesView.setExpandedVertical(false)
            
            topAddEditListItemControllerManager?.controller?.updatingItem = AddEditItem(item: tableViewListItem.listItem)
            topAddEditListItemControllerManager?.controller?.delegate = self
            
        } else {

            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in
                // "fake" update of price labels - the update has not been submitted yet to provider, since we just opened the cell and the item is submitted only after "undo" is cleared
                // we do this for simplicity purposes, if we submitted on cell open we would have to revert the update on "undo".
                // Note that after item is submitted we fetch from provider and update the labels again, to "be sure" (this time without animation). There's no real reason for this, just in case.
                // Note also callback onFinish - when there's another undo item it will be submitted automatically, which triggers a provider and price view update
                // so we have to ensure our fake update comes after this possible update, otherwise it's overwritten.
                let updatedPrice = (self?.pricesView.donePrice ?? 0) + tableViewListItem.listItem.totalPrice(.Todo)
                self?.pricesView.setDonePrice(updatedPrice, animated: true)
            })
        }
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // since we do a "fake" update of done price label when item is marked as undo (provider is not updated yet), we have to set label back when undo is reverted
        // this is done by simply reloading the prices from the provider
        updatePrices(.MemOnly)
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        onSectionSelected(section.section)
    }
    
    func onIncrementItem(tableViewListItem: TableViewListItem, delta: Int) {
        Providers.listItemsProvider.increment(tableViewListItem.listItem, delta: delta, successHandler{[weak self] in
            // TODO do this in  the provider, provider should return incremented item
            let incremented: ListItem = tableViewListItem.listItem.increment(ListItemStatusQuantity(status: .Todo, quantity: delta))
            self?.listItemsTableViewController.updateOrAddListItem(incremented, status: .Todo, increment: false, notifyRemote: false)
        })
    }
    
    // MARK: -
    
    // for tap on normal sections and edit mode sections (2 different tableviews)
    private func onSectionSelectedShared(section: Section) {
        if editing {
            topEditSectionControllerManager?.tableView = sectionsTableViewController?.tableView ?? listItemsTableViewController.tableView
            topEditSectionControllerManager?.expand(true)
            topEditSectionControllerManager?.controller?.section = section
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .Submit),
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
        }
    }
    
//    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
//        return UIBarPosition.TopAttached
//    }
    
//    override func preferredStatusBarStyle() -> UIStatusBarStyle {
//        return UIStatusBarStyle.LightContent
//    }

    private func getTableViewInset() -> CGFloat {
        return topBar.frame.height
    }
    
    func onListItemsChangedSection(tableViewListItems: [TableViewListItem]) {
        Providers.listItemsProvider.update(tableViewListItems.map{$0.listItem}, remote: true, successHandler{result in
        })
    }
    
    /**
    Update price labels (total, done) using state in provider
    */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {
        if let currentList = self.currentList {
            Providers.listItemsProvider.listItems(currentList, sortOrderByStatus: .Todo, fetchMode: listItemsFetchMode, successHandler{listItems in
                self.pricesView.setTotalPrice(listItems.totalPriceTodoAndCart, animated: false)
                // The reason we exclude stash from total price is that when user is in the store they want to know what they will have to pay at the end (if they buy the complete list - this may not be necessarily the case though), which is todo + stash
                self.pricesView.setDonePrice(listItems.totalPrice(.Done), animated: false)
            })
        }
    }
    
    private func addItem(listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {

        if let currentList = self.currentList {
            Providers.listItemsProvider.add(listItemInput, list: currentList, order: nil, possibleNewSectionOrder: ListItemStatusOrder(status: .Todo, order: listItemsTableViewController.sections.count), successHandler {[weak self] savedListItem in
                self?.onListItemAddedToProvider(savedListItem)
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }

    }
    
    
    private func onListItemAddedToProvider(savedListItem: ListItem, notifyRemote: Bool = true) {
        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
        listItemsTableViewController.updateOrAddListItem(savedListItem, status: .Todo, increment: true, scrollToSelection: true, notifyRemote: notifyRemote)
        updatePrices(.MemOnly)
        updateEmptyView()
    }
    
    // Note: don't use this to reorder sections, this doesn't update section order
    // Note: concerning status - this only updates the .Todo related data (quantity, order). This means quantity and order of possible items in .Done or .Stash is not affected
    private func updateItem(listItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            if let updatingListItem = self.updatingListItem {
                
                let category = listItem.product.category.copy(name: listItemInput.category, color: listItemInput.categoryColor)
                let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price, category: category, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand) // possible product update

                func onHasSection(section: Section) {
                    let listItem = ListItem(
                        uuid: updatingListItem.uuid,
                        product: product,
                        section: section,
                        list: currentList,
                        note: listItemInput.note,
                        statusOrder: ListItemStatusOrder(status: .Todo, order: updatingListItem.order(.Todo)),
                        statusQuantity: ListItemStatusQuantity(status: .Todo, quantity: listItemInput.quantity)
                    )
                    
                    Providers.listItemsProvider.update([listItem], remote: true, successHandler {[weak self] in
                        self?.listItemsTableViewController.updateListItem(listItem, status: .Todo, notifyRemote: true)
                        self?.updatePrices(.MemOnly)
                        handler?()
                    })
                }
                
                if listItem.section.name != listItemInput.section { // if user changed the section we have to see if a section with new name exists already (explanation below)
                    
                    Providers.sectionProvider.loadSection(listItemInput.section, list: listItem.list, handler: successHandler{sectionMaybe in
                        // if a section with name exists already, use existing section, otherwise create a new one
                        // Note we don't update here the section of the editing list item, this would mean that we change the section name for existing section, e.g. we change section of "tomatoes" from "vegatables" to "fruits", if we just update the section this means all the items which are in "vegetables" will be now in "fruits" and this is not what we want.
                        let section: Section = {
                            if let section = sectionMaybe {
                                return section
                            } else {
                                return updatingListItem.section.copy(uuid: NSUUID().UUIDString, name: listItemInput.section)
                            }
                        }()
                        onHasSection(section)
                    })
                } else { // if the user hasn't entered a different section name, there's no need to load the section from db, just use the existing one
                    onHasSection(listItem.section)
                }
                
            } else {
                print("Error: Invalid state: trying to update list item without updatingListItem")
            }

        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }

    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        Providers.listItemsProvider.remove(tableViewListItem.listItem, remote: true, successHandler{[weak self] in
            self?.updateEmptyView()
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
                    self.listItemsTableViewController.clearPendingSwipeItemIfAny(true) {
                        doneViewController.list = self.currentList
                        doneViewController.backgroundColor = self.listItemsTableViewController.view.backgroundColor
                    }
                }
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

    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let list = currentList {

            // TODO save "group list item" don't desintegrate group immediatly
            
            Providers.listItemsProvider.addGroupItems(group, list: list, successHandler{[weak self] addedListItems in
                if let list = self?.currentList {
                    self?.initWithList(list) // refresh list items
                } else {
                    print("Warn: Group was added but couldn't reinit list, self or currentList is not set: self: \(self), currentlist: \(self?.currentList)")
                }
                onFinish?()
                
            })
        } else {
            print("Error: Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onAddProduct(product: Product) {
        if let list = currentList {
            Providers.listItemsProvider.addListItem(product, sectionName: product.category.name, quantity: 1, list: list, note: nil, order: nil, successHandler {[weak self] savedListItem in
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
    
    // MARK: - EditSectionViewControllerDelegate
    
    func onSectionUpdated(section: Section) {
        // use table view of controller which is showing
        let tableView: UITableView = sectionsTableViewController?.tableView ?? listItemsTableViewController.tableView
        topEditSectionControllerManager?.tableView = tableView
        topEditSectionControllerManager?.expand(false)
        
        if let controller = sectionsTableViewController {
            controller.updateSection(section)
        }
        listItemsTableViewController.updateSection(section)
        
        // because updateSection/reloadData listItemsTableViewController sets back expanded to true, set correct state. If sectionsTableViewController is not visible it means it's expanded.
//        listItemsTableViewController.sectionsExpanded = sectionsTableViewController == nil
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
        setReorderSections(sectionsTableViewController == nil)
    }
    
    private func setReorderSections(reorderSections: Bool) {

        if !lockToggleSectionsTableView {
            lockToggleSectionsTableView = true
            
            if reorderSections { // show reorder sections table view
                
                listItemsTableViewController.setAllSectionsExpanded(!listItemsTableViewController.sectionsExpanded, animated: true, onComplete: { // collapse - add sections table view
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewController()
                    
                    sectionsTableViewController.cellBgColor = self.listItemsTableViewController.headerBGColor
                    sectionsTableViewController.selectedCellBgColor = self.expandCollapseButton.backgroundColor
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
                    
                    self.expandCollapseButton.setExpanded(true)
                })
                
            } else { // show normal table view
                
                if let sectionsTableViewController = sectionsTableViewController { // expand while in collapsed state (sections tableview is set) - remove sections table view
                    
                    sectionsTableViewController.setCellHeight(30, animated: true)
                    sectionsTableViewController.setEdit(false, animated: true) {
                        sectionsTableViewController.removeFromParentViewController()
                        sectionsTableViewController.view.removeFromSuperview()
                        self.sectionsTableViewController = nil
                        self.listItemsTableViewController.setAllSectionsExpanded(!self.listItemsTableViewController.sectionsExpanded, animated: true)
                        self.lockToggleSectionsTableView = false
                        
                        self.expandCollapseButton.setExpanded(false)
                    }
                } else {
                    // we are already in normal state (sections tableview is not set) - do nothing
                    lockToggleSectionsTableView = false
                }
            }
        }
    }
    
    // MARK: - ReorderSectionTableViewControllerDelegate
    
    func onSectionsUpdated() {
        if let list = currentList {
            udpateListItems(list) {
            }
        } else {
            print("Error: ViewController.onSectionOrderUpdated: Invalid state, reordering sections and no list")
        }
    }
    
    func onSectionSelected(section: Section) {
        onSectionSelectedShared(section)
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
            SizeLimitChecker.checkListItemsSizeLimit(listItemsTableViewController.items.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.Add)
                }
            }
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
    
    // MARK: - ExpandCollapseButtonDelegate
    
    func onExpandButton(expanded: Bool) {
        toggleReorderSections()
    }
    
    // MARK: - Websocket
    
    func onWebsocketListItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[ListItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Update:
                    listItemsTableViewController.updateListItems(notification.obj, status: .Todo, notifyRemote: false)
                    updatePrices(.MemOnly)
                    
                default: print("Error: ViewController.onWebsocketUpdateListItems: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: ViewController.onWebsocketAddListItems: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketListItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ListItem>> {
            if let notification = info[WSNotificationValue] {
                
                let listItem = notification.obj
                
                switch notification.verb {
                case .Add:
                    onListItemAddedToProvider(listItem, notifyRemote: false)
                    
                case .Update:
                    listItemsTableViewController.updateListItem(listItem, status: .Todo, notifyRemote: false)
                    updatePrices(.MemOnly)
                    
                case .Delete:
                    listItemsTableViewController.removeListItem(listItem, animation: .Bottom)
                    updatePrices(.MemOnly)
                }
            } else {
                print("Error: ViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketSection(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Section>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    // There's no direct add of section
//                case .Add:
//                    addProductUI(notification.obj)
                case .Update:
                    // TODO what do we do here, if we reload the list (section order can be updated, not only name) can conflict with current state e.g. if user is editing or just swiping and item. For now do nothing - user will see updated section the next time list it's loaded
//                    updateProductUI(notification.obj)
                    print("Warn: TODO websocket section update")
                case .Delete:
                    // TODO similar to .Update comment
                    print("Warn: TODO websocket section delete")
                default: print("Error: ViewController.onWebsocketSection: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: ViewController.onWebsocketUpdateListItem: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketAddListItems: no userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    // TODO!! update all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                case .Delete:
                    // TODO!! delete all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                print("Error: ViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
}