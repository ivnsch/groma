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

class ListItemsController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, QuickAddDelegate, ReorderSectionTableViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate, UIGestureRecognizerDelegate
    //    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    private let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    
    weak var listItemsTableViewController: ListItemsTableViewController!
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    weak var expandDelegate: Foo?
    
    var currentList: List? {
        didSet {
            updatePossibleList()
        }
    }
    
    // TODO rename these blocks, which are meant to be executed only once after loading accordingly e.g. onViewWillAppearOnce
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    var status: ListItemStatus {
        fatalError("override")
    }
    
    var isPullToAddEnabled: Bool {
        return true
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
        
        topQuickAddControllerManager = initTopQuickAddControllerManager()
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        topBar.delegate = self

        
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onListRemovedNotification(_:)), name: Notification.ListRemoved.rawValue, object: nil)
        
        // websocket
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketListItems(_:)), name: WSNotificationName.ListItems.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketListItem(_:)), name: WSNotificationName.ListItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketSection(_:)), name: WSNotificationName.Section.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketProduct(_:)), name: WSNotificationName.Product.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketProductCategory(_:)), name: WSNotificationName.ProductCategory.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onIncomingGlobalSyncFinished(_:)), name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListItemsController.onWebsocketList(_:)), name: WSNotificationName.List.rawValue, object: nil)
    }

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    deinit {
        QL1("Deinit list items controller")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.itemType = .ProductForList
            controller.list = self?.currentList
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
    }
    
    func onExpand(expanding: Bool) {
        if !expanding {
            clearPossibleNotePopup()
            topQuickAddControllerManager?.controller?.removeFromParentViewControllerWithView()
            setEmptyUI(false, animated: false)
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels(rightButtonsClosing())
            // Clear list item memory cache when we leave controller. This is not really necessary but just "in case". The list item memory cache is there to smooth things *inside* a list, that is transitions between todo/done/stash, and adding/incrementing items. Causing a db-reload when we load the controller is totally ok.
            Providers.listItemsProvider.invalidateMemCache()
        }
        
        topBar.positionTitleLabelLeft(expanding, animated: true, withDot: true, heightConstraint: topBarHeightConstraint)
    }
    
    func setThemeColor(color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.whiteColor()
    }
    
    private func updatePossibleList() {
        if let list = self.currentList {
            //            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }
    
    func setEmptyUI(empty: Bool, animated: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            setDefaultLeftButtons()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        onViewWillAppear?()
        onViewWillAppear = nil
        
//        updatePrices(.First)
        
        // TODO custom empty view, put this there
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ListItemsController.onEmptyListViewTap(_:)))
        emptyView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
     
        toggleButtonRotator.reset(listItemsTableViewController.tableView, topBar: topBar)

        onViewDidAppear?()
        onViewDidAppear = nil
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
            weakSelf.onGetListItems(listItems)
            onFinish?()
        })
    }
    
    func onGetListItems(listItems: [ListItem]) {
        let i = listItems.filter{$0.hasStatus(status)}
        QL2("status: \(status), items: \(i)")
        onTableViewChangedQuantifiables()
    }
    
    // buttons for left nav bar side in default state (e.g. not while the top controller is open)
    func setDefaultLeftButtons() {
        if listItemsTableViewController.items.isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.Edit])
        }
    }
    
    func clearPossibleNotePopup() {
        if let popup = view.viewWithTag(ViewTags.NotePopup) {
            popup.removeFromSuperview()
        }
    }
    
    // MARK:
    
    // returns: is now open?
    func toggleTopAddController(rotateTopBarButton: Bool = true) -> Bool {
        
        clearPossibleUndo()
        
        clearPossibleNotePopup()
        
        // if any top controller is open, close it
        if topQuickAddControllerManager?.expanded ?? false || topEditSectionControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.expand(false)
            toggleButtonRotator.enabled = true
            topQuickAddControllerManager?.controller?.onClose()
            topEditSectionControllerManager?.expand(false)
            topEditSectionControllerManager?.controller?.onClose()
            
            setDefaultLeftButtons()
            
            if rotateTopBarButton {
                topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
            }
        
            return false
            
        } else { // if there's no top controller open, open the quick add controller
            topQuickAddControllerManager?.expand(true)
            toggleButtonRotator.enabled = false
            topQuickAddControllerManager?.controller?.initContent()
            
            topBar.setLeftButtonIds([])
            
            if rotateTopBarButton {
                topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
            }
            
            // in case we are in reorder sections mode, come back to normal. This mode doesn't make sense while adding list items as we can't see the list items.
            setReorderSections(false)
            
            return true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        clearPossibleUndo()
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated)
        
        clearPossibleNotePopup()
        
        if editing == false {
            view.endEditing(true)
        }
        
        if tryCloseTopViewController {
            topQuickAddControllerManager?.expand(false)
            toggleButtonRotator.enabled = true
            topQuickAddControllerManager?.controller?.onClose()
            topEditSectionControllerManager?.controller?.onClose()
        }
        
        if !editing {
            // in case we are in reorder sections mode, come back to normal. This is an edit specific mode.
            setReorderSections(false)
         
            setDefaultLeftButtons()
            topBar.setRightButtonModels(rightButtonsDefault())
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
        if isPullToAddEnabled {
            listItemsTableViewController.enablePullToAdd()
        }
        
        listItemsTableViewController.cellSwipeDirection = {
            switch self.status {
            case .Todo: return .Right
            case .Done: return .Left
            case .Stash: return .Left
            }
        }()
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
        if self.editing { // open quick add in edit mode
            topQuickAddControllerManager?.expand(true)
            topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
            
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: tableViewListItem.listItem, currentStatus: status))
            
        } else { // switch list item

            // TODO!!!! when receive switch status via websocket we will *not* show undo (undo should be only for the device doing the switch) but submit immediately this means:
            // 1. call switchstatus like here, 2. switch status in provider updates status/order, maybe deletes section, etc 3. update the table view - swipe the item and maybe delete section(this should be similar to calling onListItemClear except the animation in this case is not swipe, but that should be ok?)
            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in guard let weakSelf = self else {return}
                let targetStatus: ListItemStatus = {
                    switch weakSelf.status {
                    case .Todo: return .Done
                    case .Done: return .Todo
                    case .Stash: return .Todo
                    }
                }()
                
                // NOTE: For the provider the whole state is updated here - including possible section removal (if the current undo list item is the last one in the section) and the order field update of possible following sections. This means that the contents of the table view may be in a slightly inconsistent state with the data in the provider during the time cell is in undo (for the table view the section is still there, for the provider it's not). This is fine as the undo state is just a UI thing (local) and it should be cleared as soon as we try to start a new action (add, edit, delete, reorder etc) or go to the cart/stash.
                Providers.listItemsProvider.switchStatus(tableViewListItem.listItem, list: tableViewListItem.listItem.list, status1: weakSelf.status, status: targetStatus, orderInDstStatus: nil, remote: true, weakSelf.resultHandler(onSuccess: {switchedListItem in
                        weakSelf.onTableViewChangedQuantifiables()
                    }, onErrorAdditional: {result in
                        weakSelf.updatePossibleList()
                    }
                ))
            })
        }
    }
    
    // Immediate swipe - websocket
    private func swipeCell(listItemUuid: String) {
        if let indexPath = listItemsTableViewController.getIndexPath(listItemUuid) {
            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in
                self?.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
            })
        } else {
            QL2("Didn't find list item uuid in table view: \(listItemUuid)")
        }
    }
    
    // Callen when table view contents affecting list items quantity/price is modified
    func onTableViewChangedQuantifiables() {
        updateQuantifiables()
        
        updateEmptyUI()
    }
    
    private func updateEmptyUI() {
        setEmptyUI(listItemsTableViewController.items.isEmpty, animated: true)
    }
    
    func updateQuantifiables() {
    }
    
    func onListItemReset(tableViewListItem: TableViewListItem) {
        onListItemReset(tableViewListItem.listItem)
    }
    
    func onListItemReset(listItem: ListItem) {

        // revert list item operation
        let srcStatus: ListItemStatus = {
            switch status {
            case .Todo: return .Done
            case .Done: return .Todo
            case .Stash: return .Todo
            }
        }()
        
        func updateUI() {
            listItemsTableViewController.tableView.reloadData()
            onTableViewChangedQuantifiables()
        }
        
        Providers.listItemsProvider.switchStatus(listItem, list: listItem.list, status1: srcStatus, status: status, orderInDstStatus: listItem.order(status), remote: true, successHandler{switchedListItem in
            QL1("Undo successful")
            updateUI()
        })
    }
    
    func onSectionHeaderTap(header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        onSectionSelected(section.section)
    }
    
    func onIncrementItem(tableViewListItem: TableViewListItem, delta: Int) {
        Providers.listItemsProvider.increment(tableViewListItem.listItem, status: status, delta: delta, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
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
            topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
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
                self?.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
                handler?()
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }
        
    }
    
    private func onListItemAddedToProvider(savedListItem: ListItem, status: ListItemStatus, scrollToSelection: Bool, notifyRemote: Bool = true) {
        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
        listItemsTableViewController.updateOrAddListItem(savedListItem, status: status, increment: true, scrollToSelection: scrollToSelection, notifyRemote: notifyRemote)
        onTableViewChangedQuantifiables()
//        updatePrices(.MemOnly)
    }
    
    // Note: don't use this to reorder sections, this doesn't update section order
    // Note: concerning status - this only updates the current status related data (quantity, order). This means quantity and order of possible items in the other status is not affected
    private func updateItem(updatingListItem: ListItem, listItemInput: ListItemInput) {
        if let currentList = self.currentList {
            
            Providers.listItemsProvider.update(listItemInput, updatingListItem: updatingListItem, status: status, list: currentList, true, successHandler {[weak self] (listItem, replaced) in guard let weakSelf = self else {return}
                if replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
                    weakSelf.updatePossibleList()
                } else {
                    weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
                    //                    self?.updatePrices(.MemOnly)
                    weakSelf.onTableViewChangedQuantifiables()
                }
                weakSelf.closeTopController()
            })
        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }
        
    }
    
    func onListItemDeleted(tableViewListItem: TableViewListItem) {
        Providers.listItemsProvider.remove(tableViewListItem.listItem, remote: true, resultHandler(onSuccess: {[weak self] in
            self?.onTableViewChangedQuantifiables()
            }, onErrorAdditional: {[weak self] result in
                self?.updatePossibleList()
            }
        ))
    }
    
    // MARK: - QuickAddDelegate
    
    func onCloseQuickAddTap() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
    }
    
    func onAddGroup(group: ListItemGroup, onFinish: VoidFunction?) {
        if let list = currentList {
            
            // TODO save "group list item" don't desintegrate group immediatly
            
            
            Providers.listItemsProvider.addGroupItems(group, status: status, list: list, resultHandler(onSuccess: {[weak self] addedListItems in
                if let list = self?.currentList {
                    self?.initWithList(list) // refresh list items
                    if let firstListItem = addedListItems.first {
                        self?.listItemsTableViewController.scrollToListItem(firstListItem)
                    } else {
                        QL3("Shouldn't be here without list items")
                    }
                } else {
                    QL3("Group was added but couldn't reinit list, self or currentList is not set: self: \(self), currentlist: \(self?.currentList)")
                }
            }, onError: {[weak self] result in guard let weakSelf = self else {return}
                switch result.status {
                case .IsEmpty:
                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
                default:
                    self?.defaultErrorHandler()(providerResult: result)
                }
            }))
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onAddProduct(product: Product) {
        if let list = currentList {
            Providers.listItemsProvider.addListItem(product, status: status, sectionName: product.category.name, sectionColor: product.category.color, quantity: 1, list: list, note: nil, order: nil, storeProductInput: nil, successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
                weakSelf.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
            })
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onSubmitAddEditItem(input: ListItemInput, editingItem: Any?) {
        
        func onEditListItem(input: ListItemInput, editingListItem: ListItem) {
            // set normal (.Note) mode in advance - with updateItem the table view calls reloadData, but the change to .Note mode happens after (in setEditing), which doesn't reload the table so the cells will appear without notes.
            updateItem(editingListItem, listItemInput: input)
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
    }
    
    func onAddProductOpen() {
    }
    
    func parentViewForAddButton() -> UIView {
        return self.view
    }
    
    func addEditSectionOrCategoryColor(name: String, handler: UIColor? -> Void) {
        if let list = currentList {
            Providers.sectionProvider.sections([name], list: list, handler: successHandler {[weak self] sections in guard let weakSelf = self else {return}
                if let section = sections.first {
                    handler(section.color)
                } else {
                    // Suggestions can be sections and/or categories. If there's no section with this name (which we look up first, since we are in list items so section has higher prio) we look for a category.
                    Providers.productCategoryProvider.categoryWithNameOpt(name, weakSelf.successHandler {categoryMaybe in
                        handler(categoryMaybe?.color)
                        
                        if categoryMaybe == nil {
                            QL4("No section or category found with name: \(name) in list: \(list)") // if it's in the autocompletions it must be either the name of a section or category so we should have found one of these
                        }
                    })
                }
            })
        } else {
            QL4("Invalid state: retrieving section color for add/edit but list is not set")
        }
    }
    
    func onAddGroupOpen() {
        topBar.setBackVisible(false)
        topBar.setLeftButtonModels([])
    }
    
    func onAddGroupItemsOpen() {
        topBar.setBackVisible(true)
        topBar.setLeftButtonModels([])
    }
    
    func onRemovedSectionCategoryName(name: String) {
        updatePossibleList()
    }
    
    func onRemovedBrand(name: String) {
        updatePossibleList()
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
    
    private weak var sectionsTableViewController: ReorderSectionTableViewController?
    private var lockToggleSectionsTableView: Bool = false // prevent condition in which user presses toggle too quickly many times and sectionsTableViewController doesn't go away
    
    // Toggles between expanded and collapsed section mode. For this a second tableview with only sections is added or removed from foreground. Animates floating button.
    func toggleReorderSections() {
        setReorderSections(sectionsTableViewController == nil)
    }
    
    private func setReorderSections(reorderSections: Bool) {
        
        if !lockToggleSectionsTableView {
            lockToggleSectionsTableView = true
            
            if reorderSections { // show reorder sections table view
                
                listItemsTableViewController.setAllSectionsExpanded(!listItemsTableViewController.sectionsExpanded, animated: true, onComplete: { // collapse - add sections table view
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewController()
                    
                    sectionsTableViewController.sections = self.listItemsTableViewController.sections
                    sectionsTableViewController.status = self.status
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
                    
                    self.onToggleReorderSections(true)
                    
                })
                
            } else { // show normal table view
                
                if let sectionsTableViewController = sectionsTableViewController { // expand while in collapsed state (sections tableview is set) - remove sections table view
                    
                    sectionsTableViewController.setCellHeight(DimensionsManager.listItemsHeaderHeight, animated: true)
                    sectionsTableViewController.setEdit(false, animated: true) {
                        sectionsTableViewController.removeFromParentViewController()
                        sectionsTableViewController.view.removeFromSuperview()
                        self.sectionsTableViewController = nil
                        self.listItemsTableViewController.setAllSectionsExpanded(!self.listItemsTableViewController.sectionsExpanded, animated: true)
                        self.lockToggleSectionsTableView = false
                    
                        self.onToggleReorderSections(false)
                    }
                } else {
                    // we are already in normal state (sections tableview is not set) - do nothing
                    lockToggleSectionsTableView = false
                }
            }
        }
    }
    
    func onToggleReorderSections(isNowInReorderSections: Bool) {
        // override
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
    
    func canRemoveSection(section: Section, can: Bool -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_section_confirm", section.name), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {
            can(true)
        }, onCancel: {
            can(false)
        })
    }
    
    func onSectionRemoved(section: Section) {
        listItemsTableViewController.removeSection(section.uuid)
        Providers.sectionProvider.remove(section, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.updatePossibleList()
            }
        ))
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
        toggleButtonRotator.enabled = true
        rightButtonsClosing()
        topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
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
    
    
    private func topBarOnCloseExpandable() {
        setDefaultLeftButtons()
        topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
    }
    
    private func closeTopController() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        topBarOnCloseExpandable()
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
            topBar.setRightButtonModels(rightButtonsDefault())
        }
    }
    
    // MARK: - Right buttons
    
    func rightButtonsDefault() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .ToggleOpen)]
    }
    
    func rightButtonsOpeningQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .ToggleOpen, endTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)))]
    }

    func rightButtonsClosingQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .ToggleOpen, initTransform: CGAffineTransformMakeRotation(CGFloat(M_PI_4)), endTransform: CGAffineTransformIdentity)]
    }
    
    func rightButtonsClosing() -> [TopBarButtonModel] {
        return []
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
                            AlertPopup.show(title: trans("popup_title_list_deleted"), message: trans("popup_list_was_deleted_in_other_device", list.name), controller: self, onDismiss: {[weak self] in
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
                case .TodoOrder:
                    fallthrough
                case .DoneOrder:
                    updatePossibleList() // reload list
                    
                default: print("Error: ViewController.onWebsocketUpdateListItems: Not handled: \(notification.verb)")
                }
            } else {
                print("Error: ViewController.onWebsocketAddListItems: no value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<[ListItem]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Add:
                    updatePossibleList() // reload list
                    
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
                    onListItemAddedToProvider(listItem, status: status, scrollToSelection: false, notifyRemote: false)
                    
                case .Update:
                    listItemsTableViewController.updateListItem(listItem, status: status, notifyRemote: false)
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
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteListItemIncrement>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Increment:
                    let incr = notification.obj
                    listItemsTableViewController.updateQuantity(incr.uuid, quantity: incr.updatedQuantity, notifyRemote: false)
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
            }

        } else if let info = note.userInfo as? Dictionary<String, WSNotification<(result: RemoteSwitchListItemFullResult, switchedListItem: ListItem)>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    
                case .Switch:
                    
                    let switchResult = notification.obj.result
                    
                    // If list item was switched from this status, just "swipe it out"
                    if switchResult.srcStatus == status {
                        swipeCell(switchResult.switchResult.switchedItem.uuid)
                        
                    // If list item was switched to this status, for the UI this is (for the most part) the same as add, so we call the same handler as add.
                    // The only difference with add is that when switch back for the original user the item keeps at the original order, while for the receiver it's appended at the end of the section. At the end the order of the original user "wins" (if the users reload the list, the item is still at the undo position not at the end of the section), since the undo of this user is the last operation to be sent to the server.
                    // For now we let it like this, otherwise we have to implement functionality to insert item at the original index.
                    } else if switchResult.dstStatus == status {
                        onListItemAddedToProvider(notification.obj.switchedListItem, status: status, scrollToSelection: false, notifyRemote: false)
                    }

                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
            }
            
            //            RemoteSwitchListItemFullResult
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteBuyCartResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .BuyCart:
                    // This is relevant for all status - cart (list items removed), stash (added), todo (cart price view update)
                    updatePossibleList() // reload list
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("Mo value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<RemoteSwitchAllListItemsLightResult>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .SwitchAll:
                    guard (currentList.map{notification.obj.update.listUuid == $0.uuid}) ?? false else {return} // TODO!!!! add this check to all others, also in inventory and group items
                    updatePossibleList() // reload list
                    
                default: QL4("Not handled: \(notification.verb)")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketSection(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[Section]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    // There's no direct add of section
                    //                case .Add:
                case .Update:
                    
                    // Updated note: for now we just update everything immediately - later we think about how to improve UX.
//                    // NOTE: this doesn't update order. Update reorder would require to reload the table view and this can e.g. revert undo cells or interfere with current action like swiping an item. So to update order the user has to reopen the list.
//                    for section in notification.obj {
//                        listItemsTableViewController.updateSection(section)
//                    }
                    updatePossibleList() // reload list

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
                    sectionsTableViewController?.removeSection(notification.obj)
                    
                case .DeleteWithName:
                    // This deletes sections but also categories so just reload
//                    if listItemsTableViewController.hasSectionWith({$0.name == notification.obj}) {
                        updatePossibleList() // reload list
//                    }
                    
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
                case .DeleteWithBrand:
                    // we can improve this by at least checking if there's a product that references this brand in the list, for now just reload
                    updatePossibleList() // reload list
                    
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