//
//  ListItemsController.swift
//  shoppin
//
//  Created by ischuetz on 30/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import SwiftValidator
import ChameleonFramework
import QorumLogs

class ListItemsController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, QuickAddDelegate, ReorderSectionTableViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate, ExpandCollapseButtonDelegate, UIGestureRecognizerDelegate
    //    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    // TODO put next vars in a struct
    //    private var updatingListItem: ListItem?
    private var updatingSelectedCell: UITableViewCell?
    
    var listItemsTableViewController: ListItemsTableViewController!
    
    private var currentTopController: UIViewController?
    
    @IBOutlet weak var expandCollapseButton: ExpandCollapseButton!
    
//    @IBOutlet weak var listNameView: UILabel!
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    private let transition = BlurBubbleTransition()
    
    var titleLabel: UILabel?
    
    var expandDelegate: Foo?
    
    var currentList: List? {
        didSet {
            updatePossibleList()
        }
    }
    var onViewWillAppear: VoidFunction?
    
    
    var status: ListItemStatus {
        fatalError("override")
    }
    
    var tableViewBottomInset: CGFloat {
        return 0
    }
    
    private var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    private var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()
    
    var emptyView: UIView {
        fatalError("override")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableViewController()
        
        setEditing(false, animated: false, tryCloseTopViewController: false)
        
        initTitleLabel()
        
        expandCollapseButton.delegate = self
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        topBar.delegate = self
        
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onListRemovedNotification:", name: Notification.ListRemoved.rawValue, object: nil)
        
        // websocket
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItems:", name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketListItem:", name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketSection:", name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProductCategory:", name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketList:", name: WSNotificationName.List.rawValue, object: nil)
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
            setEmptyViewVisible(false, animated: false)
            clearPossibleUndo()
            topBar.setLeftButtonIds([])
            topBar.setRightButtonIds([])
            // Clear list item memory cache when we leave controller. This is not really necessary but just "in case". The list item memory cache is there to smooth things *inside* a list, that is transitions between todo/done/stash, and adding/incrementing items. Causing a db-reload when we load the controller is totally ok.
            Providers.listItemsProvider.invalidateMemCache()
        }
        
        topBar.positionTitleLabelLeft(expanding, animated: true, withDot: true, heightConstraint: topBarHeightConstraint)
    }
    
    func setThemeColor(color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.whiteColor()
        
        expandCollapseButton.strokeColor = UIColor.blackColor()
    }
    
    private func updatePossibleList() {
        if let list = self.currentList {
            //            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }
    
    func setEmptyViewVisible(visible: Bool, animated: Bool) {
        fatalError("override")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        onViewWillAppear?()
        onViewWillAppear = nil
        
//        updatePrices(.First)
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("onEmptyListViewTap:"))
        emptyView.addGestureRecognizer(tapRecognizer)
    }
    
    func onEmptyListViewTap(sender: UITapGestureRecognizer) {
        toggleTopAddController() // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }

    
    private func initWithList(list: List) {
        topBar.title = topBarTitle(list)
        udpateListItems(list)
    }
    
    func topBarTitle(list: List) -> String {
        return list.name
    }
    
    private func udpateListItems(list: List, onFinish: VoidFunction? = nil) {
        Providers.listItemsProvider.listItems(list, sortOrderByStatus: status, fetchMode: .MemOnly, successHandler{[weak self] listItems in guard let weakSelf = self else {return}
            weakSelf.listItemsTableViewController.setListItems(listItems.filter{$0.hasStatus(weakSelf.status)})
            weakSelf.onTableViewChangedQuantifiables()
            onFinish?()
        })
    }
    
    // buttons for left nav bar side in default state (e.g. not while the top controller is open)
    func setDefaultLeftButtons() {
        topBar.setLeftButtonIds([.Edit])
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
            
            setDefaultLeftButtons()
            
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
        
        listItemsTableViewController.status = status
        listItemsTableViewController.scrollViewDelegate = self
        listItemsTableViewController.listItemsTableViewDelegate = self
        listItemsTableViewController.listItemsEditTableViewDelegate = self
        
        let navbarHeight = topBar.frame.height
        let topInset = navbarHeight
        let bottomInset: CGFloat = tableViewBottomInset + 10 // 10 - show a little empty space between the last item and the prices view
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
        listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .Bottom)
        onTableViewChangedQuantifiables()
        onFinish()
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
            
            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in guard let weakSelf = self else {return}
                let targetStatus: ListItemStatus = {
                    switch weakSelf.status {
                    case .Todo: return .Done
                    case .Done: return .Todo
                    case .Stash: return .Todo
                    }
                }()
                Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: tableViewListItem.listItem.list, status1: weakSelf.status, status: targetStatus, remote: true, weakSelf.successHandler {
                        weakSelf.onTableViewChangedQuantifiables()
                })
            })
        }
    }
    
    // Callen when table view contents affecting list items quantity/price is modified
    func onTableViewChangedQuantifiables() {
        updateQuantifiables()
        
        // update empty view
        setEmptyViewVisible(listItemsTableViewController.items.isEmpty, animated: true)
    }
    
    func updateQuantifiables() {
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        // revert list item operation
        let srcStatus: ListItemStatus = {
            switch status {
            case .Todo: return .Done
            case .Done: return .Todo
            case .Stash: return .Todo
            }
        }()
        
        Providers.listItemsProvider.switchStatus([tableViewListItem.listItem], list: tableViewListItem.listItem.list, status1: srcStatus, status: status, remote: true, successHandler{[weak self] in
            QL1("Undo successful")
            self?.listItemsTableViewController.tableView.reloadData()
            self?.onTableViewChangedQuantifiables()
        })
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        onSectionSelected(section.section)
    }
    
    func onIncrementItem(tableViewListItem: TableViewListItem, delta: Int) {
        Providers.listItemsProvider.increment(tableViewListItem.listItem, delta: delta, remote: true, successHandler{[weak self] in guard let weakSelf = self else {return}
            // TODO do this in  the provider, provider should return incremented item
            let incremented: ListItem = tableViewListItem.listItem.increment(ListItemStatusQuantity(status: weakSelf.status, quantity: delta))
            self?.listItemsTableViewController.updateOrAddListItem(incremented, status: weakSelf.status, increment: false, notifyRemote: false)
            self?.onTableViewChangedQuantifiables()
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
    
    func onListItemsOrderChangedSection(tableViewListItems: [TableViewListItem]) {
        fatalError("override")
    }
    
    /**
     Update price labels (total, done) using state in provider
     */
    func updatePrices(listItemsFetchMode: ProviderFetchModus = .Both) {
        // override
        QL3("No override for updatePrices")
    }
    
    private func addItem(listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        
        if let currentList = self.currentList {
            Providers.listItemsProvider.add(listItemInput, status: status, list: currentList, order: nil, possibleNewSectionOrder: ListItemStatusOrder(status: status, order: listItemsTableViewController.sections.count), successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
                self?.onListItemAddedToProvider(savedListItem, status: weakSelf.status)
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }
        
    }
    
    private func onListItemAddedToProvider(savedListItem: ListItem, status: ListItemStatus, notifyRemote: Bool = true) {
        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
        listItemsTableViewController.updateOrAddListItem(savedListItem, status: status, increment: true, scrollToSelection: true, notifyRemote: notifyRemote)
        onTableViewChangedQuantifiables()
//        updatePrices(.MemOnly)
    }
    
    // Note: don't use this to reorder sections, this doesn't update section order
    // Note: concerning status - this only updates the current status related data (quantity, order). This means quantity and order of possible items in the other status is not affected
    private func updateItem(updatingListItem: ListItem, listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        if let currentList = self.currentList {
            
            let category = updatingListItem.product.category
            let product = Product(uuid: updatingListItem.product.uuid, name: listItemInput.name, price: listItemInput.price, category: category, baseQuantity: listItemInput.baseQuantity, unit: listItemInput.unit, brand: listItemInput.brand, store: listItemInput.store) // possible product update
            
            func onHasSection(section: Section) {
                let listItem = ListItem(
                    uuid: updatingListItem.uuid,
                    product: product,
                    section: section,
                    list: currentList,
                    note: listItemInput.note,
                    statusOrder: ListItemStatusOrder(status: status, order: updatingListItem.order(status)),
                    statusQuantity: ListItemStatusQuantity(status: status, quantity: listItemInput.quantity)
                )
                
                Providers.listItemsProvider.update([listItem], remote: true, successHandler {[weak self] in guard let weakSelf = self else {return}
                    self?.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
//                    self?.updatePrices(.MemOnly)
                    self?.onTableViewChangedQuantifiables()
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
            self?.onTableViewChangedQuantifiables()
        })
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
            
            Providers.listItemsProvider.addGroupItems(group, status: status, list: list, successHandler{[weak self] addedListItems in
                if let list = self?.currentList {
                    self?.initWithList(list) // refresh list items
                } else {
                    QL3("Group was added but couldn't reinit list, self or currentList is not set: self: \(self), currentlist: \(self?.currentList)")
                }
                onFinish?()
                
                })
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onAddProduct(product: Product) {
        if let list = currentList {
            Providers.listItemsProvider.addListItem(product, status: status, sectionName: product.category.name, sectionColor: product.category.color, quantity: 1, list: list, note: nil, order: nil, successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
                weakSelf.onListItemAddedToProvider(savedListItem, status: weakSelf.status)
            })
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
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

    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
        if controller is QuickAddViewController || controller is AddEditListItemViewController {
            view.frame.origin.y = CGRectGetHeight(topBar.frame)
        }
    }
    
    func onExpandableClose() {
//        topBar.setBackVisible(false)
        setDefaultLeftButtons()
        topBar.setRightButtonModels([TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)])
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
        
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.Back)
    }
    
    func onTopBarTitleTap() {
        // override
    }
    
    func back() {
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
            setDefaultLeftButtons()
            topBar.setRightButtonIds([.ToggleOpen])
        }
    }
    
    // MARK: - ExpandCollapseButtonDelegate
    
    func onExpandButton(expanded: Bool) {
        toggleReorderSections()
    }
    
    
    // MARK: - Notification
    
    func onListRemovedNotification(note: NSNotification) {
        guard let info = note.userInfo as? Dictionary<String, String> else {QL4("Invalid info: \(note)"); return}
        guard let listUuid = info[NotificationKey.list] else {QL4("No list uuid: \(info)"); return}
        guard let currentList = currentList else {QL3("No current list, ignoring list removed notification."); return}
        
        // If we happen to be showing a list that was just removed (e.g. because user removed an inventory the list was associated to), exit.
        // In this case (opposed to websocket notification) we don't show an alert, as this is triggered by an action of the user in the same device and user should know it was removed.
        if listUuid == currentList.uuid {
            back()
        }
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
                                self?.back()
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
                    // TODO!!!!! websocket add/update must send status also
                    onListItemAddedToProvider(listItem, status: .Todo, notifyRemote: false)
                    
                case .Update:
                    
                    // TODO!!!!! websocket add/update must send status also
                    listItemsTableViewController.updateListItem(listItem, status: .Todo, notifyRemote: false)
                    onTableViewChangedQuantifiables()
                    
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
                    onTableViewChangedQuantifiables()
                    
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
                    // TODO!!!!! websocket add/update must send status also
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
                    // TODO!!!!! websocket add/update must send status also
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