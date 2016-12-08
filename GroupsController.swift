//
//  GroupsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import QorumLogs

class ExpandableTableViewGroupModel: ExpandableTableViewModel {
    
    let group: ListItemGroup
    
    init (group: ListItemGroup) {
        self.group = group
    }
    
    override var name: String {
        return group.name
    }
    
    override var bgColor: UIColor {
        return group.bgColor
    }
    
    override var users: [DBSharedUser] {
        return []
    }
    
    override func same(_ rhs: ExpandableTableViewModel) -> Bool {
        return group.same((rhs as! ExpandableTableViewGroupModel).group)
    }
    
    override var debugDescription: String {
        return group.debugDescription
    }
}

class GroupsController: ExpandableItemsTableViewController, AddEditGroupControllerDelegate, ExpandableTopViewControllerDelegate {
    
    fileprivate var editButton: UIBarButtonItem!
    
    var expandDelegate: Foo?
    
    fileprivate var topAddEditListControllerManager: ExpandableTopViewController<AddEditGroupViewController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_groups"))
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NotificationCenter.default.addObserver(self, selector: #selector(GroupsController.onWebsocketGroup(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Group.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupsController.onWebsocketGroups(_:)), name: NSNotification.Name(rawValue: WSNotificationName.Groups.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupsController.onIncomingGlobalSyncFinished(_:)), name: NSNotification.Name(rawValue: WSNotificationName.IncomingGlobalSyncFinished.rawValue), object: nil)    
    }
    
    deinit {
        QL1("Deinit groups controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditGroup()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ManageGroupsTmpContainerController.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = false
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    
    override func initModels() {
        Providers.listItemGroupsProvider.groups(NSRange(location: 0, length: 1000), sortBy: .order, successHandler{[weak self] groups in
            self?.models = groups.map{ExpandableTableViewGroupModel(group: $0)}
            self?.debugItems()
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(_ model: ExpandableTableViewModel) {
        super.onSelectCellInEditMode(model)
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewGroupModel).group
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func onReorderedModels() {
        let groups = (models as! [ExpandableTableViewGroupModel]).map{$0.group}
        
        let reorderedGroups = groups.mapEnumerate{index, group in group.copy(order: index)}
        let orderUpdates = reorderedGroups.map{group in OrderUpdate(uuid: group.uuid, order: group.order)}
        
        models = reorderedGroups.map{ExpandableTableViewGroupModel(group: $0)}
        
        Providers.listItemGroupsProvider.updateGroupsOrder(orderUpdates, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.initModels()
            }
        ))
    }
    
    override func onRemoveModel(_ model: ExpandableTableViewModel) {
        Providers.listItemGroupsProvider.remove((model as! ExpandableTableViewGroupModel).group, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.initModels()
            }
        ))
    }
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.groupItemsController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = {[weak listItemsController, weak cell] in guard let weakCell = cell else {return} // FIXME crash here once when tapped on "edit"
            // Note: order of lines important here, group has to be set first for topbar dot to be positioned correctly right of the title
            listItemsController?.group = (model as! ExpandableTableViewGroupModel).group //change
            listItemsController?.setThemeColor(weakCell.backgroundColor!)
            listItemsController?.onExpand(true)
        }
        
        listItemsController.onViewDidAppear = {[weak listItemsController] in
            listItemsController?.onExpand(true)
        }
        
        return listItemsController
    }
    
    override func animationsComplete(_ wasExpanding: Bool, frontView: UIView) {
        super.animationsComplete(wasExpanding, frontView: frontView)
        if !wasExpanding {
            removeChildViewControllers()
        }
    }
    
    override func onAddTap(_ rotateTopBarButton: Bool = true) {
        super.onAddTap()
        SizeLimitChecker.checkGroupsSizeLimit(models.count, controller: self) {[weak self] in
            if let weakSelf = self {
                let expand = !(weakSelf.topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
                weakSelf.topAddEditListControllerManager?.expand(expand)
                if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
                    weakSelf.setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
                }
            }
        }
    }
    
    func setThemeColor(_ color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.white
    }
    
    fileprivate func debugItems() {
        if QorumLogs.minimumLogLevelShown < 2 {
            print("Groups:")
            (models as! [ExpandableTableViewGroupModel]).forEach{print("\($0.group.shortDebugDescription)")}
        }
    }
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    fileprivate func initNavBar(_ actions: [UIBarButtonSystemItem]) {
        navigationItem.title = trans("title_products")
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .add:
                let button = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ExpandableItemsTableViewController.onAddTap(_:)))
                buttons.append(button)
            case .edit:
                let button = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(ExpandableItemsTableViewController.onEditTap(_:)))
                self.editButton = button
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    // MARK: - EditListViewController
    //change
    func onAddGroup(_ group: ListItemGroup) {
        Providers.listItemGroupsProvider.add(group, remote: true, resultHandler(onSuccess: {[weak self] in
            self?.addGroupUI(group)
            }, onErrorAdditional: {[weak self] result in
                self?.onGroupAddOrUpdateError(group)
            }
        ))
    }
    
    func onUpdateGroup(_ group: ListItemGroup) {
        Providers.listItemGroupsProvider.update(group, remote: true, resultHandler(onSuccess: {[weak self] in
            self?.updateGroupUI(group)
            }, onErrorAdditional: {[weak self] result in
                self?.onGroupAddOrUpdateError(group)
            }
        ))
    }
    
    fileprivate func addGroupUI(_ group: ListItemGroup) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRows(at: [IndexPath(row: weakSelf.models.count, section: 0)], with: UITableViewRowAnimation.top)
                self?.models.append(ExpandableTableViewGroupModel(group: group))
                self?.topAddEditListControllerManager?.expand(false)
                self?.setTopBarState(.normalFromExpanded)
            }
        }
    }
    
    fileprivate func updateGroupUI(_ group: ListItemGroup) {
        _ = models.update(ExpandableTableViewGroupModel(group: group))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
        setTopBarState(.normalFromExpanded)
    }
    
    fileprivate func onGroupAddOrUpdateError(_ group: ListItemGroup) {
        initModels()
        // If the user quickly after adding the group opened its group items controller, close it.
        for childViewController in childViewControllers {
            if let groupItemsController = childViewController as? GroupItemsController {
                if (groupItemsController.group.map{$0.same(group)}) ?? false {
                    groupItemsController.back()
                }
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
    
    // MARK: - Websocket
    
    func onWebsocketGroup(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<ListItemGroup>> {
            if let notification = info[WSNotificationValue] {
                let group = notification.obj
                switch notification.verb {
                case .Add:
                    addGroupUI(group)
                case .Update:
                    Providers.listItemGroupsProvider.update(group, remote: false, successHandler{[weak self] in
                        self?.updateGroupUI(group)
                    })
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<String>> {
            if let notification = info[WSNotificationValue] {
                
                let groupUuid = notification.obj
                
                switch notification.verb {
                case .Delete:
                    if let model = ((models as! [ExpandableTableViewGroupModel]).filter{$0.group.uuid == groupUuid}).first {
                        removeModel(model)
                    } else {
                        QL3("Received notification to remove group but it wasn't in table view. Uuid: \(groupUuid)")
                    }
                    
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("No userInfo")
        }
    }
    
    func onWebsocketGroups(_ note: Foundation.Notification) {
        if let info = (note as NSNotification).userInfo as? Dictionary<String, WSNotification<[RemoteOrderUpdate]>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Order:
                    initModels()
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else {
            QL4("userInfo not there or couldn't be casted: \((note as NSNotification).userInfo)")
        }
    }
    
    func onIncomingGlobalSyncFinished(_ note: Foundation.Notification) {
        // TODO notification - note has the sender name
        initModels()
    }
}
