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

class ManageGroupsAddEditController: UIViewController, QuickAddGroupViewControllerDelegate, ManageGroupsSelectItemsControllerDelegate {

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

        initNavBar([.Add, .Save])
        initEmbeddedAddEditController()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketGroupItem:", name: WSNotificationName.GroupItem.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onWebsocketProduct:", name: WSNotificationName.Product.rawValue, object: nil)        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Add:
                let button = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "onAddTap:")
                buttons.append(button)
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        addEditGroupController.submit()
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
    
    func onAddTap(sender: UIBarButtonItem) {
        showSelectItemsController()
    }
    
    private func showSelectItemsController() {
        let controller = UIStoryboard.manageGroupsSelectItemsController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
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
    
    // MARK: - Websocket
    
    func onWebsocketGroupItem(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<GroupItem>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                    // .Add use case doesn't exist yet, see note in MyWebsocketDispatcher.processGroupItem
//                case .Add:
//                    addEditGroupController.addGroupItemUI(notification.obj)
                case .Update:
                    addEditGroupController.updateGroupItemUI(notification.obj)
                case .Delete:
                    addEditGroupController.removeGroupItemUI(notification.obj)
                    
                default: print("ManageGroupsAddEditController.onWebsocketGroupItem not handled: \(notification.verb)")

                }
            } else {
                print("Error: ManageGroupsAddEditController.onWebsocketGroupItem: no value")
            }
        } else {
            print("Error: ManageGroupsAddEditController.onWebsocketGroupItem: no userInfo")
        }
    }
    
    func onWebsocketProduct(note: NSNotification) {
        if let info = note.userInfo as? Dictionary<String, WSNotification<Product>> {
            if let notification = info[WSNotificationValue] {
                switch notification.verb {
                case .Update:
                    // TODO!! update all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                case .Delete:
                    // TODO!! delete all listitems that reference this product
                    print("Warn: TODO onWebsocketProduct")
                default: break // no error msg here, since we will receive .Add but not handle it in this view controller
                }
            } else {
                print("Error: ManageGroupsAddEditController.onWebsocketProduct: no value")
            }
        } else {
            print("Error: ManageGroupsAddEditController.onWebsocketProduct: no userInfo")
        }
    }
}
