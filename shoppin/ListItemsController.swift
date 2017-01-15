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
import Providers
import RealmSwift

class ListItemsController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegate, ListItemsEditTableViewDelegate, QuickAddDelegate, ReorderSectionTableViewControllerDelegate, EditSectionViewControllerDelegate, ExpandableTopViewControllerDelegate, ListTopBarViewDelegate
    //    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
    fileprivate let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    
    weak var listItemsTableViewController: ListItemsTableViewController!
    
    @IBOutlet weak var topBar: ListTopBarView!
    @IBOutlet weak var topBarHeightConstraint: NSLayoutConstraint!
    
    weak var expandDelegate: Foo?
    
    var currentList: Providers.List? {
        didSet {
            updatePossibleList()
        }
    }
    
    // TODO rename these blocks, which are meant to be executed only once after loading accordingly e.g. onViewWillAppearOnce
    var onViewWillAppear: VoidFunction?
    var onViewDidAppear: VoidFunction?
    
    fileprivate var listItemsResult: Results<ListItem>?
    fileprivate var notificationToken: NotificationToken?
    
    var status: ListItemStatus {
        fatalError("override")
    }
    
    var isPullToAddEnabled: Bool {
        return true
    }
    
    var tableViewBottomInset: CGFloat {
        return 0
    }
    
    fileprivate var topQuickAddControllerManager: ExpandableTopViewController<QuickAddViewController>?
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate var toggleButtonRotator: ToggleButtonRotator = ToggleButtonRotator()
    
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

        NotificationCenter.default.addObserver(self, selector: #selector(ListItemsController.onListRemovedNotification(_:)), name: NSNotification.Name(rawValue: Notification.ListRemoved.rawValue), object: nil)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    deinit {
        QL1("Deinit list items controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initTopQuickAddControllerManager() -> ExpandableTopViewController<QuickAddViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<QuickAddViewController> = ExpandableTopViewController(top: top, height: DimensionsManager.quickAddHeight, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = UIStoryboard.quickAddViewController()
            controller.delegate = self
            controller.itemType = .productForList
            controller.list = self?.currentList
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    fileprivate func initEditSectionControllerManager() -> ExpandableTopViewController<EditSectionViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<EditSectionViewController> = ExpandableTopViewController(top: top, height: 70, openInset: top, closeInset: top, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] in
            let controller = EditSectionViewController()
            controller.delegate = self
            return controller
        }
        manager.delegate = self
        return manager
    }
    
    fileprivate func initTitleLabel() {
        let label = UILabel()
        label.font = Fonts.regular
        label.textColor = UIColor.white
        topBar.addSubview(label)
    }
    
    func onExpand(_ expanding: Bool) {
        if !expanding {
            clearPossibleNotePopup()
            topQuickAddControllerManager?.controller?.removeFromParentViewControllerWithView()
            setEmptyUI(false, animated: false)
            topBar.setLeftButtonIds([])
            topBar.setRightButtonModels(rightButtonsClosing())
            // Clear list item memory cache when we leave controller. This is not really necessary but just "in case". The list item memory cache is there to smooth things *inside* a list, that is transitions between todo/done/stash, and adding/incrementing items. Causing a db-reload when we load the controller is totally ok.
            Prov.listItemsProvider.invalidateMemCache()
        }
        
        topBar.positionTitleLabelLeft(expanding, animated: true, withDot: true, heightConstraint: topBarHeightConstraint)
    }
    
    func setThemeColor(_ color: UIColor) {
        topBar.dotColor = color
        view.backgroundColor = UIColor.white
    }
    
    fileprivate func updatePossibleList() {
        if let list = self.currentList {
            //            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }
    
    func setEmptyUI(_ empty: Bool, animated: Bool) {
        if empty {
            topBar.setLeftButtonIds([])
        } else {
            setDefaultLeftButtons()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
        toggleButtonRotator.reset(listItemsTableViewController.tableView, topBar: topBar)

        onViewDidAppear?()
        onViewDidAppear = nil
    }
    
    func onEmptyListViewTap(_ sender: UITapGestureRecognizer) {
        _ = toggleTopAddController() // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }

    
    fileprivate func initWithList(_ list: Providers.List) {
        topBar.title = topBarTitle(list)
        udpateListItems(list)
    }
    
    func topBarTitle(_ list: Providers.List) -> String {
        return list.name
    }
    
    fileprivate func udpateListItems(_ list: Providers.List, onFinish: VoidFunction? = nil) {
        Prov.listItemsProvider.listItems(list, sortOrderByStatus: status, fetchMode: .memOnly, successHandler{[weak self] listItems in guard let weakSelf = self else {return}

            weakSelf.listItemsTableViewController.setListItems(listItems.toArray())

            weakSelf.listItemsResult = listItems
            
//            weakSelf.notificationToken = weakSelf.listItemsResult?.addNotificationBlock { changes in
//                
//                switch changes {
//                case .initial:
//                    //                        // Results are now populated and can be accessed without blocking the UI
//                    //                        self.viewController.didUpdateList(reload: true)
//                    QL1("initial")
//                    
//                case .update(_, let deletions, let insertions, let modifications):
//                    QL2("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
//                    
//                    guard let results = weakSelf.listItemsResult else {QL4("No Results"); return}
//                    
//                    results.realm?.refresh()
//                    
//                    
//                    QL2("results refreshed, count: \(results.count)")
//                    
////                    for deletion in deletions {
////                        weakSelf.listItemsTableViewController?.removeListItem(index: deletion)
////                    }
//
//                    
//                    
//                    
////                    if deletions.isEmpty { // FIXME: in some cases, we delete an item and get insertions (!?) which can cause a crash if same index as deleted element, which is now invalid. Investigate why.
////                        for insertion in insertions {
////                            let listItem = results[insertion]
////                            weakSelf.listItemsTableViewController?.updateOrAddListItem(listItem, status: weakSelf.status, increment: true, scrollToSelection: true, notifyRemote: false)
////                        }
////                    } else {
////                        QL3("Got insertions with deletions, skipping insertions")
////                    }
//
//                    
////                    if let modification = modifications.first, modifications.count == 1 {
////                        if let listItem = results[safe: modification] { // When we decrement item to 0 (update - TODO remove when todo, done and stash are 0?), Realm passes us here an index, but our filter has todo/done/stash count > 0, which means the item was removed already from results. So this index is not valid (crashes e.g. when we decrement the last element - we get index 0 but results is empty). This seems like a Realm bug, TODO ask.
////                            weakSelf.listItemsTableViewController?.updateOrAddListItem(listItem, status: weakSelf.status, increment: true, scrollToSelection: true, notifyRemote: false)
////                        } else {
////                            QL3("Index to modify out of bounds - skipping: \(modification), results count: \(results.count)")
////                        }
////
////                    } else {
////                        weakSelf.listItemsTableViewController.setListItems(listItems.toArray())
////                    }
//
//                    
//
//                    // TODO!!!!!!!!!!!!!!!: update
////                    if replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
////                        weakSelf.updatePossibleList()
////                    } else {
////                        weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
////                        //                    self?.updatePrices(.MemOnly)
////                        weakSelf.onTableViewChangedQuantifiables()
////                    }
////                    weakSelf.closeTopController()
//                    
//                    
//                    // TODO close only when receiving own notification, not from someone else (possible?)
//                    if !modifications.isEmpty { // close only if it's an update (for add user may want to add multiple products)
//                        weakSelf.topQuickAddControllerManager?.expand(false)
//                        weakSelf.topQuickAddControllerManager?.controller?.onClose()
//                    }
//                    
//                    QL2("self?.onTableViewChangedQuantifiables(")
//
////                    self?.onTableViewChangedQuantifiables()
//                    
//                case .error(let error):
//                    // An error occurred while opening the Realm file on the background worker thread
//                    fatalError(String(describing: error))
//                }
//            }
            
            onFinish?()
        })
    }
    
    func onGetListItems(_ listItems: [ListItem]) {
        let i = listItems.filter{$0.hasStatus(status)}
        QL2("status: \(status), items: \(i)")
        onTableViewChangedQuantifiables()
    }
    
    // buttons for left nav bar side in default state (e.g. not while the top controller is open)
    func setDefaultLeftButtons() {
        if listItemsTableViewController.items.isEmpty {
            topBar.setLeftButtonIds([])
        } else {
            topBar.setLeftButtonIds([.edit])
        }
    }
    
    func clearPossibleNotePopup() {
        if let popup = view.viewWithTag(ViewTags.NotePopup) {
            popup.removeFromSuperview()
        }
    }
    
    // MARK:
    
    // returns: is now open?
    func toggleTopAddController(_ rotateTopBarButton: Bool = true) -> Bool {
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        clearPossibleUndo()
    }
    
    // Note: Parameter tryCloseTopViewController should not be necessary but quick fix for breaking constraints error when quickAddController (lazy var) is created while viewDidLoad or viewWillAppear. viewDidAppear works but has little strange effect on loading table then
    func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
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
        
        
        listItemsTableViewController.cellMode = editing ? .increment : .note
    }
    
    // TODO do we still need this? This was prob used by done view controller to update our list
    //    func itemsChanged() {
    //        self.initList()
    //    }
    
    //    var refreshControl: UIRefreshControl?
    fileprivate func initTableViewController() {
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
            case .todo: return .right
            case .done: return .left
            case .stash: return .left
            }
        }()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        clearPossibleUndo()
    }
    
    func clearPossibleUndo() {
        self.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
    }
    
    // MARK: - ListItemsTableViewDelegate
    
    func onTableViewScroll(_ scrollView: UIScrollView) {
        toggleButtonRotator.rotateForOffset(-64, topBar: topBar, scrollView: scrollView)
    }
    
    func onPullToAdd() {
        _ = toggleTopAddController(false) // this is meant to only open the menu, but toggle is ok since if we can tap on empty view it means it's closed
    }
    
    func onListItemClear(_ tableViewListItem: TableViewListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .bottom)
        onTableViewChangedQuantifiables()
        onFinish()
    }
    
    func onListItemSelected(_ tableViewListItem: TableViewListItem, indexPath: IndexPath) {
        if self.isEditing { // open quick add in edit mode
            topQuickAddControllerManager?.expand(true)
            topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
            
            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: tableViewListItem.listItem, currentStatus: status))
            
        } else { // switch list item

            // TODO!!!! when receive switch status via websocket we will *not* show undo (undo should be only for the device doing the switch) but submit immediately this means:
            // 1. call switchstatus like here, 2. switch status in provider updates status/order, maybe deletes section, etc 3. update the table view - swipe the item and maybe delete section(this should be similar to calling onListItemClear except the animation in this case is not swipe, but that should be ok?)
            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in guard let weakSelf = self else {return}
                let targetStatus: ListItemStatus = {
                    switch weakSelf.status {
                    case .todo: return .done
                    case .done: return .todo
                    case .stash: return .todo
                    }
                }()
                
                // NOTE: For the provider the whole state is updated here - including possible section removal (if the current undo list item is the last one in the section) and the order field update of possible following sections. This means that the contents of the table view may be in a slightly inconsistent state with the data in the provider during the time cell is in undo (for the table view the section is still there, for the provider it's not). This is fine as the undo state is just a UI thing (local) and it should be cleared as soon as we try to start a new action (add, edit, delete, reorder etc) or go to the cart/stash.
                Prov.listItemsProvider.switchStatus(tableViewListItem.listItem, list: tableViewListItem.listItem.list, status1: weakSelf.status, status: targetStatus, orderInDstStatus: nil, remote: true, weakSelf.resultHandler(onSuccess: {switchedListItem in
//                        weakSelf.onTableViewChangedQuantifiables()
                    }, onErrorAdditional: {result in
                        weakSelf.updatePossibleList()
                    }
                ))
            })
        }
    }
    
    // Immediate swipe - websocket
    fileprivate func swipeCell(_ listItemUuid: String) {
        if let indexPath = listItemsTableViewController.getIndexPath(listItemUuid: listItemUuid) {
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
    
    fileprivate func updateEmptyUI() {
        setEmptyUI(listItemsTableViewController.items.isEmpty, animated: true)
    }
    
    func updateQuantifiables() {
    }
    
    func onListItemReset(_ tableViewListItem: TableViewListItem) {
        onListItemReset(tableViewListItem.listItem)
    }
    
    func onListItemReset(_ listItem: ListItem) {

        // revert list item operation
        let srcStatus: ListItemStatus = {
            switch status {
            case .todo: return .done
            case .done: return .todo
            case .stash: return .todo
            }
        }()
        
        func updateUI() {
            listItemsTableViewController.tableView.reloadData()
            onTableViewChangedQuantifiables()
        }
        
        Prov.listItemsProvider.switchStatus(listItem, list: listItem.list, status1: srcStatus, status: status, orderInDstStatus: listItem.order(status), remote: true, successHandler{switchedListItem in
            QL1("Undo successful")
            updateUI()
        })
    }
    
    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        onSectionSelected(section.section)
    }
    
    func onIncrementItem(_ tableViewListItem: TableViewListItem, delta: Int) {
        Prov.listItemsProvider.increment(tableViewListItem.listItem, status: status, delta: delta, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
            self?.onTableViewChangedQuantifiables()
        })
    }
    
    
    
    
    // MARK: -
    
    // for tap on normal sections and edit mode sections (2 different tableviews)
    fileprivate func onSectionSelectedShared(_ section: Section) {
        if isEditing {
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
    
    fileprivate func getTableViewInset() -> CGFloat {
        return topBar.frame.height
    }
    
    func onListItemsOrderChangedSection(_ tableViewListItems: [TableViewListItem]) {
        fatalError("override")
    }
    
    /**
     Update price labels (total, done) using state in provider
     */
    func updatePrices(_ listItemsFetchMode: ProviderFetchModus = .both) {
        // override
        QL3("No override for updatePrices")
    }
    
    fileprivate func addItem(_ listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {

        guard let notificationToken = notificationToken, let realm = listItemsResult?.realm else {QL4("No notification token: \(self.notificationToken) or result: \(listItemsResult)"); return}

        if let currentList = self.currentList {
            Prov.listItemsProvider.add(listItemInput, status: status, list: currentList, order: nil, possibleNewSectionOrder: ListItemStatusOrder(status: status, order: listItemsTableViewController.sections.count), token: RealmToken(token: notificationToken, realm: realm), successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
                self?.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
                handler?() // TODO!!!!!!!!!! whats this for?
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }
        
    }
    
    fileprivate func onListItemAddedToProvider(_ savedListItem: ListItem, status: ListItemStatus, scrollToSelection: Bool, notifyRemote: Bool = true) {
        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
        listItemsTableViewController.updateOrAddListItem(savedListItem, status: status, increment: true, scrollToSelection: scrollToSelection, notifyRemote: notifyRemote)
        onTableViewChangedQuantifiables()
//        updatePrices(.MemOnly)
    }
    
    // Note: don't use this to reorder sections, this doesn't update section order
    // Note: concerning status - this only updates the current status related data (quantity, order). This means quantity and order of possible items in the other status is not affected
    fileprivate func updateItem(_ updatingListItem: ListItem, listItemInput: ListItemInput) {
        if let currentList = self.currentList {
            
            Prov.listItemsProvider.update(listItemInput, updatingListItem: updatingListItem, status: status, list: currentList, true, successHandler {[weak self] (listItem, replaced) in guard let weakSelf = self else {return}
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
    
    func onListItemDeleted(_ tableViewListItem: TableViewListItem) {
        
        guard let notificationToken = notificationToken, let realm = listItemsResult?.realm else {QL4("No notification token: \(self.notificationToken) or result: \(listItemsResult)"); return}
        
        Prov.listItemsProvider.remove(tableViewListItem.listItem, remote: true, token: RealmToken(token: notificationToken, realm: realm), resultHandler(onSuccess: {[weak self] in
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
    
    func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        if let list = currentList {
            
            // TODO save "group list item" don't desintegrate group immediatly
            
            
            Prov.listItemsProvider.addGroupItems(group, status: status, list: list, resultHandler(onSuccess: {[weak self] addedListItems in
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
                case .isEmpty:
                    AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
                default:
                    self?.defaultErrorHandler()(result)
                }
            }))
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onAddProduct(_ product: QuantifiableProduct) {

//        guard let notificationToken = notificationToken, let realm = listItemsResult?.realm else {QL4("No notification token: \(self.notificationToken) or result: \(listItemsResult)"); return}
        let token: RealmToken? = nil // quickfix

        if let list = currentList {
            Prov.listItemsProvider.addListItem(product, status: status, sectionName: product.product.category.name, sectionColor: product.product.category.color, quantity: 1, list: list, note: nil, order: nil, storeProductInput: nil, token: token, successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
                weakSelf.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
            })
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
        func onEditListItem(_ input: ListItemInput, editingListItem: ListItem) {
            // set normal (.Note) mode in advance - with updateItem the table view calls reloadData, but the change to .Note mode happens after (in setEditing), which doesn't reload the table so the cells will appear without notes.
            updateItem(editingListItem, listItemInput: input)
        }
        
        func onAddListItem(_ input: ListItemInput) {
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
    
    func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        if let list = currentList {
            Prov.sectionProvider.sections([name], list: list, handler: successHandler {[weak self] sections in guard let weakSelf = self else {return}
                if let section = sections.first {
                    handler(section.color)
                } else {
                    // Suggestions can be sections and/or categories. If there's no section with this name (which we look up first, since we are in list items so section has higher prio) we look for a category.
                    Prov.productCategoryProvider.categoryWithNameOpt(name, weakSelf.successHandler {categoryMaybe in
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
    
    func onRemovedSectionCategoryName(_ name: String) {
        updatePossibleList()
    }
    
    func onRemovedBrand(_ name: String) {
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
    
    func onSectionUpdated(_ section: Section) {
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
    
    fileprivate func sendActionToTopController(_ action: FLoatingButtonAction) {
        if topQuickAddControllerManager?.expanded ?? false {
            topQuickAddControllerManager?.controller?.handleFloatingButtonAction(action)
        }
    }
    
    // MARK: - Reorder sections
    
    fileprivate weak var sectionsTableViewController: ReorderSectionTableViewController?
    fileprivate var lockToggleSectionsTableView: Bool = false // prevent condition in which user presses toggle too quickly many times and sectionsTableViewController doesn't go away
    
    // Toggles between expanded and collapsed section mode. For this a second tableview with only sections is added or removed from foreground. Animates floating button.
    func toggleReorderSections() {
        setReorderSections(sectionsTableViewController == nil)
    }
    
    fileprivate func setReorderSections(_ reorderSections: Bool) {
        
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
    
    func onToggleReorderSections(_ isNowInReorderSections: Bool) {
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
    
    func onSectionSelected(_ section: Section) {
        onSectionSelectedShared(section)
    }
    
    func canRemoveSection(_ section: Section, can: @escaping (Bool) -> Void) {
        ConfirmationPopup.show(title: trans("popup_title_confirm"), message: trans("popup_remove_section_confirm", section.name), okTitle: trans("popup_button_yes"), cancelTitle: trans("popup_button_no"), controller: self, onOk: {
            can(true)
        }, onCancel: {
            can(false)
        })
    }
    
    func onSectionRemoved(_ section: Section) {
        listItemsTableViewController.removeSection(section.uuid)
        Prov.sectionProvider.remove(section, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.updatePossibleList()
            }
        ))
    }

    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
        if controller is QuickAddViewController || controller is AddEditListItemViewController {
            view.frame.origin.y = topBar.frame.height
        }
    }
    
    func onExpandableClose() {
//        topBar.setBackVisible(false)
        setDefaultLeftButtons()
        toggleButtonRotator.enabled = true
        _ = rightButtonsClosing()
        topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
        topQuickAddControllerManager?.controller?.onClose()
        topEditSectionControllerManager?.controller?.onClose()
        
    }
    
    // MARK: - ListTopBarViewDelegate
    
    func onTopBarBackButtonTap() {
        sendActionToTopController(.back)
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
    
    
    fileprivate func topBarOnCloseExpandable() {
        setDefaultLeftButtons()
        topBar.setRightButtonModels(rightButtonsClosingQuickAdd())
    }
    
    fileprivate func closeTopController() {
        topQuickAddControllerManager?.expand(false)
        toggleButtonRotator.enabled = true
        topQuickAddControllerManager?.controller?.onClose()
        topBarOnCloseExpandable()
    }
    
    func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        switch buttonId {
        case .add:
            SizeLimitChecker.checkListItemsSizeLimit(listItemsTableViewController.items.count, controller: self) {[weak self] in
                if let weakSelf = self {
                    weakSelf.sendActionToTopController(.add)
                }
            }
        case .toggleOpen:
            _ = toggleTopAddController()
        case .edit:
            clearPossibleUndo()
            let editing = !self.listItemsTableViewController.isEditing
            self.setEditing(editing, animated: true, tryCloseTopViewController: true)
        default: QL4("Not handled: \(buttonId)")
        }
    }
    
    func onCenterTitleAnimComplete(_ center: Bool) {
        if center {
            setDefaultLeftButtons()
            topBar.setRightButtonModels(rightButtonsDefault())
        }
    }
    
    // MARK: - Right buttons
    
    func rightButtonsDefault() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen)]
    }
    
    func rightButtonsOpeningQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen, endTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)))]
    }

    func rightButtonsClosingQuickAdd() -> [TopBarButtonModel] {
        return [TopBarButtonModel(buttonId: .toggleOpen, initTransform: CGAffineTransform(rotationAngle: CGFloat(M_PI_4)), endTransform: CGAffineTransform.identity)]
    }
    
    func rightButtonsClosing() -> [TopBarButtonModel] {
        return []
    }
    
    // MARK: - Notification
    
    func onListRemovedNotification(_ note: Foundation.Notification) {
        guard let info = (note as NSNotification).userInfo as? Dictionary<String, String> else {QL4("Invalid info: \(note)"); return}
        guard let listUuid = info[NotificationKey.list] else {QL4("No list uuid: \(info)"); return}
        guard let currentList = currentList else {QL3("No current list, ignoring list removed notification."); return}
        
        // If we happen to be showing a list that was just removed (e.g. because user removed an inventory the list was associated to), exit.
        // In this case (opposed to websocket notification) we don't show an alert, as this is triggered by an action of the user in the same device and user should know it was removed.
        if listUuid == currentList.uuid {
            back()
        }
    }
}
