//
//  GroupsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator


class ExpandableTableViewGroupModel: ExpandableTableViewModel {
    
    let group: ListItemGroup
    
    init (group: ListItemGroup) {
        self.group = group
    }
    
    override var name: String {
        return group.name
    }
    
    override var bgColor: UIColor {
        return UIColor.whiteColor()
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
    
    @IBOutlet weak var emptyGroupsView: UIView!
    
    var expandDelegate: Foo?
    
    private var topAddEditListControllerManager: ExpandableTopViewController<AddEditGroupViewController>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle("Groups")
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketGroup:", name: WSNotificationName.Group.rawValue, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = CGRectGetHeight(topBar.frame)
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: 100, parentViewController: self, tableView: tableView) {[weak self] in
            let controller = UIStoryboard.addEditGroup()
            controller.delegate = self
            controller.currentListsCount = self?.models.count ?? {
                print("Error: ManageGroupsTmpContainerController.initTopAddEditListControllerManager: no valid self reference")
                return 0
            }()
            controller.view.clipsToBounds = true
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    
    override func initModels() {
        
        Providers.listItemGroupsProvider.groups(NSRange(location: 0, length: 1000), successHandler{[weak self] groups in
            if let weakSelf = self {
                let models: [ExpandableTableViewModel] = groups.map{ExpandableTableViewGroupModel(group: $0)}
                if weakSelf.models != models {
                    weakSelf.models = models
                    weakSelf.tableView.reloadData()
                }
            }
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(model: ExpandableTableViewModel) {
        super.onSelectCellInEditMode(model)
        topAddEditListControllerManager?.controller?.listToEdit = (model as! ExpandableTableViewGroupModel).group
        topAddEditListControllerManager?.expand(true)
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func onReorderedModels() {
        // TODO groups don't support reordering yet (also not in server)
        //        let lists = (models as! [ExpandableTableViewInventoryModel]).map{$0.inventory}
        //
        //        let updatedLists = lists.mapEnumerate{index, list in list.copy(order: index)}
        //
        //        Providers.inventoryProvider.updateInventories(updatedLists, remote: true, successHandler{//change
        //            //            self?.models = models // REVIEW remove? this seem not be necessary...
        //            })
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
    
    override func onAddTap() {
        super.onAddTap()
        let expand = !(topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
        topAddEditListControllerManager?.expand(expand)
        setTopBarStateForAddTap(expand)
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
                    Providers.listItemGroupsProvider.add(group, remote: false, successHandler {[weak self] in
                        self?.onGroupAdded(group)
                    })
                case .Update:
                    Providers.listItemGroupsProvider.update(group, remote: false, successHandler{[weak self] in
                        self?.onGroupUpdated(group)
                    })
                    
                case .Delete:
                    Providers.listItemGroupsProvider.remove(group, remote: false, successHandler{[weak self] in
                        self?.removeModel(ExpandableTableViewGroupModel(group: group))
                    })
                }
            } else {
                print("Error: ManageGroupsViewController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: ManageGroupsViewController.onWebsocketProduct: no userInfo")
        }
    }
}