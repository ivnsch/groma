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
    
    override var users: [SharedUser] {
        return []
    }
    
    override func same(rhs: ExpandableTableViewModel) -> Bool {
        return group.same((rhs as! ExpandableTableViewGroupModel).group)
    }
}

class GroupsController: ExpandableItemsTableViewController, AddEditGroupControllerDelegate, ExpandableTopViewControllerDelegate {
    
    private var editButton: UIBarButtonItem!
    
    var expandDelegate: Foo?
    
    private var topAddEditListControllerManager: ExpandableTopViewController<AddEditGroupViewController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Groups")
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketGroup:", name: WSNotificationName.Group.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onIncomingGlobalSyncFinished:", name: WSNotificationName.IncomingGlobalSyncFinished.rawValue, object: nil)    
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: 60, parentViewController: self, tableView: tableView) {[weak self] in
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
        Providers.listItemGroupsProvider.groups(NSRange(location: 0, length: 1000), sortBy: .Order, successHandler{[weak self] groups in
            self?.models = groups.map{ExpandableTableViewGroupModel(group: $0)}
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        super.onSelectCellInEditMode(model)
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewGroupModel).group
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func onReorderedModels() {
        // TODO groups don't support reordering yet (also not in server)
        let groups = (models as! [ExpandableTableViewGroupModel]).map{$0.group}

        let updatedGroups = groups.mapEnumerate{index, group in group.copy(order: index)}
        
        Providers.listItemGroupsProvider.update(updatedGroups, remote: true, successHandler{
//            self.models = models // REVIEW remove? this seem not be necessary...
        })
    }
    
    override func onRemoveModel(model: ExpandableTableViewModel) {
        Providers.listItemGroupsProvider.remove((model as! ExpandableTableViewGroupModel).group, remote: true, resultHandler(onSuccess: {
            }, onError: {[weak self] result in
                self?.initModels()
                self?.defaultErrorHandler()(providerResult: result)
            }
        ))
    }
    
    override func initDetailController(cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.groupItemsController()
        listItemsController.view.frame = view.frame
        addChildViewController(listItemsController)
        listItemsController.expandDelegate = self
        listItemsController.view.clipsToBounds = true
        
        listItemsController.onViewWillAppear = { // FIXME crash here once when tapped on "edit"
            listItemsController.setThemeColor(cell.backgroundColor!)
            listItemsController.group = (model as! ExpandableTableViewGroupModel).group //change
            listItemsController.onExpand(true)
        }
        
        return listItemsController
    }
    
    override func onAddTap(rotateTopBarButton: Bool = true) {
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
    
    func setThemeColor(color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.whiteColor()
    }
    
    
    // We have to do this programmatically since our storyboard does not contain the nav controller, which is in the main storyboard ("more"), thus the nav bar in our storyboard is not used. Maybe there's a better solution - no time now
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                buttons.append(button)
            case .Edit:
                let button = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "onEditTap:")
                self.editButton = button
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onPullToAdd() {
        onAddTap(false)
    }
    
    // MARK: - EditListViewController
    //change
    func onGroupAdded(list: ListItemGroup) {
        tableView.wrapUpdates {[weak self] in
            if let weakSelf = self {
                self?.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: weakSelf.models.count, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Top)
                self?.models.append(ExpandableTableViewGroupModel(group: list))
                self?.topAddEditListControllerManager?.expand(false)
                self?.setTopBarState(.NormalFromExpanded)
            }
        }
    }
    
    func onGroupUpdated(list: ListItemGroup) {
        models.update(ExpandableTableViewGroupModel(group: list))
        tableView.reloadData()
        topAddEditListControllerManager?.expand(false)
    }
    
    // MARK: - ExpandableTopViewControllerDelegate
    
    func animationsForExpand(controller: UIViewController, expand: Bool, view: UIView) {
    }
    
    func onExpandableClose() {
        setTopBarState(.NormalFromExpanded)
    }
    
    // MARK: - Websocket
    
    func onWebsocketGroup(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<ListItemGroup>> {
            if let notification = info[WSNotificationValue] {
                let group = notification.obj
                switch notification.verb {
                case .Add:
                    onGroupAdded(group)
                case .Update:
                    Providers.listItemGroupsProvider.update(group, remote: false, successHandler{[weak self] in
                        self?.onGroupUpdated(group)
                    })
                default: QL4("Not handled case: \(notification.verb))")
                }
            } else {
                QL4("No value")
            }
            
        } else if let info = note.userInfo as? Dictionary<String, WSNotification<String>> {
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
    
    func onIncomingGlobalSyncFinished(note: NSNotification) {
        // TODO notification - note has the sender name
        initModels()
    }
}