//
//  ExpandableTableViewListModel.swift
//  shoppin
//
//  Created by ischuetz on 16/12/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

class ExpandableTableViewListModel: ExpandableTableViewModel {
    
    let list: List
    
    init (list: List) {
        self.list = list
    }
    
    override var name: String {
        return list.name
    }
    
    override var subtitle: String? {
        return list.store
    }
    
    override var bgColor: UIColor {
        return list.bgColor
    }
    
    override var users: [SharedUser] {
        return list.users
    }
    
    override func same(rhs: ExpandableTableViewModel) -> Bool {
        return list.same((rhs as! ExpandableTableViewListModel).list)
    }
    
    override var debugDescription: String {
        return list.debugDescription
    }
}

class ListsTableViewController: ExpandableItemsTableViewController, AddEditListControllerDelegate, ExpandableTopViewControllerDelegate {

    var topAddEditListControllerManager: ExpandableTopViewController<AddEditListController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Lists")        

        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketList:", name: WSNotificationName.List.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketLists:", name: WSNotificationName.Lists.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onListInvitationAccepted:", name: Notification.ListInvitationAccepted.rawValue, object: nil)
        
        initGlobalTabBar() // since ListsTableViewController is the always the first controller (that shows a tabbar) init tabBar insets here. Tried to do this in AppDelegate with root controller it doesn't have tabBarController.
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func initGlobalTabBar() {
        if let tabBar = tabBarController?.tabBar {
            for tabBarItem in tabBar.items! {
                tabBarItem.title = ""
                // Center images (otherwise space for text stays), src http://stackoverflow.com/questions/26494130/remove-tab-bar-item-text-show-only-image
                // TODO calculate inset dynamically if possible, can we get dynamically the height of the images?
                tabBarItem.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
            }
        } else {
            QL4("Couldn't set tabitems appearance, tabBar is nil")
        }
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditListController> {
        let top = CGRectGetHeight(topBar.frame)
        let expandableTopViewController: ExpandableTopViewController<AddEditListController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight + 40, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditList()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ListsTableViewController2.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = false
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    override func canRemoveModel(model: ExpandableTableViewModel, can: Bool -> Void) {
        let list = (model as! ExpandableTableViewListModel).list
        if list.users.count > 1 { // myself + 1
            ConfirmationPopup.show(title: "!", message: "This will remove the list '\(list.name)' also for the other participants (\(list.users.count - 1)).\nIf you wish to only remove yourself as a participant please edit the list participants instead.", okTitle: "Remove list", cancelTitle: "Cancel", controller: self, onOk: {
                can(true)
                }, onCancel: {
                    can(false)
            })
        } else {
            can(true)
        }
    }
    
    override func initModels() {
        Providers.listProvider.lists(true, successHandler{[weak self] lists in
            self?.models = lists.map{ExpandableTableViewListModel(list: $0)}
//            self?.debugItems()
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        super.onSelectCellInEditMode(model)
        
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewListModel).list
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }

    override func onReorderedModels() {
        let lists = (models as! [ExpandableTableViewListModel]).map{$0.list}
        
        let reorderedLists = lists.mapEnumerate{index, list in list.copy(order: index)}
        let orderUpdates = reorderedLists.map{list in OrderUpdate(uuid: list.uuid, order: list.order)}

        models = reorderedLists.map{ExpandableTableViewListModel(list: $0)}
        
        Providers.listProvider.updateListsOrder(orderUpdates, remote: true, successHandler{
        })
    }
    
    override func onRemoveModel(model: ExpandableTableViewModel) {
        Providers.listProvider.remove((model as! ExpandableTableViewListModel).list, remote: true, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.initModels()
                self?.defaultErrorHandler()(providerResult: result)
            }
        ))
    }
    
    override func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.todoItemsViewController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true

        listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, list has to be set first for topbar dot to be positioned correctly right of the title
            listItemsController.currentList = (model as! ExpandableTableViewListModel).list
            listItemsController.setThemeColor(cell.backgroundColor!)
        }
        
        listItemsController.onViewDidAppear = {
            listItemsController.onExpand(true)
        }

        return listItemsController
    }

    override func onAddTap(rotateTopBarButton: Bool = true) {
        super.onAddTap()
        SizeLimitChecker.checkListItemsSizeLimit(models.count, controller: self) {[weak self] in
            if let weakSelf = self {
                let expand = !(weakSelf.topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                weakSelf.topAddEditListControllerManager?.expand(expand)
                if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
                    weakSelf.setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
                }
            }
        }
    }
    
    // MARK: - AddEditListControllerDelegate
    //sub?
    func onListAdded(list: List) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewListModel(list: list))
                self?.topAddEditListControllerManager?.expand(false)
                self?.setTopBarState(.NormalFromExpanded)
            }
        }
    }

    func onListUpdated(list: List) {
        models.update(ExpandableTableViewListModel(list: list))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
        setTopBarState(.NormalFromExpanded)
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    override func onExpandableClose() {
        super.onExpandableClose()
        setTopBarState(.NormalFromExpanded)
    }
    
    // MARK:

    override func onExpand(expanding: Bool) {
    }
    
    private func debugItems() {
        if QorumLogs.minimumLogLevelShown < 2 {
            print("Lists:")
            (models as! [ExpandableTableViewListModel]).forEach{print("\($0.list.shortDebugDescription)")}
        }
    }

    // MARK: - Websocket
    
    func onWebsocketList(note: NSNotification) {
        
        if let info = note.userInfo as? Dictionary<String, WSNotification<List>> {
            if let notification = info[WSNotificationValue] {
                let list = notification.obj
                switch notification.verb {
                case .Add:
                    onListAdded(list)
                case .Update:
                    onListUpdated(list)
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                let listUuid = notification.obj
                switch notification.verb {
                case .Delete:
                    if let model = ((models as! [ExpandableTableViewListModel]).filter{$0.list.uuid == listUuid}).first {
                        removeModel(model)
                    } else {
                        QL3("Received notification to remove list but it wasn't in table view. Uuid: \(listUuid)")
                    }
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("userInfo not there or couldn't be casted: \(note.userInfo)")
        }
    }
    
    func onWebsocketLists(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<[RemoteOrderUpdate]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Order:
                    initModels()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
        }
    }

    func onListInvitationAccepted(note: NSNotification) {
        initModels()
    }
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        initModels()
    }
}