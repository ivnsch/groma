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
import QorumLogs
import Providers
import RealmSwift

class ListItemsControllerNew: ItemsController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegateNew, ListItemsEditTableViewDelegateNew, ReorderSectionTableViewControllerDelegateNew, EditSectionViewControllerDelegate
    //    , UIBarPositioningDelegate
{
    
    // TODO remove fields that are not necessary anymore
    
//    fileprivate let defaultSectionIdentifier = "default" // dummy section for items where user didn't specify a section TODO repeated with tableview controller
    
    
    weak var listItemsTableViewController: ListItemsTableViewControllerNew!
    
    
    var currentList: Providers.List? {
        didSet {
            updatePossibleList()
        }
    }
    
    fileprivate var realmData: RealmData?
    fileprivate var notificationToken: NotificationToken? {
        return realmData?.token
    }
    
    var status: ListItemStatus {
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
    
    fileprivate var topEditSectionControllerManager: ExpandableTopViewController<EditSectionViewController>?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topEditSectionControllerManager = initEditSectionControllerManager()
        
        _ = topBar.dotColor
        
        initEmptyView(line1: trans("empty_list_line1"), line2: trans("empty_list_line2"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListItemsControllerNew.onListRemovedNotification(_:)), name: NSNotification.Name(rawValue: Notification.ListRemoved.rawValue), object: nil)
    }
 
    override func initProgrammaticViews() {
        super.initProgrammaticViews()
        
        initTableViewController()
    }
    
    deinit {
        QL1("Deinit list items controller")
        NotificationCenter.default.removeObserver(self)
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

    
    fileprivate func updatePossibleList() {
        if let list = self.currentList {
            //            self.navigationItem.title = list.name
            self.initWithList(list)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updatePossibleList() // if there's a list already (e.g. come back from cart or stash - reload. If not (come from lists) onViewWillAppear triggers it.
        
        
        //        updatePrices(.First)
        
    }
    
    
    fileprivate func initWithList(_ list: Providers.List) {
        topBar.title = topBarTitle(list)
        udpateListItems(list)
    }
    
    func topBarTitle(_ list: Providers.List) -> String {
        return list.name
    }
    
    fileprivate func udpateListItems(_ list: Providers.List, onFinish: VoidFunction? = nil) {

        guard let list = currentList else {QL4("No list"); return}
        
        listItemsTableViewController.sections = list.sections(status: status)
        
        QL1("Initialized sections: \(listItemsTableViewController.sections?.count)")
        
        onTableViewChangedQuantifiables()
        
        initNotifications()
    }
    
    fileprivate func initNotifications() {

        guard let sections = listItemsTableViewController.sections else {QL4("No sections"); return}
        guard let sectionsRealm = sections.realm else {QL4("No realm"); return}

        realmData?.token.stop()
        
        let notificationToken = sections.addNotificationBlock {[weak self] changes in guard let weakSelf = self else {return}

            switch changes {
            case .initial:
                //                        // Results are now populated and can be accessed without blocking the UI
                //                        self.viewController.didUpdateList(reload: true)
                QL1("initial")

            case .update(_, let deletions, let insertions, let modifications):
                QL2("LIST ITEMS notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")


                // TODO pass modifications to listItemsTableViewController, don't access table view directly
                weakSelf.listItemsTableViewController.tableView.beginUpdates()
                weakSelf.listItemsTableViewController.tableView.insertSections(IndexSet(insertions), with: .top)
                weakSelf.listItemsTableViewController.tableView.deleteSections(IndexSet(deletions), with: .top)
                weakSelf.listItemsTableViewController.tableView.reloadSections(IndexSet(modifications), with: .none)
                weakSelf.listItemsTableViewController.tableView.endUpdates()
                

                // TODO!!!!!!!!!!!!!!!: update
//                    if replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
//                        weakSelf.updatePossibleList()
//                    } else {
//                        weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
//                        //                    self?.updatePrices(.MemOnly)
//                        weakSelf.onTableViewChangedQuantifiables()
//                    }
//                    weakSelf.closeTopController()




//                QL2("self?.onTableViewChangedQuantifiables(")

//                    self?.onTableViewChangedQuantifiables()

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
    
    override func openQuickAdd(rotateTopBarButton: Bool = true, itemToEdit: AddEditItem? = nil) {
        super.openQuickAdd(rotateTopBarButton: rotateTopBarButton, itemToEdit: itemToEdit)
        
        // in case we are in reorder sections mode, come back to normal. This mode doesn't make sense while adding list items as we can't see the list items.
        setReorderSections(false)
    }
    
    func onListItemClear(_ tableViewListItem: ListItem, notifyRemote: Bool, onFinish: VoidFunction) {
        // TODO!!!!!!!!!!!!!!!!!!!!! necessary?
//        listItemsTableViewController.removeListItem(tableViewListItem.listItem, animation: .bottom)
//        onTableViewChangedQuantifiables()
//        onFinish()
    }
    
    func onListItemSelected(_ tableViewListItem: ListItem, indexPath: IndexPath) {
        // TODO!!!!!!!!!!!!!!!!!!!!! update for new UI - we probably will not use "select" anymore but swipe and without undo
        
        guard let realmData = realmData else {QL4("No realm data"); return}
        
       if self.isEditing { // open quick add in edit mode
            // TODO!!!!!!!!!!!!!! is this correct?
            openQuickAdd(itemToEdit: AddEditItem(item: tableViewListItem, currentStatus: status))
//            topQuickAddControllerManager?.expand(true)
//            topBar.setRightButtonModels(rightButtonsOpeningQuickAdd())
//            topQuickAddControllerManager?.controller?.initContent(AddEditItem(item: tableViewListItem, currentStatus: status))
        
       } else { // switch list item
           
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
//            QL2("Didn't find list item uuid in table view: \(listItemUuid)")
//        }
//    }
    
    // Callen when table view contents affecting list items quantity/price is modified
    func onTableViewChangedQuantifiables() {
        updateQuantifiables()
        updateEmptyUI()
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
    //         QL1("Undo successful")
    //         updateUI()
    //     })
    //     //Prov.listItemsProvider.switchStatus(listItem, list: listItem.list, status1: srcStatus, status: status, orderInDstStatus: listItem.order(status), remote: true, successHandler{switchedListItem in
    //     //    QL1("Undo successful")
    //     //    updateUI()
    //     //})
    }

    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        onSectionSelected(section.section)
    }
    
    func onIncrementItem(_ tableViewListItem: ListItem, delta: Float) {
        Prov.listItemsProvider.increment(tableViewListItem, status: status, delta: delta, remote: true, successHandler{incrementedListItem in
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
//            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
//            self?.onTableViewChangedQuantifiables()
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
    
    
    // MARK: - ListItemsEditTableViewDelegateNew
    
    func onListItemsOrderChangedSection(_ tableViewListItems: [ListItem]) {
        fatalError("override")
    }
    
    func onListItemDeleted(indexPath: IndexPath, tableViewListItem: ListItem) {
//        guard let status = currentList else {QL4("No realm data"); return}
        guard let list = currentList else {QL4("No list"); return}
        guard let realmData = realmData else {QL4("No realm data"); return}
        
        Prov.listItemsProvider.deleteNew(indexPath: indexPath, status: status, list: list, realmData: realmData, resultHandler(onSuccess: {[weak self] result in
            self?.onTableViewChangedQuantifiables()
            
            // NOTE: Assumes that Provider's deleteNew is synchronous
            if result.deletedSection {
                self?.listItemsTableViewController.deleteSection(index: indexPath.section)
            }
            
            }, onErrorAdditional: {[weak self] result in
                self?.updatePossibleList()
            }
        ))
//        Prov.listItemsProvider.remove(tableViewListItem, remote: true, token: RealmToken(token: notificationToken, realm: realm), resultHandler(onSuccess: {[weak self] in
//            self?.onTableViewChangedQuantifiables()
//            }, onErrorAdditional: {[weak self] result in
//                self?.updatePossibleList()
//            }
//        ))
    }
    
    func onListItemMoved(from: IndexPath, to: IndexPath) {
        guard from != to else {QL1("Nothing to move"); return}
        
        guard let list = currentList else {QL4("No list"); return}
        guard let realmData = realmData else {QL4("No realm data"); return}

        Prov.listItemsProvider.move(from: from, to: to, status: status, list: list, realmData: realmData, resultHandler(onSuccess: {result in
            delay(0.4) {
                // show possible changes, e.g. new section color, deleted section (when it's left empty)
                //            tableView.reloadRows(at: [destinationIndexPath], with: .none) // for now we reload complete tableview, when section is left empty it also has to be removed
                self.listItemsTableViewController.reload()
            }
            
            
            }, onErrorAdditional: {[weak self] result in
                self?.updatePossibleList()
            }
        ))
    }
    
    /**
     Update price labels (total, done) using state in provider
     */
    func updatePrices(_ listItemsFetchMode: ProviderFetchModus = .both) {
        // override
        QL3("No override for updatePrices")
    }
    
    fileprivate func addItem(_ listItemInput: ListItemInput, successHandler handler: VoidFunction? = nil) {
        
        guard let realmData = realmData else {QL4("No realm data"); return}
        
        
        func onAddSuccess(result: AddListItemResult) {
            
            let indexPath = IndexPath(row: result.listItemIndex, section: result.sectionIndex)
            if result.isNewItem {
                listItemsTableViewController.addRow(indexPath: indexPath, isNewSection: result.isNewSection)
            } else {
                listItemsTableViewController.updateRow(indexPath: indexPath)
            }
            listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: Theme.defaultRowPosition, animated: true)
            
            updateEmptyUI()
        }
        
        if let currentList = self.currentList {
            Prov.listItemsProvider.addNew(listItemInput: listItemInput, list: currentList, status: status, realmData: realmData, successHandler {result in
                onAddSuccess(result: result)
                handler?() // TODO!!!!!!!!!! whats this for?
            })
            //Prov.listItemsProvider.add(listItemInput, status: status, list: currentList, order: nil, possibleNewSectionOrder: ListItemStatusOrder(status: status, order: listItemsTableViewController.sections.count), token: RealmToken(token: notificationToken, realm: realm), successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
            //    self?.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
            //    handler?() // TODO!!!!!!!!!! whats this for?
            //})
            
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
    fileprivate func updateItem(_ updatingListItem: ListItem, listItemInput: ListItemInput) {
        guard let realmData = realmData else {QL4("No realm data"); return}
        
        if let currentList = self.currentList {
            
            Prov.listItemsProvider.updateNew(listItemInput, updatingListItem: updatingListItem, status: status, list: currentList, realmData: realmData, successHandler {[weak self] updateResult in guard let weakSelf = self else {return}
                if updateResult.replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
                    weakSelf.updatePossibleList()
                } else {
                    // TODO!!!!!!!!!!!!!!!!!
//                    weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
                    //                    self?.updatePrices(.MemOnly)
                    
                    // If as part of the update user entered a different section, we have to update both the src and dst sections
                    // This takes into account that dst section is a new one - since Realm's results are already updated, we will find the returned section in the table view controller's sections result and be able to reload it in the table view.
                    if updateResult.changedSection {
                        weakSelf.listItemsTableViewController.updateTableViewSection(section: updatingListItem.section)
                        weakSelf.listItemsTableViewController.updateTableViewSection(section: updateResult.listItem.section)
                        
                    } else {
                        weakSelf.listItemsTableViewController.updateListItemCell(listItem: updateResult.listItem)
                    }
                    
                    weakSelf.onTableViewChangedQuantifiables()
                }
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
        if let list = currentList {
            
            // TODO save "group list item" don't desintegrate group immediatly
            
            
            Prov.listItemsProvider.addGroupItems(group, status: status, list: list, resultHandler(onSuccess: {[weak self] addedListItems in
                if let list = self?.currentList {
                    self?.initWithList(list) // refresh list items
//                    if let firstListItem = addedListItems.first {
//                        //    TODO!!!!!!!!!!!!!!!! ?
////                        self?.listItemsTableViewController.scrollToListItem(firstListItem)
//                    } else {
//                        QL3("Shouldn't be here without list items")
//                    }
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
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        guard let list = currentList else {QL4("No list"); return}
        guard let realmData = realmData else {QL4("No realm data"); return}

        let listItemInputs = ingredientModels.map {model in
            
            ListItemInput(
                name: model.productPrototype.name,
                quantity: model.quantity,
                price: -1, // No prices here - use existing store product or default for new store product
                section: model.ingredient.item.category.name,
                sectionColor: model.ingredient.item.category.color,
                note: nil,
                baseQuantity: model.productPrototype.baseQuantity,
                unit: model.productPrototype.unit,
                brand: model.productPrototype.brand
            )
        }
        
        Prov.listItemsProvider.addNew(listItemInputs: listItemInputs, list: list, status: status, realmData: realmData, successHandler {_ in
            // The list will update automatically with realm notification
            quickAddController.closeRecipeController()
        })
        
        //Prov.listItemsProvider.add(listItemInputs, status: .todo, list: list, order: nil, possibleNewSectionOrder: nil, token: nil, successHandler{(addedListItems: [ListItem]) in
        //    // The list will update automatically with realm notification
        //    quickAddController.closeRecipeController()
        //})
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        guard let list = currentList else {QL4("No list"); return}
        
        Prov.listItemsProvider.listItems(list: list, ingredient: ingredient, mapper: {listItems -> String in
            if listItems.isEmpty {
                return ""
            } else {
                return trans("recipe_already_has", listItems.map{$0.quantityTextWithoutName()}.joined(separator: ", "))
            }
        }, successHandler {text in
            handler(text)
        })
    }
    
    
    override func onAddProduct(_ product: QuantifiableProduct, quantity: Float) {
        guard let realmData = realmData else {QL4("No realm data"); return}
     
        if let list = currentList {
            
            // TODO!!!!!!!!!!! review if (in other places, here we do after) it's ok to manipulate table view before doing the realm operation or if we should rather wait for realm, otherwise we may get crash when realm fails
            
            // TODO!!!!!!!!!!! don't pass store, list has the store!
            Prov.listItemsProvider.addNew(quantifiableProduct: product, store: list.store ?? "", list: list, quantity: quantity, status: status, realmData: realmData, successHandler {[weak self] (addResult: AddListItemResult) in
                
                let indexPath = IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex)
                if addResult.isNewItem {
                    self?.listItemsTableViewController.addRow(indexPath: IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex), isNewSection: addResult.isNewSection)
                } else {
                    self?.listItemsTableViewController.updateRow(indexPath: IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex))
                }
                self?.listItemsTableViewController.tableView.scrollToRow(at: indexPath, at: Theme.defaultRowPosition, animated: true)

                self?.updateEmptyUI()
            })
//            Prov.listItemsProvider.addListItem(product, status: status, sectionName: product.product.category.name, sectionColor: product.product.category.color, quantity: 1, list: list, note: nil, order: nil, storeProductInput: nil, token: token, successHandler {[weak self] savedListItem in guard let weakSelf = self else {return}
//                weakSelf.onListItemAddedToProvider(savedListItem, status: weakSelf.status, scrollToSelection: true)
//            })
        } else {
            QL4("Add product from quick list but there's no current list in ViewController'")
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
                QL4("Cast didn't work: \(editingItem)")
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
                            QL4("No section or category found with name: \(name) in list: \(list)") // if it's in the autocompletions it must be either the name of a section or category so we should have found one of these
                        }
                    })
                }
            })
        } else {
            QL4("Invalid state: retrieving section color for add/edit but list is not set")
        }
    }
    
    override func onRemovedSectionCategoryName(_ name: String) {
        updatePossibleList()
    }
    
    override func onRemovedBrand(_ name: String) {
        updatePossibleList()
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
                QL1("Repeating current state, return")
                lockToggleSectionsTableView = false
                return
            }
            
            if reorderSections { // show reorder sections table view.
                
                listItemsTableViewController.setAllSectionsExpanded(false, animated: true, onComplete: { // collapse - add sections table view
                    let sectionsTableViewController = UIStoryboard.reorderSectionTableViewControllerNew()
                    
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
                        self.listItemsTableViewController.setAllSectionsExpanded(true, animated: true)
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
        // TODO!!!!!!!!!!!!!!!!!!!!!
//        listItemsTableViewController.removeSection(section.uuid)
        Prov.sectionProvider.remove(section, remote: true, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.updatePossibleList()
            }
        ))
    }
    
    override func back() {
        super.back()
        topEditSectionControllerManager?.controller?.onClose()
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
