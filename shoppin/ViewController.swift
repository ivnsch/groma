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
import QorumLogs

class ViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, QuickAddDelegate, ReorderSectionTableViewControllerDelegate, CartViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate, ExpandCollapseButtonDelegate
//    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller

    // TODO put next vars in a struct
//    private var updatingListItem: ListItem?
    private var updatingSelectedCell: UITableViewCell?
    
    private var listItemsTableViewController: ListItemsTableViewController!

    private var currentTopController: UIViewController?
    
    @IBOutlet weak var expandCollapseButton: ExpandCollapseButton!
    
    @IBOutlet weak var pricesView: PricesView!
    
    @IBOutlet weak var stashView: StashView!
    
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
    private var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()

        setEditing(false, animated: false, tryCloseTopViewController: false)
        
        initTitleLabel()

        expandCollapseButton.delegate = self

        topQuickAddControllerManager = initTopQuickAddControllerManager()
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        topBar.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItems:", name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItem:", name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSection:", name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketList:", name: WSNotificationName.List.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: 290, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            return controller
        }
        manager.delegate = self
        return manager
    }

    private func initEditSectionControllerManager() -> ExpandableTopViewController<EditSectionViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<EditSectionViewController> = ExpandableTopViewController(top: top, height: 70, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
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
        topBar.dotColor = color
        view.backgroundColor = UIColor.whiteColor()
        
        expandCollapseButton.strokeColor = UIColor.blackColor()

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
    
    // MARK:
    
    private func toggleTopAddController(rotateTopBarButton: Bool = true) {
        
        clearPossibleUndo()
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || topEditSectionControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            topQuickAddControllerManager?.controller?.onClose()
            topEditSectionControllerManager?.expand(false)
            topEditSectionControllerManager?.controller?.onClose()

            topBar.setLeftButtonIds([.Edit])

            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
            }

            
            if editing {
                // if we are in edit mode, show the reorder sections button again (we hide it when we open the top controller)
                expandCollapseButton.setHiddenAnimated(false)
            }
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            topQuickAddControllerManager?.controller?.initContent()

            topBar.setLeftButtonIds([])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))])
            }
            
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
            topQuickAddControllerManager?.controller?.onClose()
            topEditSectionControllerManager?.controller?.onClose()
        }
        
        expandCollapseButton.setHiddenAnimated(!editing)
        
        if !editing {
            // in case we are in reorder sections mode, come back to normal. This is an edit specific mode.
            setReorderSections(false)
            expandCollapseButton.setHiddenAnimated(true)
            
            topBar.setRightButtonIds([.ToggleOpen])
        }
        
        listItemsTableViewController.setEditing(editing, animated: animated)


        listItemsTableViewController.cellMode = editing ? .Increment : .Note
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
//    func itemsChanged() {
//        self.initList()
//    }
    
//    var refreshControl: UIRefreshControl?
    private func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewController()
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.status = .Todo
        listItemsTableViewController.scrollViewDelegate = self
        listItemsTableViewController.listItemsTableViewDelegate = self
        listItemsTableViewController.listItemsEditTableViewDelegate = self
        
        let navbarHeight = topBar.frame.height
        let topInset = navbarHeight
        let bottomInset: CGFloat = pricesView.frame.height + 10 // 10 - show a little empty space between the last item and the prices view
        listItemsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
        listItemsTableViewController.tableView.topOffset = -listItemsTableViewController.tableView.inset.top
        listItemsTableViewController.enablePullToAdd()
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        clearPossibleUndo()
    }
    
    func clearPossibleUndo() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    // MARK: - ListItemsTableViewDelegate
    
    func onTableViewScroll(scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(-64, topBar: topBar, scrollView: scrollView)
    }
    
    func onPullToAdd() {
        toggleTopAddController(false) // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }
    
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
            updatingSelectedCell = listItemsTableViewController.tableView.cellForRowAtIndexPath(indexPath)

            topQuickAddControllerManager?.expand(true)
            topBar.setRightButtonModels([
                TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
            ])
            
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: tableViewListItem.listItem))
            
        } else {

            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in
                // "fake" update of price labels - the update has not been submitted yet to provider, since we just opened the cell and the item is submitted only after "undo" is cleared
                // we do this for simplicity purposes, if we submitted on cell open we would have to revert the update on "undo".
                // Note that after item is submitted we fetch from provider and update the labels again, to "be sure" (this time without animation). There's no real reason for this, just in case.
                // Note also callback onFinish - when there's another undo item it will be submitted automatically, which triggers a provider and price view update
                // so we have to ensure our fake update comes after this possible update, otherwise it's overwritten.
                let updatedPrice = (self?.pricesView.donePrice ?? 0) + tableViewListItem.listItem.totalPrice(.Todo)
                let updatedQuantity = (self?.pricesView.cartQuantity ?? 0) + 1
                self?.pricesView.setDonePrice(updatedPrice, animated: true)
                self?.pricesView.cartQuantity = updatedQuantity
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
        Providers.listItemsProvider.increment(tableViewListItem.listItem, delta: delta, remote: true, successHandler{[weak self] in
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
        Providers.listItemsProvider.updateListItemsTodoOrder(tableViewListItems.map{$0.listItem}, remote: true, successHandler{result in
        })
    }
    
    /**
    Update price labels (total, done) using state in provider
    */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {
        if let currentList = self.currentList {
            Providers.listItemsProvider.listItems(currentList, sortOrderByStatus: .Todo, fetchMode: listItemsFetchMode, successHandler{[weak self] listItems in
                self?.pricesView.setTotalPrice(listItems.totalPriceTodoAndCart, animated: false)
                // The reason we exclude stash from total price is that when user is in the store they want to know what they will have to pay at the end (if they buy the complete list - this may not be necessarily the case though), which is todo + stash
                self?.pricesView.setDonePrice(listItems.totalPrice(.Done), animated: false)
                self?.pricesView.cartQuantity = listItems.filterDone().count
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
    private func updateItem(updatingListItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            let category = updatingListItem.product.category
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
            
            if updatingListItem.section.name != listItemInput.section { // if user changed the section we have to see if a section with new name exists already (explanation below)
                
                Providers.sectionProvider.loadSection(listItemInput.section, list: updatingListItem.list, handler: successHandler{sectionMaybe in
                    // if a section with name exists already, use existing section, otherwise create a new one
                    // Note we don't update here the section of the editing list item, this would mean that we change the section name for existing section, e.g. we change section of "tomatoes" from "vegatables" to "fruits", if we just update the section this means all the items which are in "vegetables" will be now in "fruits" and this is not what we want.
                    let section: Section = {
                        if let section = sectionMaybe {
                            return section
                        } else {
                            return updatingListItem.section.copy(uuid: NSUUID().UUIDString, name: listItemInput.section, color: listItemInput.sectionColor)
                        }
                    }()
                    onHasSection(section)
                })
            } else { // if the user hasn't entered a different section name, there's no need to load the section from db, just use the existing one. Update possible color change.
                let updatedSection = updatingListItem.section.copy(color: listItemInput.sectionColor)
                onHasSection(updatedSection)
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
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
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
            Providers.listItemsProvider.addListItem(product, sectionName: product.category.name, sectionColor: product.category.color, quantity: 1, list: list, note: nil, order: nil, successHandler {[weak self] savedListItem in
                self?.onListItemAddedToProvider(savedListItem)
            })
        } else {
            print("Error: Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        
        func onEditListItem(input: ListItemInput, editingListItem: ListItem) {
            // set normal (.Note) mode in advance - with updateItem the table view calls reloadData, but the change to .Note mode happens after (in setEditing), which doesn't reload the table so the cells will appear without notes.
            listItemsTableViewController.cellMode = .Note
            updateItem(editingListItem, listItemInput: input) {[weak self] in
                self?.setEditing(false, animated: true, tryCloseTopViewController: true)
            }
        }
        
        func onAddListItem(input: ListItemInput) {
            addItem(input, successHandler: nil)
        }
        
        if let editingListItem = editingItem as? ListItem {
            onEditListItem(input, editingListItem: editingListItem)
        } else {
            if editingItem == nil {
                onAddListItem(input)
            } else {
                QL4("Cast didn't work: \(editingItem)")
            }
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
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }

    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
            TopBarButtonModel(buttonId: .Add),
            TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))
        ])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
        topBar.setRightButtonModels([
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
        topEditSectionControllerManager?.controller?.onClose()
        
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
                    
                    sectionsTableViewController.sections = self.listItemsTableViewController.sections
                    sectionsTableViewController.delegate = self
                    
                    sectionsTableViewController.onViewDidLoad = {
                        let navbarHeight = self.topBar.frame.height
                        let topInset = navbarHeight
                        
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
                    
                    sectionsTableViewController.setCellHeight(Constants.listItemsTableViewHeaderHeight, animated: true)
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
            view.frame.origin.y = CGRectGetHeight(topBar.frame)
        }
    }
    
    func onExpandableClose() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonIds([.Edit])
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
        
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.Back)
    }
    
    func onTopBarTitleTap() {
        onExpand(false)
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
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
        case .ToggleOpen:
            toggleTopAddController()
        case .Edit:
            clearPossibleUndo()
            let editing = !self.listItemsTableViewController.editing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        default: QL4("Not handled: \(buttonId)")
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
    
    func onWebsocketList(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let listUuid = notification.obj
                switch notification.verb {
                case .Delete:
                    if let list = currentList {
                        if list.uuid == listUuid {
                            AlertPopup.show(title: "List deleted", message: "The list \(list.name) was deleted from another device. Returning to lists.", controller: self, onDismiss: {[weak self] in
                                self?.navigationController?.popViewControllerAnimated(true)
                            })
                        } else {
                            QL1("Websocket: List items controller received a notification to delete a list which is not the one being currently shown")
                        }
                    } else {
                        QL4("Websocket: Can't process delete list notification because there's no list set")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        }
    }
    
    // This is called on batch list item update, which is used when reordering list items
    func onWebsocketListItems(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteListItemsReorderResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Order:
                    updatePossibleList() // reload list
                    updatePrices(.MemOnly)
                    
                default: print("Error: ViewController.onWebsocketUpdateListItems: Not handled: z\(notification.verb)")
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

                default: QL4("Not handled verb: \(notification.verb)")
                }
            } else {
                print("Error: ViewController.onWebsocketUpdateListItem: no value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let itemUuid = notification.obj
                
                switch notification.verb {
                case .Delete:
                    listItemsTableViewController.removeListItem(itemUuid)
                    updatePrices(.MemOnly)
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<ItemIncrement>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case WSNotificationVerb.Increment:
                    let incr = notification.obj
                    listItemsTableViewController.incrementListItem(incr, status: .Todo, notifyRemote: false)
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
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
                case .Update:
                    // NOTE: this doesn't update order. Update reorder would require to reload the table view and this can e.g. revert undo cells or interfere with current action like swiping an item. So to update order the user has to reopen the list.
                    listItemsTableViewController.updateSection(notification.obj)

                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("no value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    listItemsTableViewController.removeSection(notification.obj)
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    listItemsTableViewController.updateProduct(notification.obj, status: .Todo)
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                print("Error: ViewController.onWebsocketProduct: no value")
            }
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let productUuid = notification.obj
                switch notification.verb {
                case .Delete:
                    listItemsTableViewController.removeListItemReferencingProduct(productUuid)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }

    func onWebsocketProductCategory(note: NSNotification) {
        
        // category udpate not relevant for list items since items show only section, not category. The add/edit has also only section
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Delete:
                    let categoryUuid = notification.obj
                    listItemsTableViewController.removeListItemsReferencingCategory(categoryUuid)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        } else {
            print("Error: ViewController.onWebsocketProduct: no userInfo")
        }
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        updatePossibleList()
    }
}