//
//  ListItemsControllerNew.swift
//  shoppin
//
//  Created by Ivan Schuetz on 30/01/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import SwiftValidator
import ChameleonFramework

import Providers
import RealmSwift

class ListItemsControllerNew: ItemsController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegateNew, ListItemsEditTableViewDelegateNew, ReorderSectionTableViewControllerDelegateNew, EditSectionViewControllerDelegate
    //    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
//    fileprivate let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    
    weak var listItemsTableViewController: ListItemsTableViewControllerNew!
    
    var tableViewTopConstraint: NSLayoutConstraint?
    var reorderSectionsTableViewTopConstraint: NSLayoutConstraint?
    
    var currentList: Providers.List? {
        didSet {
            if let list = currentList {
                initWithList(list)
            }
        }
    }
    
    var realmData: RealmData?
    fileprivate var notificationToken: NotificationToken? {
        return realmData?.tokens.first
    }

    // Status of current controller - with the current hierarchy this can be only .done (hierachy changed and code was not updated)
    // This is used for the current items shown in this controller
    var status: ListItemStatus {
        fatalError("override")
    }

    // Status to be passed to update (or any other provider methods that require status of item)
    // This is used for specific items that are changed and have to reflect the status where these items are in
    var statusForUpdate: ListItemStatus {
        fatalError("override")
    }

    override var tableView: UITableView {
        return listItemsTableViewController.tableView
    }
    
    override var isEmpty: Bool {
        return currentList?.sections(status: status).isEmpty ?? true
    }
    
    override var list: Providers.List? {
        return currentList
    }
    
    override var isAnyTopControllerExpanded: Bool {
        return super.isAnyTopControllerExpanded || (topEditSectionControllerManager?.expanded ?? false)
    }
    
    var tableViewBottomInset: CGFloat {
        return 0
    }
    
    var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?
    
    fileprivate var initializedTableViewBottomInset = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = topBar.dotColor
        
        initEmptyView(line1: trans("empty_list_line1"), line2: trans("empty_list_line2"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListItemsControllerNew.onInventoryRemovedNotification(_:)), name: NSNotification.Name(rawValue: Notification.InventoryRemoved.rawValue), object: nil)
    }

    override func initProgrammaticViews() {
        super.initProgrammaticViews()
        
        initTableViewController()
    }
    
    deinit {
        logger.v("Deinit list items controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set inset such that newly added cells can be positioned directly below the quick add controller
        // Before of view did appear final table view height is not set. We also have to execute this only the first time because later it may be that the table view is contracted (quick add is open) which would set an incorrect inset.
        if !initializedTableViewBottomInset {
            initializedTableViewBottomInset = true
            listItemsTableViewController.tableView.bottomInset = listItemsTableViewController.tableView.height - DimensionsManager.quickAddHeight - DimensionsManager.defaultCellHeight
        }
    }
    
    func initEditSectionControllerManager() -> ExpandableTopViewController<EditSectionViewController> {
        let top = topBar.frame.height
        let manager: ExpandableTopViewController<EditSectionViewController> = ExpandableTopViewController(top: top, height: 70, animateTableViewInset: false, parentViewController: self, tableView: listItemsTableViewController.tableView) {[weak self] _ in
            let controller = EditSectionViewController()
            controller.delegate = self
            return controller
        }
        manager.delegate = self
        return manager
    }

    fileprivate func initWithList(_ list: Providers.List) {
        topBar.title = topBarTitle(list)

        delay(0.2) { // smoother animation when showing controller
            self.listItemsTableViewController.sections = list.sections(status: self.status)

            logger.v("Initialized sections: \(String(describing: self.listItemsTableViewController.sections?.count))")

            self.updateEmptyUI()

            self.onTableViewChangedQuantifiables()

            self.initNotifications()
        }
    }
    
    func topBarTitle(_ list: Providers.List) -> String {
        return list.name
    }

    fileprivate func initNotifications() {

        guard let sections = listItemsTableViewController.sections else {logger.e("No sections"); return}
        guard let sectionsRealm = sections.realm else {logger.e("No realm"); return}

        realmData?.invalidateTokens()
        
        let notificationToken = sections.observe {[weak self] changes in guard let weakSelf = self else {return}

            switch changes {
            case .initial:
                //                        // Results are now populated and can be accessed without blocking the UI
                //                        self.viewController.didUpdateList(reload: true)
                logger.v("initial")

            case .update(_, let deletions, let insertions, let modifications):
                logger.d("LIST ITEMS notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")

                // when we delete an inventory the list, listitems etc. are deleted too - don't process notification if this is the case
                // default to true - if there's no list there's also no reason to run this block
                if !(weakSelf.list?.isInvalidated ?? true) {

                    if deletions.count > 1 {
                        logger.i("Got multiple deletions: reloading table", .ui)
                        weakSelf.listItemsTableViewController.tableView.reloadData()

                    } else {

                        // TODO pass modifications to listItemsTableViewController, don't access table view directly
                        weakSelf.listItemsTableViewController.tableView.beginUpdates()
                        weakSelf.listItemsTableViewController.tableView.insertSections(IndexSet(insertions), with: .top)
                        weakSelf.listItemsTableViewController.tableView.deleteSections(IndexSet(deletions), with: .top)
                        weakSelf.listItemsTableViewController.tableView.reloadSections(IndexSet(modifications), with: .none)
                        weakSelf.listItemsTableViewController.tableView.endUpdates()


                        weakSelf.updateEmptyUI()

                        // TODO!!!!!!!!!!!!!!!: update
                        //                    if replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
                        //                        weakSelf.updatePossibleList()
                        //                    } else {
                        //                        weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
                        //                        //                    self?.updatePrices(.MemOnly)
                        //                        weakSelf.onTableViewChangedQuantifiables()
                        //                    }
                        //                    weakSelf.closeTopController()

                    }

                    //                logger.d("self?.onTableViewChangedQuantifiables(")

                    weakSelf.onTableViewChangedQuantifiables()

                    // TODO crash: both devices delete their duplicate at the same time, which sends a delete for an out of index item
                    // e.g. testing with only 1 list item -> add to cart at the same time -> both get a duplicated section and delete it (with removePossibleSectionDuplicates), send it to the other (index of deleted section is 1) since duplicate was deleted locally already receiver has only 1 section and deleted index 1 is out of bounds -> crash
                    if !insertions.isEmpty || !modifications.isEmpty { // Checking for modifications too - here we work with sections, not listitems, so modified sections can mean inserted listitem.
                        logger.w("TODO LIST insertions not empty! will remove possible duplicates thread: \(Thread.current)", .ui)
                        if let list = weakSelf.currentList {
                            Prov.listItemsProvider.removePossibleSectionDuplicates(list: list, status: weakSelf.status, weakSelf.successHandler { removedADuplicate in
                                if removedADuplicate {
                                    logger.i("Removed a section duplicate! Reloading table view", .ui)
                                    //                                weakSelf.listItemsTableViewController.tableView.reloadData()
                                }
                            })
                        } else {
                            logger.e("Unexpected: No list.", .ui)
                        }
                    }

                }

            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError(String(describing: error))
            }
        }
        
        realmData = RealmData(realm: sectionsRealm, token: notificationToken)
    }


    
    // TODO do we still need this? This was prob used by done view controller to update our list
    //    func itemsChanged() {
    //        self.initList()
    //    }
    
    //    var refreshControl: UIRefreshControl?
    fileprivate func initTableViewController() {
        listItemsTableViewController = UIStoryboard.listItemsTableViewControllerNew()
        
        listItemsTableViewController.automaticallyAdjustsScrollViewInsets = false
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false

        _ = listItemsTableViewController.view.alignLeft(view)
        _ = listItemsTableViewController.view.alignRight(view)
        _ = listItemsTableViewController.view.alignBottom(view)
        
        let tableViewTopConstraint = NSLayoutConstraint(item: listItemsTableViewController.view, attribute: .top, relatedBy: .equal, toItem: topBar, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(tableViewTopConstraint)
        self.tableViewTopConstraint = tableViewTopConstraint
        
        listItemsTableViewController.status = status
        listItemsTableViewController.scrollViewDelegate = self
        listItemsTableViewController.listItemsTableViewDelegate = self
        listItemsTableViewController.listItemsEditTableViewDelegate = self

        
//        let navbarHeight = topBar.frame.height
//        let topInset = navbarHeight
//        let bottomInset: CGFloat = tableViewBottomInset + 10 // 10 - show a little empty space between the last item and the prices view
//        listItemsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
//        listItemsTableViewController.tableView.topOffset = -listItemsTableViewController.tableView.inset.top
        
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

    override func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        
        listItemsTableViewController.setEditing(editing, animated: animated)
        listItemsTableViewController.cellMode = editing ? .increment : .note
        
        if !editing {
            // in case we are in reorder sections mode, come back to normal. This is an edit specific mode.
            setReorderSections(false)
        }
    }
    
    override func closeTopControllers(rotateTopBarButton: Bool = true) {
        super.closeTopControllers(rotateTopBarButton: rotateTopBarButton)
        topEditSectionControllerManager?.expand(false)
        topEditSectionControllerManager?.controller?.onClose()

    }
    
    override func onFinishCloseTopControllers() {
        super.onFinishCloseTopControllers()

        listItemsTableViewController.contract = false
        //        self?.listItemsTableViewController.placeHolderItem = (indexPath: indexPath, item: addResult.listItem)
        listItemsTableViewController.tableView.reloadData()
        //        self?.listItemsTableViewController.tableView.layoutIfNeeded()
    }
    
    override func openQuickAdd(rotateTopBarButton: Bool = true, itemToEdit: AddEditItem? = nil) {
        super.openQuickAdd(rotateTopBarButton: rotateTopBarButton, itemToEdit: itemToEdit)
        
        // in case we are in reorder sections mode, come back to normal. This mode doesn't make sense while adding list items as we can't see the list items.
        setReorderSections(false)
        
        // hide headers
        listItemsTableViewController.contract = true
        listItemsTableViewController.tableView.reloadData()
        listItemsTableViewController.tableView.layoutIfNeeded()
    }
    
    func onListItemClear(_ tableViewListItem: ListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        // TODO!!!!!!!!!!!!!!!!!!!!! necessary?
//        listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .bottom)
//        onTableViewChangedQuantifiables()
//        onFinish()
    }
    
    func onListItemSelected(_ tableViewListItem: ListItem, indexPath: IndexPath) {
        if isEditing {
            beforeToggleTopAddController(willExpand: true)
            openQuickAdd(itemToEdit: AddEditItem(item: tableViewListItem, currentStatus: status))
        }
    }
    
    func onListItemSwiped(_ tableViewListItem: ListItem, indexPath: IndexPath) {
        if !isEditing {
            guard let realmData = realmData else { logger.e("No realm data"); return }
            
            // TODO!!!! when receive switch status via websocket we will *not* show undo (undo should be only for the device doing the switch) but submit immediately this means:
            // 1. call switchstatus like here, 2. switch status in provider updates status/order, maybe deletes section, etc 3. update the table view - swipe the item and maybe delete section(this should be similar to calling onListItemClear except the animation in this case is not swipe, but that should be ok?)
            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in guard let weakSelf = self else {return}
                //               let targetStatus: ListItemStatus = {
                //                   switch weakSelf.status {
                //                   case .todo: return .done
                //                   case .done: return .todo
                //                   case .stash: return .todo
                //                   }
                //               }()
                
                // NOTE: For the provider the whole state is updated here - including possible section removal (if the current undo list item is the last one in the section) and the order field update of possible following sections. This means that the contents of the table view may be in a slightly inconsistent state with the data in the provider during the time cell is in undo (for the table view the section is still there, for the provider it's not). This is fine as the undo state is just a UI thing (local) and it should be cleared as soon as we try to start a new action (add, edit, delete, reorder etc) or go to the cart/stash.
                
                Prov.listItemsProvider.switchTodoToCartSync(listItem: tableViewListItem, from: indexPath, realmData: realmData, weakSelf.successHandler{[weak self] switchedListItem in
                    self?.onTableViewChangedQuantifiables()
                })
                // Prov.listItemsProvider.switchStatus(tableViewListItem.listItem, list: tableViewListItem.listItem.list, status1: weakSelf.status, status: targetStatus, orderInDstStatus: nil, remote: true, weakSelf.resultHandler(onSuccess: {switchedListItem in
                //     //                        weakSelf.onTableViewChangedQuantifiables()
                // }, onErrorAdditional: {result in
                //     weakSelf.updatePossibleList()
                // }
                // ))
            })
        }
    }

    // TODO remove no websockets
//    // Immediate swipe - websocket
//    fileprivate func swipeCell(_ listItemUuid: String) {
//        if let indexPath = listItemsTableViewController.getIndexPath(listItemUuid: listItemUuid) {
//            listItemsTableViewController.markOpen(true, indexPath: indexPath, notifyRemote: true, onFinish: {[weak self] in
//                self?.listItemsTableViewController.clearPendingSwipeItemIfAny(true)
//            })
//        } else {
//            logger.d("Didn't find list item uuid in table view: \(listItemUuid)")
//        }
//    }
    
    // Callen when table view contents affecting list items quantity/price is modified
    func onTableViewChangedQuantifiables() {
        updateQuantifiables()
        updateEmptyUI()
        setDefaultLeftButtons()
    }
    
    func updateQuantifiables() {
    }

    
    func onListItemReset(_ listItem: ListItem) {
        // TODO!!!!!!!!!!!!!! reset now only for delete.
        
    //     // revert list item operation
    //     let srcStatus: ListItemStatus = {
    //         switch status {
    //         case .todo: return .done
    //         case .done: return .todo
    //         case .stash: return .todo
    //         }
    //     }()
        
    //     func updateUI() {
    //         listItemsTableViewController.tableView.reloadData()
    //         onTableViewChangedQuantifiables()
    //     }
        
    //     Prov.listItemsProvider.switchStatusNew(listItem: listItem, srcStatus: srcStatus, dstStatus: status, notificationToken: notificationToken, realm: nil, successHandler{switchedListItem in
    //         logger.v("Undo successful")
    //         updateUI()
    //     })
    //     //Prov.listItemsProvider.switchStatus(listItem, list: listItem.list, status1: srcStatus, status: status, orderInDstStatus: listItem.order(status), remote: true, successHandler{switchedListItem in
    //     //    logger.v("Undo successful")
    //     //    updateUI()
    //     //})
    }

    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: Section) {
        onSectionSelected(section)
    }
    
    // TODO why this doesn't trigger the notification? Nowhere we pass notification token and the transaction executes successfully, with a change. Adding realm.add(obj, update: true) after the increment also didn't help. The increment of the cart, on the other side works as expected - it triggers a notification (in the cart) when no token is passed. UPDATE: In last tests this *was* triggering the notification - now passing token to prevent this - all local changes should be done without notifications, notifications are only for other clients! When testing sync with other clients, remove this todo if behavior is corrent.
    func onIncrementItem(_ tableViewListItem: ListItem, delta: Float) {
        guard let realmData = realmData else {logger.e("No realm data"); return}

        Prov.listItemsProvider.increment(tableViewListItem, status: status, delta: delta, remote: true, tokens: realmData.tokens, successHandler{incrementedListItem in
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
//            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
//            self?.onTableViewChangedQuantifiables()
        })
    }
    
    func onQuantityInput(_ listItem: ListItem, quantity: Float) {
        let delta = quantity - listItem.quantity
        onIncrementItem(listItem, delta: delta)
    }
    
    
    // MARK: -
    
    // for tap on normal sections and edit mode sections (2 different tableviews)
    fileprivate func onSectionSelectedShared(_ section: Section) {
        if sectionsTableViewController != nil {
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

    override func onTopBarButtonTap(_ buttonId: ListTopBarViewButtonId) {
        if buttonId == .expandSections {
            if let expandSectionButton = topBar.expandSectionButton {
                // change the button's state (this is different to other buttons in the topbar since the button does the
                // animation itself
                expandSectionButton.on = !expandSectionButton.on
                toggleReorderSections()
            } else {
                logger.e("Invalid state - tapped on expand section button but not set", .ui)
            }
        } else {
            super.onTopBarButtonTap(buttonId)
        }
    }

    // MARK: - ListItemsEditTableViewDelegateNew
    
    func onListItemsOrderChangedSection(_ tableViewListItems: [ListItem]) {
        fatalError("override")
    }
    
    func onListItemDeleted(indexPath: IndexPath, tableViewListItem: ListItem) {
//        guard let status = currentList else {logger.e("No realm data"); return}
        guard let list = currentList else {logger.e("No list"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        Prov.listItemsProvider.deleteNew(indexPath: indexPath, status: status, list: list, realmData: realmData, successHandler{[weak self] result in
            self?.onTableViewChangedQuantifiables()
            
            // NOTE: Assumes that Provider's deleteNew is synchronous
            if result.deletedSection {
                self?.listItemsTableViewController.tableView.deleteSection(index: indexPath.section)
            }}
        )
    }
    
    func onListItemMoved(from: IndexPath, to: IndexPath) {
        guard from != to else {logger.v("Nothing to move"); return}
        
        guard let list = currentList else {logger.e("No list"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}

        Prov.listItemsProvider.move(from: from, to: to, status: status, list: list, realmData: realmData, successHandler{result in
            delay(0.4) {
                // show possible changes, e.g. new section color, deleted section (when it's left empty)
                //            tableView.reloadRows(at: [destinationIndexPath], with: .none) // for now we reload complete tableview, when section is left empty it also has to be removed
                self.listItemsTableViewController.tableView.reloadData()
            }}
        )
    }
    
    /**
     Update price labels (total, done) using state in provider
     */
    func updatePrices(_ listItemsFetchMode: ProviderFetchModus = .both) {
        // override
        logger.w("No override for updatePrices")
    }
    
    fileprivate func addItem(_ listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil, onFinish: ((QuickAddItem, Any) -> Void)? = nil) {
        
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        
        func onAddSuccess(result: AddListItemResult) {
            
            let indexPath = IndexPath(row: result.listItemIndex, section: result.sectionIndex)
            if result.isNewItem {
                listItemsTableViewController.tableView.addRow(indexPath: indexPath, isNewSection: result.isNewSection)
            } else {
                listItemsTableViewController.tableView.updateRow(indexPath: indexPath)
            }
            listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: Theme.defaultRowPosition, animated: true)
            
            updateEmptyUI()
        }
        
        if let currentList = self.currentList {
            Prov.listItemsProvider.addNew(listItemInput: listItemInput, list: currentList, status: status, realmData: realmData, successHandler {result in
                onAddSuccess(result: result)
                
                let res = QuickAddProduct(result.listItem.product.product.product, colorOverride: nil, quantifiableProduct: result.listItem.product.product, boldRange: nil)
                
                    
                onFinish?(res, result.listItem)
                handler?() // TODO!!!!!!!!!! whats this for? -- remove we now have on finish
            })
            //Prov.listItemsProvider.add(listItemInput, status: status, list: currentList, order: nil, possibleNewSectionOrder: ListItemStatusOrder(status: status, order: listItemsTableViewController.sections.count), token: RealmToken(token: notificationToken, realm: realm), successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
            //    self?.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
            //    handler?() // TODO!!!!!!!!!! whats this for?
            //})
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }
        
    }
    
    
    
    fileprivate func addFormItem(_ listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil, onFinish: ((QuickAddItem, Any) -> Void)? = nil) {
        
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        
        func onAddSuccess(result: AddListItemResult) {
            
            let indexPath = IndexPath(row: result.listItemIndex, section: result.sectionIndex)
            if result.isNewItem {
                listItemsTableViewController.tableView.addRow(indexPath: indexPath, isNewSection: result.isNewSection)
            } else {
                listItemsTableViewController.tableView.updateRow(indexPath: indexPath)
            }
            listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: Theme.defaultRowPosition, animated: true)
            
            updateEmptyUI()
        }
        
        if let currentList = self.currentList {
            
            Prov.listItemsProvider.addNew(listItemInput: listItemInput, list: currentList, status: status, realmData: realmData, successHandler {result in
                onAddSuccess(result: result)
                
                let res = QuickAddProduct(result.listItem.product.product.product, colorOverride: nil, quantifiableProduct: result.listItem.product.product, boldRange: nil)
                
                onFinish?(res, result.listItem)
                handler?() // TODO!!!!!!!!!! whats this for? -- remove we now have on finish
            })
            
        } else {
            print("Error: Invalid state: trying to add item without current list")
        }
        
    }
    
    
    
    
    
    // TODO!!!!!!!!!!!!!!!!! we probably will add in advance, so remove this?
    fileprivate func onListItemAddedToProvider(_ savedListItem: ListItem, status: ListItemStatus, scrollToSelection: Bool, notifyRemote: Bool = true) {
//        // Our "add" can also be an update - if user adds an item with a name that already exists, it's an update (increment)
//        listItemsTableViewController.updateOrAddListItem(savedListItem, status: status, increment: true, scrollToSelection: scrollToSelection, notifyRemote: notifyRemote)
//        onTableViewChangedQuantifiables()
//        //        updatePrices(.MemOnly)
    }
    
    // Note: don't use this to reorder sections, this doesn't update section order
    // Note: concerning status - this only updates the current status related data (quantity, order). This means quantity and order of possible items in the other status is not affected
    fileprivate func updateItem(_ updatingListItem: ListItem, listItemInput: ListItemInput, onFinish: ((QuickAddItem, Bool) -> Void)? = nil) {
        guard let realmData = realmData else {logger.e("No realm data"); return}
        
        if let currentList = self.currentList {
            
            Prov.listItemsProvider.updateNew(listItemInput, updatingListItem: updatingListItem, status: statusForUpdate, list: currentList, realmData: realmData, successHandler {[weak self] updateResult in guard let weakSelf = self else {return}
                if updateResult.replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
                    weakSelf.listItemsTableViewController.tableView.reloadData()
                    
                } else {
                    // TODO!!!!!!!!!!!!!!!!!
//                    weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
                    //                    self?.updatePrices(.MemOnly)
                    
                    // If as part of the update user entered a different section, we have to update both the src and dst sections
                    // This takes into account that dst section is a new one - since Realm's results are already updated, we will find the returned section in the table view controller's sections result and be able to reload it in the table view.
                    if updateResult.changedSection {
                        if let _ = updateResult.deletedSectionIndex { // A section was left empty - remove it
                            
                            // not sure what the problem is here, but at least when section 0 (src) is deleted and section 1 (target) updated there's an error with "can't update and delete the same row". Apparently after deleting section 0, section 1 becomes 0 (in the same transaction). Several different combinations didn't work (calling only update, only delete, changing order, etc). So using reloadData().
//                            weakSelf.listItemsTableViewController.tableView.wrapUpdates {
//                                weakSelf.listItemsTableViewController.deleteSection(index: deletedSectionIndex)
//                                weakSelf.listItemsTableViewController.updateTableViewSection(section: updateResult.listItem.section)
//                            }
                            weakSelf.listItemsTableViewController.tableView.reloadData()
                            
                        } else if let _ = updateResult.addedSectionIndex { // A new section was created - add it
                            // Here also reloadData, because I'm lazy. Note that there can also be the case that both src section is deleted (left empty) and a new section added - this is also handled by reloadData()
                            weakSelf.listItemsTableViewController.tableView.reloadData()
                            
                        } else { // No section was added or removed
                            weakSelf.listItemsTableViewController.tableView.reloadData()
                        }

                    } else {
                        weakSelf.listItemsTableViewController.updateListItemCell(listItem: updateResult.listItem)
                    }
                    
                    weakSelf.onTableViewChangedQuantifiables()
                }
                
                
                let res = QuickAddProduct(updateResult.listItem.product.product.product, colorOverride: nil, quantifiableProduct: updateResult.listItem.product.product, boldRange: nil)
                onFinish?(res, false) // for now we assume that item submitted in update is always not new. This is actually not always the case, as we can enter a new name/unique in the update form. Not critical though, for current usage of this flag (TODO improve this).
                weakSelf.closeTopControllers()
            })
        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }
        
    }

    
    // MARK: - QuickAddDelegate

    // TODO!!!!!!!!!!! only close top controllers?
//    override func onCloseQuickAddTap() {
//        super.onCloseQuickAddTap()
//        topQuickAddControllerManager?.expand(false)
//        toggleButtonRotator.enabled = true
//        topQuickAddControllerManager?.controller?.onClose()
//        topEditSectionControllerManager?.controller?.onClose()
//    }
    
    override func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        logger.e("Outdated")
//        
//        if let list = currentList {
//            
//            // TODO save "group list item" don't desintegrate group immediatly
//            
//            
//            Prov.listItemsProvider.addGroupItems(group, status: status, list: list, resultHandler(onSuccess: {[weak self] addedListItems in
//                if let list = self?.currentList {
//                    self?.initWithList(list) // refresh list items
////                    if let firstListItem = addedListItems.first {
////                        //    TODO!!!!!!!!!!!!!!!! ?
//////                        self?.listItemsTableViewController.scrollToListItem(firstListItem)
////                    } else {
////                        logger.w("Shouldn't be here without list items")
////                    }
//                } else {
//                    logger.w("Group was added but couldn't reinit list, self or currentList is not set: self: \(self), currentlist: \(self?.currentList)")
//                }
//                }, onError: {[weak self] result in guard let weakSelf = self else {return}
//                    switch result.status {
//                    case .isEmpty:
//                        AlertPopup.show(title: trans("popup_title_group_is_empty"), message: trans("popup_group_is_empty"), controller: weakSelf)
//                    default:
//                        self?.defaultErrorHandler()(result)
//                    }
//            }))
//        } else {
//            logger.e("Add product from quick list but there's no current list in ViewController'")
//        }
    }
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], recipeData: RecipeData, quickAddController: QuickAddViewController) {
        guard let list = currentList else {logger.e("No list"); return}
        guard let realmData = realmData else {logger.e("No realm data"); return}

        let listItemInputs = ingredientModels.map {model in
            
            ListItemInput(
                name: model.productPrototype.name,
                quantity: model.quantity,
                refPrice: nil,
                refQuantity: nil,
                section: model.ingredient.item.category.name,
                sectionColor: model.ingredient.item.category.color,
                note: nil,
                baseQuantity: model.productPrototype.baseQuantity,
                secondBaseQuantity: model.productPrototype.secondBaseQuantity,
                unit: model.productPrototype.unit,
                brand: model.productPrototype.brand,
                edible: model.productPrototype.edible
            )
        }
        
        Prov.listItemsProvider.addNew(listItemInputs: listItemInputs, list: list, status: status, overwriteColorIfAlreadyExists: true, realmData: realmData, successHandler {[weak self] _ in guard let weakSelf = self else { return }
            quickAddController.closeRecipeController()
            self?.tableView.reloadData()
            self?.onTableViewChangedQuantifiables()

            if let tabBarHeight = weakSelf.tabBarController?.tabBar.bounds.size.height {
                AddRecipeToListNotificationHelper.show(tabBarHeight: tabBarHeight, parent: weakSelf.view, recipeData: recipeData)
            } else {
                logger.e("No tabBarController")
            }
        })

        //Prov.listItemsProvider.add(listItemInputs, status: .todo, list: list, order: nil, possibleNewSectionOrder: nil, token: nil, successHandler{(addedListItems: [ListItem]) in
        //    // The list will update automatically with realm notification
        //    quickAddController.closeRecipeController()
        //})
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        guard let list = currentList else {logger.e("No list"); return}
        
        Prov.listItemsProvider.listItems(list: list, ingredient: ingredient, mapper: { listItems -> String in
            if listItems.isEmpty {
                return ""
            } else {
                return trans("recipe_already_has", listItems.map {
                    Ingredient.quantityFullText(quantity: $0.quantity, baseQuantity: $0.product.product.baseQuantity, secondBaseQuantity: $0.product.product.secondBaseQuantity, unitId: $0.product.product.unit.id, unitName: $0.product.product.unit.name, showNoneUnitName: true)
                }.joined(separator: ", "))
            }
        }, successHandler {text in
            handler(text)
        })
    }
    
    
    override func onAddProduct(_ product: QuantifiableProduct, quantity: Float, note: String?, onAddToProvider: @escaping (QuickAddAddProductResult) -> Void) {
        guard let realmData = realmData else {logger.e("No realm data"); return}
     
        if let list = currentList {
            
            // TODO!!!!!!!!!!! don't pass store, list has the store!
            Prov.listItemsProvider.addNew(quantifiableProduct: product, store: list.store ?? "", list: list, quantity: quantity, note: note, status: status, realmData: realmData, successHandler {[weak self] (addResult:
                AddListItemResult) in
                
                onAddToProvider(QuickAddAddProductResult(isNewItem: addResult.isNewItem))
                
                let indexPath = IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex)

                if addResult.isNewSection {
                    self?.listItemsTableViewController.placeHolderItem = (indexPath: indexPath, item: addResult.listItem)
                    self?.tableView.insertSections([addResult.sectionIndex], with: Theme.defaultRowAnimation)
                    self?.listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    
                } else if addResult.isNewItem {
                    self?.listItemsTableViewController.placeHolderItem = (indexPath: indexPath, item: addResult.listItem)
                    self?.tableView.insertRows(at: [indexPath], with: Theme.defaultRowAnimation)
                    self?.listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                    
                } else { // update
                    self?.listItemsTableViewController.tableView.updateRow(indexPath: IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex))
                    self?.listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
                

                self?.updateEmptyUI()
            })
            
        } else {
            logger.e("Add product from quick list but there's no current list in ViewController'")
        }
    }
    
    override func onSubmitAddEditItem(_ input: ListItemInput, editingItem: Any?) {
        
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
                logger.e("Cast didn't work: \(String(describing: editingItem))")
            }
        }
    }

    func getRealmDataForAddEditItem() -> RealmData? {
        return realmData
    }

    override func onSubmitAddEditItem2(_ input: ListItemInput, editingItem: Any?, onFinish: ((QuickAddItem, Bool) -> Void)?) {
        
        guard let list = currentList else {logger.e("No list"); return}
        guard let realmData = getRealmDataForAddEditItem() else {logger.e("No realm data"); return}
        
        func onEditListItem(_ input: ListItemInput, editingListItem: ListItem) {
            // set normal (.Note) mode in advance - with updateItem the table view calls reloadData, but the change to .Note mode happens after (in setEditing), which doesn't reload the table so the cells will appear without notes.
            updateItem(editingListItem, listItemInput: input, onFinish: onFinish)
        }
        
        func onAddListItem(_ input: ListItemInput) {
            
            Prov.listItemsProvider.addNewStoreProduct(listItemInput: input, list: list, status: status, realmData: realmData, successHandler {addedStoreProduct in
                let res = QuickAddProduct(addedStoreProduct.0.product.product, colorOverride: nil, quantifiableProduct: addedStoreProduct.0.product, boldRange: nil)
                onFinish?(res, addedStoreProduct.1)
            })
        }
        
        if let editingListItem = editingItem as? ListItem {
            onEditListItem(input, editingListItem: editingListItem)
        } else {
            if editingItem == nil {
                onAddListItem(input)
            } else {
                logger.e("Cast didn't work: \(String(describing: editingItem))")
            }
        }
    }
    
    
    
    
    
    
    override func onQuickListOpen() {
    }
    
    override func onAddProductOpen() {
    }
    
//    override func parentViewForAddButton() -> UIView {
//        return self.view
//    }
    
    override func addEditSectionOrCategoryColor(_ name: String, handler: @escaping (UIColor?) -> Void) {
        if let list = currentList {
            // TODO filter the list sections instead of calling provider?
            Prov.sectionProvider.sections([name], list: list, handler: successHandler {[weak self] sections in guard let weakSelf = self else {return}
                if let section = sections.first {
                    handler(section.color)
                } else {
                    // Suggestions can be sections and/or categories. If there's no section with this name (which we look up first, since we are in list items so section has higher prio) we look for a category.
                    Prov.productCategoryProvider.categoryWithNameOpt(name, weakSelf.successHandler {categoryMaybe in
                        handler(categoryMaybe?.color)
                        
                        if categoryMaybe == nil {
                            logger.e("No section or category found with name: \(name) in list: \(list)") // if it's in the autocompletions it must be either the name of a section or category so we should have found one of these
                        }
                    })
                }
            })
        } else {
            logger.e("Invalid state: retrieving section color for add/edit but list is not set")
        }
    }
    
    override func onRemovedSectionCategoryName(_ name: String) {
        listItemsTableViewController.tableView.reloadData()
    }
    
    override func onRemovedBrand(_ name: String) {
        listItemsTableViewController.tableView.reloadData()
    }
    
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
        // TODO!!!!!!!!!!!!!!!!!
//        listItemsTableViewController.updateSection(section)
        
        // because updateSection/reloadData listItemsTableViewController sets back expanded to true, set correct state. If sectionsTableViewController is not visible it means it's expanded.
        //        listItemsTableViewController.sectionsExpanded = sectionsTableViewController == nil
    }

    
    override func onFinishAddCellAnimation(addedItem: AnyObject) {
        listItemsTableViewController.placeHolderItem = nil
        self.listItemsTableViewController.tableView.reloadData()
        
    }

    override var offsetForAddCellAnimation: CGFloat {
        return DimensionsManager.contractedSectionHeight
    }
    
    // MARK: - Reorder sections
    
    fileprivate weak var sectionsTableViewController: ReorderSectionTableViewControllerNew?
    fileprivate var lockToggleSectionsTableView: Bool = false // prevent condition in which user presses toggle too quickly many times and sectionsTableViewController doesn't go away
    
    // Toggles between expanded and collapsed section mode. For this a second tableview with only sections is added or removed from foreground. Animates floating button.
    func toggleReorderSections() {
        setReorderSections(sectionsTableViewController == nil)
    }
    
    func setReorderSections(_ reorderSections: Bool) {
        
        if !lockToggleSectionsTableView {
            lockToggleSectionsTableView = true
            
            let isCurrentlyExpanded = listItemsTableViewController.sectionsExpanded && sectionsTableViewController == nil // Note that the sectionsTableViewController == nil check is redundant (listItemsTableViewController.sectionsExpanded check should be enough) but just in case
            
            //  Avoid repetition. Repetition in case of contract would cause to add a new sections controller on top of the current one, which has the effect of looking like the expand gesture doesn't work anymore, as only the section controller on top is removed and after this the removal code isn't executed anymore.
            guard (reorderSections && isCurrentlyExpanded) || (!reorderSections && !isCurrentlyExpanded) else {
                logger.v("Repeating current state, return")
                lockToggleSectionsTableView = false
                return
            }
            
            if reorderSections { // show reorder sections table view.
                
                listItemsTableViewController.setAllSectionsExpanded(false, animated: true, onComplete: {[weak self] in guard let weakSelf = self else {return} // collapse - add sections table view
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewControllerNew()
                    
                    sectionsTableViewController.sections = weakSelf.listItemsTableViewController.sections
                    sectionsTableViewController.status = weakSelf.status
                    sectionsTableViewController.delegate = weakSelf
                    
                    sectionsTableViewController.listItemsNotificationToken = weakSelf.realmData?.tokens.first
                    
                    sectionsTableViewController.onViewDidLoad = {[weak self, weak sectionsTableViewController] in guard let weakSelf = self else {return}
                        _ = weakSelf.topBar.frame.height
                        let topInset: CGFloat = 0
                        
                        // TODO this makes a very big bottom inset why?
                        //            let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + addButtonContainer.frame.height
                        //        let bottomInset = (navigationController?.tabBarController?.tabBar.frame.height)! + 20
                        let bottomInset: CGFloat = 0
                        sectionsTableViewController?.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0) // TODO can we use tableViewShiftDown here also? why was the bottomInset necessary?
                        //                sectionsTableViewController.tableView.topOffset = -self.listItemsTableViewController.tableView.inset.top
                        
                        sectionsTableViewController?.view.backgroundColor = weakSelf.listItemsTableViewController.view.backgroundColor
                        sectionsTableViewController?.tableView.backgroundColor = weakSelf.listItemsTableViewController.view.backgroundColor
                        
                        weakSelf.lockToggleSectionsTableView = false
                    }
                    
                    sectionsTableViewController.view.frame = weakSelf.listItemsTableViewController.view.frame
                    weakSelf.addChildViewControllerAndView(sectionsTableViewController, viewIndex: 1)
                    
                    
                    sectionsTableViewController.view.translatesAutoresizingMaskIntoConstraints = false
                    _ = sectionsTableViewController.view.alignLeft(weakSelf.view)
                    _ = sectionsTableViewController.view.alignRight(weakSelf.view)
                    _ = sectionsTableViewController.view.alignBottom(weakSelf.view)
                    
                    let reorderSectionsTableViewTopConstraint = NSLayoutConstraint(item: sectionsTableViewController.view, attribute: .top, relatedBy: .equal, toItem: weakSelf.topBar, attribute: .bottom, multiplier: 1, constant: 0)
                    weakSelf.view.addConstraint(reorderSectionsTableViewTopConstraint)
                    weakSelf.reorderSectionsTableViewTopConstraint = reorderSectionsTableViewTopConstraint
                    
                    
                    weakSelf.sectionsTableViewController = sectionsTableViewController
                    
                    weakSelf.onToggleReorderSections(true)
                    
                })
                
            } else { // show normal table view
                
                if let sectionsTableViewController = sectionsTableViewController { // expand while in collapsed state (sections tableview is set) - remove sections table view
                    
                    sectionsTableViewController.setCellHeight(DimensionsManager.listItemsHeaderHeight, animated: true)
                    sectionsTableViewController.setEdit(false, animated: true) {[weak self] in guard let weakSelf = self else {return}
                        sectionsTableViewController.removeFromParentViewController()
                        sectionsTableViewController.view.removeFromSuperview()
                        weakSelf.sectionsTableViewController = nil
                        weakSelf.listItemsTableViewController.setAllSectionsExpanded(true, animated: true)
                        weakSelf.lockToggleSectionsTableView = false
                        weakSelf.onToggleReorderSections(false)
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
//        if let list = currentList {
//            udpateListItems(list) {
//            }
//        } else {
//            print("Error: ViewController.onSectionOrderUpdated: Invalid state, reordering sections and no list")
//        }
    }
    
    func onSectionSelected(_ section: Section) {
        onSectionSelectedShared(section)
    }
    
    func canRemoveSection(_ section: Section, can: @escaping (Bool) -> Void) {
        let message = trans("popup_remove_section_confirm", section.name)
        let ranges = message.range(section.name).map { [$0] } ?? {
            logger.e("Invalid state section name not contained in: \(message)", .ui)
            return []
        } ()

        MyPopupHelper.showPopup(
            parent: self,
            type: .warning,
            title: trans("popup_title_confirm"),
            message: message,
            highlightRanges: ranges,
            okText: trans("popup_button_yes"),
            centerYOffset: 80, onOk: {
                can(true)
            }, onCancel: {
                can(false)
            }
        )
    }
    
    func onSectionRemoved(_ section: Section) {
        listItemsTableViewController.tableView.reloadData()
    }
    
    override func back() {
        super.back()
        topEditSectionControllerManager?.controller?.onClose()
    }
    
    // MARK: - Notification
    
    @objc func onInventoryRemovedNotification(_ note: Foundation.Notification) {
        guard let info = (note as NSNotification).userInfo as? Dictionary<String, String> else { logger.e("Invalid info: \(note)"); return }
        guard let inventoryUuid = info[NotificationKey.inventory] else { logger.e("No list uuid: \(info)"); return }
        guard let currentList = currentList else { logger.w("No current list, ignoring list removed notification."); return }
        
        // If we happen to be showing a list tht references a deleted inventory, delete it
        // we assume the user was alerted in the inventory that the list will be removed
        // Note that deleting the inventory invalidates the list, so we don't really need to check for uuid here - just in case.
        // (accessing the uuid of an invalidated objects crashes, so need invalidated check as well)
        if currentList.isInvalidated || inventoryUuid == currentList.inventory.uuid {
            back()
        }
    }
}
