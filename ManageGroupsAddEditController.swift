//
//  ManageGroupsAddEditWrapperController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit


protocol ManageGroupsAddEditControllerDelegate {
    func onGroupCreated(group: ListItemGroup)
    func onGroupUpdated(group: ListItemGroup)
    func onGroupItemsOpen()
    func onGroupItemsSubmit()
}

class ManageGroupsAddEditController: UIViewController, QuickAddGroupViewControllerDelegate, BottonPanelViewDelegate, ManageGroupsSelectItemsControllerDelegate {

    @IBOutlet weak var floatingViews: FloatingViews!

    private lazy var addEditGroupController: QuickAddGroupViewController = {
        let controller = UIStoryboard.quickAddGroupViewController()
        controller.delegate = self
        return controller
    }()

    // Warning: assumption that this will not be set before the outlets of addEditGroupController are initialised (because of this we set it in onViewDidLoad)
    var editingGroup: ListItemGroup? {
        didSet {
            addEditGroupController.editingGroup = editingGroup
        }
    }

    var delegate: ManageGroupsAddEditControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initNavBar()
        initEmbeddedAddEditController()
        initFloatingViews()
    }

    private func initFloatingViews() {
        floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit, xRight: 20)])
        floatingViews.delegate = self
    }
    
    private func initEmbeddedAddEditController() {
        addEditGroupController.onViewDidLoad = {[weak self] in
            self?.addEditGroupController.editingGroup = self?.editingGroup
        }
        addChildViewControllerAndView(addEditGroupController)
        view.sendSubviewToBack(addEditGroupController.view)
        addEditGroupController.view.translatesAutoresizingMaskIntoConstraints = false
        addEditGroupController.view.fillSuperview()
        addEditGroupController.view.backgroundColor = UIColor.whiteColor()
    }

    private func initNavBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
        navigationItem.setRightBarButtonItem(addButton, animated: true)
    }
    
    func onAddTap(sender: UIBarButtonItem) {
        showSelectItemsController()
    }
    
    private func showSelectItemsController() {
        let controller = UIStoryboard.manageGroupsSelectItemsController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        switch action {
        case .Submit:
            addEditGroupController.submit()
        default:
            print("Warn: ManageGroupsAddEditController not handled action: \(action)")
            break
        }
    }
    
    // MARK: - QuickAddGroupViewControllerDelegate

    func onGroupCreated(group: ListItemGroup) {
        delegate?.onGroupCreated(group)
    }

    func onGroupUpdated(group: ListItemGroup) {
        delegate?.onGroupUpdated(group)
    }
    
    func onGroupItemsOpen() {
        // do nothing
    }
    
    func onGroupItemsSubmit() {
        // do nothing
    }
    
    func onEmptyViewTap() {
        showSelectItemsController()
    }

    // MARK: - ManageGroupsSelectItemsControllerDelegate
    
    func onSubmit(items: [GroupItem]) {
        addEditGroupController.groupItems = items
        navigationController?.popViewControllerAnimated(true)
    }
}
