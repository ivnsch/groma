//
//  GroupsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

import RealmSwift
import Providers

class ExpandableTableViewGroupModel: ExpandableTableViewModel {
    
    let group: ProductGroup
    
    init (group: ProductGroup) {
        self.group = group
    }
    
    override var name: String {
        return group.name
    }
    
    override var bgColor: UIColor {
        return group.color
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

extension ProductGroup: SimpleFirstLevelListItem {
}

class GroupsController: ExpandableItemsTableViewController, AddEditGroupControllerDelegate, ExpandableTopViewControllerDelegate {
    
    fileprivate var editButton: UIBarButtonItem!
    
    var expandDelegate: Foo?
    
    fileprivate var topAddEditListControllerManager: ExpandableTopViewController<AddEditGroupViewController>?
    
    override var isAnyTopControllerExpanded: Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }

    fileprivate var groupsResult: Results<ProductGroup>?
    fileprivate var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavTitle(trans("title_groups"))
        
        topAddEditListControllerManager = initTopAddEditListControllerManager()
    }
    
    deinit {
        logger.v("Deinit groups controller")
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initTopAddEditListControllerManager() -> ExpandableTopViewController<AddEditGroupViewController> {
        let top = topBar.frame.height
        let expandableTopViewController: ExpandableTopViewController<AddEditGroupViewController> = ExpandableTopViewController(top: top, height: Constants.topAddContainerViewHeight, parentViewController: self, tableView: tableView) {[weak self] _ in
            let controller = UIStoryboard.addEditGroup()
            controller.delegate = self
            controller.view.clipsToBounds = false
            return controller
        }
        expandableTopViewController.delegate = self
        return expandableTopViewController
    }
    
    
    override func initModels() {
        Prov.listItemGroupsProvider.groups(sortBy: .order, successHandler{[weak self] groups in guard let weakSelf = self else {return}
            
            weakSelf.groupsResult = groups
            
            self?.notificationToken = groups.observe { changes in
                switch changes {
                case .initial:
                    //                        // Results are now populated and can be accessed without blocking the UI
                    //                        self.viewController.didUpdateList(reload: true)
                    logger.v("initial")
                    
                case .update(_, let deletions, let insertions, let modifications):
                    logger.d("deletions: \(deletions), let insertions: \(insertions), let modifications: \(modifications), count: \(String(describing: weakSelf.groupsResult?.count))")
                    
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
        })
    }
    
    override func onSubmitTap() {
        topAddEditListControllerManager?.controller?.submit()
    }
    
    
    override func onSelectCellInEditMode(_ model: ExpandableTableViewModel, index: Int) {
        super.onSelectCellInEditMode(model, index: index)
        topAddEditListControllerManager?.expand(true)
        topAddEditListControllerManager?.controller?.modelToEdit = ((model as! ExpandableTableViewGroupModel).group, index)
    }
    
    override func topControllerIsExpanded() -> Bool {
        return topAddEditListControllerManager?.expanded ?? false
    }
    
    override func initDetailController(_ cell: UITableViewCell, model: ExpandableTableViewModel) -> UIViewController {
        let listItemsController = UIStoryboard.groupItemsController()
        listItemsController.view.frame = view.frame
        addChild(listItemsController)
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
        //        SizeLimitChecker.checkGroupsSizeLimit(models.count, controller: self) {[weak self] in
        //            if let weakSelf = self {
        let expand = !(topAddEditListControllerManager?.expanded ?? true) // toggle - if for some reason variable isn't set, set expanded false (!true)
        topAddEditListControllerManager?.expand(expand)
        if rotateTopBarButton { // HACK - don't reset the buttons when we don't want to rotate because this causes the toggle button animation to "jump" (this is used on pull to add - in order to show also the submit button we would have to reset the buttons, but this causes a little jump in the X since when the table view goes a little up because of the pull anim, the X animates back a little and when we reset the buttons, setting it to its final state there's a jump). TODO We need to adjust the general logic for this, we don't need multiple nav bar buttons on each side anyways anymore so maybe we can remove all this?
            setTopBarStateForAddTap(expand, rotateTopBarButtonOnExpand: rotateTopBarButton)
        }
        //            }
        //        }
    }

    func setThemeColor(_ color: UIColor) {
        topBar.backgroundColor = color
        view.backgroundColor = UIColor.white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func onPullToAdd() {
        showAddEditController(rotateTopBarButton: false)
    }
    
    // MARK: - EditListViewController
    //change
    func onAddGroup(_ input: AddEditSimpleItemInput) {
        guard let groupsResult = groupsResult else {logger.e("No result"); return}

        let group = ProductGroup(uuid: NSUUID().uuidString, name: input.name, color: input.color, order: groupsResult.count)
        Prov.listItemGroupsProvider.add(group, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.onGroupAddOrUpdateError(group)
            }
        ))
    }
    
    func onUpdateGroup(_ input: AddEditSimpleItemInput, item: SimpleFirstLevelListItem, index: Int) {
        let updatedGroup = (item as! ProductGroup).copy(name: input.name, bgColor: input.color)
        Prov.listItemGroupsProvider.update(updatedGroup, remote: true, resultHandler(onSuccess: {
            }, onErrorAdditional: {[weak self] result in
                self?.onGroupAddOrUpdateError(updatedGroup)
            }
        ))
    }
    
    fileprivate func onGroupAddOrUpdateError(_ group: ProductGroup) {
        initModels()
        // If the user quickly after adding the group opened its group items controller, close it.
        for childViewController in children {
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
}
