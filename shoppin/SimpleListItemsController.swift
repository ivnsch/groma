//
//  SimpleListItemsController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 02/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import CoreData
import SwiftValidator
import ChameleonFramework
import QorumLogs
import Providers
import RealmSwift

class SimpleListItemsController: ItemsController, UITextFieldDelegate, UIScrollViewDelegate, ListItemsTableViewDelegateNew, ListItemsEditTableViewDelegateNew {
    
    weak var listItemsTableViewController: SimpleListItemsTableViewController!
    
    
    var currentList: Providers.List? {
        didSet {
            updatePossibleList()
        }
    }
    
    var listItems: RealmSwift.List<ListItem>? {
        return currentList?.listItems(status: status)
    }
    
    var realmData: RealmData?
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
        return currentList?.listItems(status: status).isEmpty ?? true
    }
    
    override var list: Providers.List? {
        return currentList
    }
    
    var tableViewBottomInset: CGFloat {
        return 0
    }
    
    // TODO refactor with ListItemsTableViewControllerNew (duplicate code)
    var cellMode: ListItemCellMode = .note {
        didSet {
            if let cells = tableView.visibleCells as? [ListItemCellNew] {
                for cell in cells {
                    cell.mode = cellMode
                }
            } else {
                QL4("Invalid state, couldn't cast: \(tableView.visibleCells)")
            }
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setEditing(false, animated: false, tryCloseTopViewController: false)
        
        topBar.positionTitleLabelLeft(true, animated: false, withDot: true)

        initEmptyView(line1: trans("empty_list_line1"), line2: trans("empty_list_line2"))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ListItemsController.onListRemovedNotification(_:)), name: NSNotification.Name(rawValue: Notification.ListRemoved.rawValue), object: nil)
    }
    
    
    override func initProgrammaticViews() {
        initTableViewController()
    }
    
    fileprivate func initTableViewController() {
//        listItemsTableViewController = UIStoryboard.listItemsTableViewControllerNew()
        let listItemsTableViewController = SimpleListItemsTableViewController()
        
        addChildViewControllerAndView(listItemsTableViewController, viewIndex: 0)
        
        listItemsTableViewController.status = status
        listItemsTableViewController.scrollViewDelegate = self
        listItemsTableViewController.listItemsTableViewDelegate = self
        listItemsTableViewController.listItemsEditTableViewDelegate = self
        listItemsTableViewController.cellDelegate = self
        
        let navbarHeight = topBar.frame.height
        let topInset = navbarHeight
        let bottomInset: CGFloat = tableViewBottomInset + 10 // 10 - show a little empty space between the last item and the prices view
        listItemsTableViewController.tableView.inset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
        listItemsTableViewController.tableView.topOffset = -listItemsTableViewController.tableView.inset.top
        if isPullToAddEnabled {
            listItemsTableViewController.enablePullToAdd()
        }
        
        // TODO!!!!!!!!!!!!!!!!! still necessary?
//        listItemsTableViewController.cellSwipeDirection = {
//            switch self.status {
//            case .todo: return .right
//            case .done: return .left
//            case .stash: return .left
//            }
//        }()
        
        self.listItemsTableViewController = listItemsTableViewController
    }
    

    deinit {
        QL1("Deinit list items controller")
        NotificationCenter.default.removeObserver(self)
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
        
        listItemsTableViewController.listItems = list.listItems(status: status)
        
        QL1("Initialized listItems: \(listItemsTableViewController.listItems?.count)")
        
        onTableViewChangedQuantifiables()
        
        initNotifications()
    }
    
    fileprivate func initNotifications() {
        
        guard let sections = listItemsTableViewController.listItems else {QL4("No listItems"); return}
        guard let sectionsRealm = sections.realm else {QL4("No realm"); return}
        
        realmData?.token.stop()
        
        let notificationToken = sections.addNotificationBlock {[weak self] changes in guard let weakSelf = self else {return}
            
            switch changes {
            case .initial:
                //                        // Results are now populated and can be accessed without blocking the UI
                //                        self.viewController.didUpdateList(reload: true)
                QL1("initial")
                
            case .update(_, let deletions, let insertions, let modifications):
                QL2("(Simple controller) notification, deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications)")
                
                
                // TODO pass modifications to listItemsTableViewController, don't access table view directly
                weakSelf.listItemsTableViewController.tableView.beginUpdates()
                weakSelf.listItemsTableViewController.tableView.insertRows(at: insertions.map{IndexPath(row: $0, section: 0)}, with: .top)
                weakSelf.listItemsTableViewController.tableView.deleteRows(at: insertions.map{IndexPath(row: $0, section: 0)}, with: .top)
                weakSelf.listItemsTableViewController.tableView.reloadRows(at: insertions.map{IndexPath(row: $0, section: 0)}, with: .none)
//                weakSelf.listItemsTableViewController.tableView.insertSections(IndexSet(insertions), with: .top)
//                weakSelf.listItemsTableViewController.tableView.deleteSections(IndexSet(deletions), with: .top)
//                weakSelf.listItemsTableViewController.tableView.reloadSections(IndexSet(modifications), with: .none)
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

    override func setEditing(_ editing: Bool, animated: Bool, tryCloseTopViewController: Bool) {
        super.setEditing(editing, animated: animated, tryCloseTopViewController: tryCloseTopViewController)
        
        listItemsTableViewController.setEditing(editing, animated: animated)
        listItemsTableViewController.cellMode = editing ? .increment : .note

    }
    
    override func openQuickAdd(rotateTopBarButton: Bool = true, itemToEdit: AddEditItem? = nil) {
        super.openQuickAdd(rotateTopBarButton: rotateTopBarButton, itemToEdit: itemToEdit)
    }
    
    
    // MARK: - ListItemsTableViewDelegateNew
    
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
                let targetStatus: ListItemStatus = {
                    switch weakSelf.status {
                    case .todo: return .done
                    case .done: return .todo
                    case .stash: return .todo
                    }
                }()
                
                // NOTE: For the provider the whole state is updated here - including possible section removal (if the current undo list item is the last one in the section) and the order field update of possible following sections. This means that the contents of the table view may be in a slightly inconsistent state with the data in the provider during the time cell is in undo (for the table view the section is still there, for the provider it's not). This is fine as the undo state is just a UI thing (local) and it should be cleared as soon as we try to start a new action (add, edit, delete, reorder etc) or go to the cart/stash.
                
                
                Prov.listItemsProvider.switchCartToTodoSync(listItem: tableViewListItem, from: indexPath, realmData: realmData, weakSelf.successHandler{[weak self] switchedListItem in
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

    
    func onIncrementItem(_ tableViewListItem: ListItem, delta: Int) {
        Prov.listItemsProvider.increment(tableViewListItem, status: status, delta: delta, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
            //            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
            //            self?.onTableViewChangedQuantifiables()
        })
    }
    
    // For now we re-use the delegate from ListItemsTableViewControllerNew which largely meets our requirements here, except of this method
    func onSectionHeaderTap(_ header: ListItemsSectionHeaderView, section: ListItemsViewSection) {
        fatalError("Not supported")
    }
    
    
    // MARK: -

    
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
        
        if let currentList = self.currentList {
            Prov.listItemsProvider.addNew(listItemInput: listItemInput, list: currentList, status: status, realmData: realmData, successHandler {[weak self] tuple in guard let weakSelf = self else {return}
                self?.onListItemAddedToProvider(tuple.listItem, status: weakSelf.status, scrollToSelection: true)
                handler?() // TODO!!!!!!!!!! whats this for?
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
    fileprivate func updateItem(_ updatingListItem: ListItem, listItemInput: ListItemInput) {
        if let currentList = self.currentList {
            
            Prov.listItemsProvider.update(listItemInput, updatingListItem: updatingListItem, status: status, list: currentList, true, successHandler {[weak self] (listItem, replaced) in guard let weakSelf = self else {return}
                if replaced { // if an item was replaced (means: a previous list item with same unique as the updated item already existed and was removed from the list) reload list items to get rid of it. The item can be in a different status though, in which case it's not necessary to reload the current list but for simplicity we always do it.
                    weakSelf.updatePossibleList()
                } else {
                    // TODO!!!!!!!!!!!!!!!!!
                    //                    weakSelf.listItemsTableViewController.updateListItem(listItem, status: weakSelf.status, notifyRemote: true)
                    //                    self?.updatePrices(.MemOnly)
                    weakSelf.onTableViewChangedQuantifiables()
                }
                weakSelf.closeTopControllers()
            })
        } else {
            print("Error: Invalid state: trying to update list item without current list")
        }
        
    }
    
    
    // MARK: - QuickAddDelegate

    
    override func onAddGroup(_ group: ProductGroup, onFinish: VoidFunction?) {
        if let list = currentList {
            
            // TODO save "group list item" don't desintegrate group immediatly
            
            
            Prov.listItemsProvider.addGroupItems(group, status: status, list: list, resultHandler(onSuccess: {[weak self] addedListItems in
                if let list = self?.currentList {
                    self?.initWithList(list) // refresh list items
                    if let firstListItem = addedListItems.first {
                        //    TODO!!!!!!!!!!!!!!!! ?
                        //                        self?.listItemsTableViewController.scrollToListItem(firstListItem)
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
    
    override func onAddRecipe(ingredientModels: [AddRecipeIngredientModel], quickAddController: QuickAddViewController) {
        guard let list = currentList else {QL4("No list"); return}
        guard let realmData = realmData else {QL4("No realm data"); return}
        
        let listItemInputs = ingredientModels.map {model in
            
            ListItemInput(
                name: model.productPrototype.name,
                quantity: model.quantity,
                price: -1, // No prices here - use existing store product or default for new store product
                section: model.ingredient.product.product.category.name,
                sectionColor: model.ingredient.product.product.category.color,
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
    }
    
    override func getAlreadyHaveText(ingredient: Ingredient, _ handler: @escaping (String) -> Void) {
        guard let list = currentList else {QL4("No list"); return}
        
        Prov.listItemsProvider.listItems(list: list, ingredient: ingredient, mapper: {listItems -> String in
            if listItems.isEmpty {
                return ""
            } else {
                return trans("recipe_already_has", listItems.map{$0.quantityTextWithoutName(status: self.status)}.joined(separator: ", "))
            }
        }, successHandler {text in
            handler(text)
        })
    }
    
    
    override func onAddProduct(_ product: QuantifiableProduct) {
        guard let realmData = realmData else {QL4("No realm data"); return}
        
        if let list = currentList {
            
            // TODO!!!!!!!!!!! review if (in other places, here we do after) it's ok to manipulate table view before doing the realm operation or if we should rather wait for realm, otherwise we may get crash when realm fails
            
            // TODO!!!!!!!!!!! don't pass store, list has the store!
            Prov.listItemsProvider.addNew(quantifiableProduct: product, store: list.store ?? "", list: list, quantity: 1, status: status, realmData: realmData, successHandler {[weak self] (addResult: AddListItemResult) in
                
                if addResult.isNewItem {
                    self?.listItemsTableViewController.addRow(indexPath: IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex), isNewSection: addResult.isNewSection)
                } else {
                    self?.listItemsTableViewController.updateRow(indexPath: IndexPath(row: addResult.listItemIndex, section: addResult.sectionIndex))
                }
                
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


extension SimpleListItemsController: ListItemCellDelegateNew {
    
    func onItemSwiped(_ listItem: ListItem) {
        // TODO!!!!!!!!!!!!!!!!!!! move item to .todo - (note swipe in this case is to the left)
    }
    
    func onStartItemSwipe(_ listItem: ListItem) {
        // Do nothing
    }
    
    func onButtonTwoTap(_ listItem: ListItem) {
        // Do nothing
    }
    
    func onNoteTap(_ cell: ListItemCellNew, listItem: ListItem) {
        if !listItem.note.isEmpty {
            if let noteButton = cell.noteButton {
                showPopup(text: listItem.note, cell: cell, button: noteButton)
            } else {
                QL3("No note button")
            }
        } else {
            QL4("Invalid state: There's no note. When there's no note there should be no button so we shouldn't be here.")
        }
    }
    
    func onMinusTap(_ listItem: ListItem) {
        Prov.listItemsProvider.increment(listItem, status: status, delta: -1, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
            //            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
            //            self?.onTableViewChangedQuantifiables()
        })
    }
    
    func onPlusTap(_ listItem: ListItem) {
        Prov.listItemsProvider.increment(listItem, status: status, delta: 1, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
            //            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
            //            self?.onTableViewChangedQuantifiables()
        })
    }
    
    func onPanQuantityUpdate(_ tableViewListItem: ListItem, newQuantity: Int) {
        Prov.listItemsProvider.increment(tableViewListItem, status: status, delta: newQuantity - tableViewListItem.quantity, remote: true, successHandler{[weak self] incrementedListItem in guard let weakSelf = self else {return}
            // TODO!!!!!!!!!!!!!!!!! should we maybe do increment in advance like everything else? otherwise adapt
            //            self?.listItemsTableViewController.updateOrAddListItem(incrementedListItem, status: weakSelf.status, increment: false, notifyRemote: false)
            //            self?.onTableViewChangedQuantifiables()
        })
    }
}






class SimpleListItemsTableViewController: UITableViewController {
    
    var listItems: RealmSwift.List<ListItem>? {
        didSet {
            tableView.reloadData()
        }
    }
    var status: ListItemStatus = .done
    var cellMode: ListItemCellMode = .increment
    
    weak var listItemsTableViewDelegate: ListItemsTableViewDelegateNew?
    weak var cellDelegate: ListItemCellDelegateNew?
    weak var scrollViewDelegate: UIScrollViewDelegate?
    weak var listItemsEditTableViewDelegate: ListItemsEditTableViewDelegateNew?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "ListItemCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listItems?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListItemCellNew
        
        if let listItem = listItems?[indexPath.row], let cellDelegate = cellDelegate {
            cell.setup(status, mode: cellMode, tableViewListItem: listItem, delegate: cellDelegate)
            
        } else {
            QL4("Invalid state: no listitem for: \(indexPath) or no cell delegate: \(cellDelegate)")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            guard let listItem = listItems?[indexPath.row] else {QL4("No listItem"); return}
            
            tableView.beginUpdates()
            
            // remove from content provider
            listItemsEditTableViewDelegate?.onListItemDeleted(indexPath: indexPath, tableViewListItem: listItem)
            
            // remove from tableview and model
            tableView.deleteRows(at: [indexPath], with: .top)
            
            tableView.endUpdates()
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isEditing
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        listItemsEditTableViewDelegate?.onListItemMoved(from: sourceIndexPath, to: destinationIndexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let listItem = listItems?[indexPath.row] else {QL4("No listItem"); return}
        listItemsTableViewDelegate?.onListItemSelected(listItem, indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    // MARK: - Pull to refresh
    
    func enablePullToAdd() {
        let refreshControl = PullToAddHelper.createPullToAdd(self)
        refreshControl.addTarget(self, action: #selector(onPullRefresh(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    func onPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        listItemsTableViewDelegate?.onPullToAdd()
    }
    
    // MARK: - Scrolling
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    // MARK: - Etc
    
    /**
     Sets pending item (mark as undo" if open and shows cell open state. Submits currently pending item if existent.
     parameter onFinish: After cell marked open and automatic update of possible second "undo" item (to "done").
     // TODO!!!! remove notify remote parameter, this is necessary anymore
     */
    func markOpen(_ open: Bool, indexPath: IndexPath, notifyRemote: Bool, onFinish: VoidFunction? = nil) {
        //TODO!!!!!!!!!!!!!!!!! new animation with green background and direct removal from table view. No undo. Rename method and adjust parameters
        
        // if let section = self.tableViewSections[safe: (indexPath as NSIndexPath).section], let tableViewListItem = section.tableViewListItems[safe: (indexPath as NSIndexPath).row] {
        //     // Note: order is important here! first show open at current index path, then remove possible pending (which can make indexPath invalid, thus later), then update pending variable with new item
        //     self.showCellOpen(open, indexPath: indexPath)
        //     self.clearPendingSwipeItemIfAny(notifyRemote) {
        //         self.swipedTableViewListItem = tableViewListItem
        onFinish?()
        //     }
        
        // } else {
        //     QL3("markOpen: \(open), self not set or indexPath not found: \(indexPath)")
        // }
    }
}
