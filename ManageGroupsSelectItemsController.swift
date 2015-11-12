//
//  ManageGroupsSelectItemsController.swift
//  shoppin
//
//  Created by ischuetz on 28/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol ManageGroupsSelectItemsControllerDelegate {
    func onSubmit(items: [GroupItem])
}

class ManageGroupsSelectItemsController: UIViewController, QuickAddGroupItemsViewControllerDelegate {

    var delegate: ManageGroupsSelectItemsControllerDelegate?
    
    private lazy var itemsController: QuickAddGroupItemsViewController = {
        let controller = UIStoryboard.quickAddGroupItemsViewController()
        controller.delegate = self
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEmbeddedController()
        initNavBar([.Save])

        navigationItem.title = "Add items"
    }
    
    private func initNavBar(actions: [UIBarButtonSystemItem]) {
        navigationItem.title = "Manage products"
        
        var buttons: [UIBarButtonItem] = []
        
        for action in actions {
            switch action {
            case .Save:
                let button = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "onSubmitTap:")
                buttons.append(button)
            default: break
            }
        }
        navigationItem.rightBarButtonItems = buttons
    }
    
    func onSubmitTap(sender: UIBarButtonItem) {
        itemsController.submit()
    }

    func initEmbeddedController() {
        addChildViewControllerAndView(itemsController)
        view.sendSubviewToBack(itemsController.view)
        itemsController.view.translatesAutoresizingMaskIntoConstraints = false
        itemsController.view.fillSuperview()
        itemsController.view.backgroundColor = UIColor.whiteColor()
    }
    
    // MARK: - QuickAddGroupItemsViewControllerDelegate
    
    func onSubmit(items: [GroupItem]) {
        delegate?.onSubmit(items)
    }

    func onCancel() {
        navigationController?.popViewControllerAnimated(true)
    }
}
