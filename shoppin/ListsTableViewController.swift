//
//  ExpandableTableViewListModel.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import RealmSwift
import Providers

class ExpandableTableViewListModel: ExpandableTableViewModel {
    
    let list: Providers.List
    
    init (list: Providers.List) {
        self.list = list
    }
    
    override var name: String {
        return list.name
    }
    
    override var subtitle: String? {
        return list.store
    }
    
    override var bgColor: UIColor {
        return list.color
    }
    
    override var users: [DBSharedUser] {
        return list.users.toArray()
    }
    
    override func same(_ rhs: ExpandableTableViewModel) -> Bool {
        return list.same((rhs as! ExpandableTableViewListModel).list)
    }
    
    override var debugDescription: String {
        return list.debugDescription
    }
}

class ListsTableViewController: ExpandableItemsTableViewController, AddEditListControllerDelegate, ExpandableTopViewControllerDelegate {

    fileprivate var listsResult: RealmSwift.List<Providers.List>? {
        didSet {
            tableView.reloadData()
            updateEmptyUI()
        }
    }
    fileprivate var notificationToken: NotificationToken?
    
    var topAddEditListControllerManager: ExpandableTopViewController<AddEditListController>?

    var canLoadModelsOnWillAppear = false

    override var emptyViewLabels: (label1: String, label2: String) {
        return (label1: trans("empty_lists_line1"), label2: trans("empty_lists_line2"))
    }
    
    override var isAnyTopControllerExpanded: Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_lists"))

        topAddEditListControllerManager = initTopAddEditListControllerManager()
        
        initGlobalTabBar() // since ListsTableViewController is the always the first controller (that shows a tabbar) init tabBar insets here. Tried to do this in AppDelegate with root controller it doesn't have tabBarController.

        Notification.subscribe(.realmSwapped, selector: #selector(ListsTableViewController.onRealmSwapped(_:)), observer: self)
        Notification.subscribe(.willClearAllData, selector: #selector(ListsTableViewController.onWillClearAllData(_:)), observer: self)
    }

    @objc func onRealmSwapped(_ note: Foundation.Notification) {
        closeListItemsController()
        initModels()
    }

    @objc func onWillClearAllData(_ note: Foundation.Notification) {
        // Exit items view such that there will be no realm exceptions, because the items reference deleted objects
        closeListItemsController()
        initModels()
    }

    deinit {
        logger.v("Deinit lists controller")
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func initGlobalTabBar() {
        if let tabBar = tabBarController?.tabBar {
            for tabBarItem in tabBar.items! {
                tabBarItem.title = ""
                // Center images (otherwise space for text stays), src http://stackoverflow.com/questions/26494130/remove-tab-bar-item-text-show-only-image
                // TODO calculate inset dynamically if possible, can we get dynamically the height of the images?
                tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
            }
        } else {
            logger.e("Couldn't set tabitems appearance, tabBar is nil")
        }
    }
    
    override func onPullToAdd() {
        showAddEditController(rotateTopBarButton: false)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditListController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditListController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight + 40, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.addEditList()
            controller.delegate = self
            controller.currentListsCount = self?.itemsCount ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = false
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    override func canRemoveModel(_ model: ExpandableTableViewModel, can: @escaping (Bool) -> Void) {
        let list = (model as! ExpandableTableViewListModel).list
        if list.users.count > 1 { // myself + 1
            ConfirmationPopup.show(title: trans("popup_title_warning"), message: trans("popup_remove_list_warning", list.name), okTitle: trans("popup_button_remove_list"), cancelTitle: trans("popup_button_cancel"), controller: self, onOk: {
                can(true)
                }, onCancel: {
                    can(false)
            })
        } else {
            can(true)
        }
    }
    
    override func initModels() {

        Prov.listProvider.lists(true, successHandler{[weak self] lists in guard let weakSelf = self else {return}
//            self?.models = lists.map{ExpandableTableViewListModel(list: $0)}
//            self?.debugItems()
            
            
            weakSelf.listsResult = lists
            
            self?.notificationToken = lists.observe { changes in
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    logger.v("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications), count: \(String(describing: weakSelf.listsResult?.count))")
                    
                    weakSelf.tableView.beginUpdates()
                    weakSelf.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .top)
                    weakSelf.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                    weakSelf.tableView.endUpdates()
                    
//                    // TODO close only when receiving own notification, not from someone else (possible?)
//                    weakSelf.topAddEditListControllerManager?.expand(false)
//                    weakSelf.setTopBarState(.normalFromExpanded)

                    
                case .error(let error):
                    // An error occurred while opening the Realm file on the background worker thread
                    fatalError(String(describing: error))
                }
            }
            
//            weakSelf.models = lists.map{ExpandableTableViewListModel(list: $0)} // TODO use results!
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    override func onSelectCellInEditMode(_ model: ExpandableTableViewModel, index: Int) {
        super.onSelectCellInEditMode(model, index: index)
        
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewListModel).list
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.todoItemsViewControllerNew()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true

        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, list has to be set first for topbar dot to be positioned correctly right of the title
            listItemsController?.currentList = (model as! ExpandableTableViewListModel).list
            listItemsController?.setThemeColor(weakCell.backgroundColor!)
            listItemsController?.onExpand(true)
            // This has to be after onExpand so it gets the updated navbar frame height! (which is set in positionTitleLabelLeft...)
            listItemsController?.topQuickAddControllerManager = listItemsController?.initTopQuickAddControllerManager()
        }

        return listItemsController
    }
    
    override func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }

    override func openTopController(rotateTopBarButton: Bool = true) {
        super.openTopController(rotateTopBarButton: rotateTopBarButton)
        showAddEditController(rotateTopBarButton: rotateTopBarButton)
    }
    
    override func closeTopControllers(rotateTopBarButton: Bool = true) {
        if topAddEditListControllerManager?.expanded ?? false {
            
            if topAddEditListControllerManager?.controller?.requestClose() ?? true {
                topAddEditListControllerManager?.expand(false)
                onCloseTopControllers(rotateTopBarButton: rotateTopBarButton)
            }
        }
    }
    
    // This is called after close with topbar's x as well as tapping semi transparent overlay. After everything else (rotate top button, close top controllers etc.) was done. Override for custom logic to be executed after closing top controller.
    func onFinishCloseTopControllers() {
        // optional override
    }
    
    fileprivate func showAddEditController(rotateTopBarButton: Bool = true) {
        //        SizeLimitChecker.checkListItemsSizeLimit(models.count, controller: self) {[weak self] in
        //            if let weakSelf = self {
        let expand = !(topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
        topAddEditListControllerManager?.expand(expand)
        if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
            setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
        }
        //            }
        //        }
    }
    
    // MARK: - AddEditListControllerDelegate
    
    func onAddList(_ list: Providers.List) {
        guard let listsResult = listsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}

        Prov.listProvider.add(list, lists: listsResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in

            self?.tableView.insertRows(at: [IndexPath(row: listsResult.count - 1, section: 0)], with: .top) // Note -1 as at this point the new item is already inserted in results

            self?.afterAddOrUpdateList()

            }, onError: {[weak self] result in guard let weakSelf = self else { return }
                if result.status == .nameAlreadyExists {
                    let message = trans("error_list_already_exists", list.name)
                    let ranges = message.range(list.name).map { [$0] } ?? {
                        logger.e("Invalid state list name not contained in: \(message)", .ui)
                        return []
                    } ()

                    let addEditNameInput = weakSelf.topAddEditListControllerManager?.controller?.listNameInputField
                    let currentFirstResponder = (addEditNameInput?.isFirstResponder ?? false) ? addEditNameInput : nil
                    weakSelf.view.endEditing(true)
                    MyPopupHelper.showPopup(parent: weakSelf.root, type: .error, message: message, highlightRanges: ranges, onOkOrCancel: {
                        currentFirstResponder?.becomeFirstResponder()
                    })
                } else {
                    weakSelf.defaultErrorHandler()(result)
                }
                weakSelf.onListAddOrUpdateError(list)
            }
        ))
    }
    
    func onUpdateList(_ list: Providers.List, listInput: ListInput) {
        guard let listsResult = listsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        
        Prov.listProvider.update(list, input: listInput, lists: listsResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            
            var row: Int?
            for (index, item) in listsResult.enumerated() {
                if item.uuid == list.uuid {
                    row = index
                }
            }
            
            if let row = row {
                self?.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            } else {
                logger.e("Invalid state: can't find list: \(list)")
            }
            
            self?.afterAddOrUpdateList()
            
        }, onErrorAdditional: {[weak self] result in
            self?.onListAddOrUpdateError(list)
            }
        ))

    }
    
    fileprivate func afterAddOrUpdateList() {
        topAddEditListControllerManager?.expand(false)
        setTopBarState(.normalFromExpanded)
        updateEmptyUI()
    }

    fileprivate func onListAddOrUpdateError(_ list: Providers.List) {
        initModels()
        // If the user quickly after adding the list opened its list items controller, close it.
        for childViewController in childViewControllers {
            if let todoListItemController = childViewController as? TodoListItemsControllerNew {
                if (todoListItemController.currentList.map{$0.same(list)}) ?? false {
                    todoListItemController.back()
                }
            }
        }
    }

    fileprivate func closeListItemsController() {
        for childViewController in childViewControllers {
            if let todoListItemController = childViewController as? TodoListItemsControllerNew {
                todoListItemController.back()
            }
        }
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(_ controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.normalFromExpanded)
    }
    
    // MARK:

    override func onExpand(_ expanding: Bool) {
    }
    
    
    // New
    
    override func loadModels(onSuccess: @escaping () -> Void) {
        // TODO!!!!!!!!!!!!! on success. Is also this method actually necessary?
        initModels()
    }
    
    override func itemForRow(row: Int) -> ExpandableTableViewModel? {
        guard let listsResult = listsResult else {logger.e("No result"); return nil}
        
        return ExpandableTableViewListModel(list: listsResult[row])
    }
    
    override var itemsCount: Int? {
        guard let listsResult = listsResult else { return nil }
        
        return listsResult.count
    }
    
    override func deleteItem(index: Int) {
        guard let listsResult = listsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}

        Prov.listProvider.delete(index: index, lists: listsResult, notificationToken: notificationToken, resultHandler(onSuccess: {[weak self] in
            self?.updateEmptyUI()
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
    
    override func moveItem(from: Int, to: Int) {
        guard let listsResult = listsResult else {logger.e("No result"); return}
        guard let notificationToken = notificationToken else {logger.e("No notification token"); return}
        
        Prov.listProvider.move(from: from, to: to, lists: listsResult, notificationToken: notificationToken, resultHandler(onSuccess: {
        }, onErrorAdditional: {[weak self] result in
            self?.initModels()
            }
        ))
    }
}
