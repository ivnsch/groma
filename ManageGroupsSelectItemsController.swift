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

class ManageGroupsSelectItemsController: UIViewController, QuickAddGroupItemsViewControllerDelegate, BottonPanelViewDelegate {

    @IBOutlet weak var floatingViews: FloatingViews!

    var delegate: ManageGroupsSelectItemsControllerDelegate?
    
    private lazy var itemsController: QuickAddGroupItemsViewController = {
        let controller = UIStoryboard.quickAddGroupItemsViewController()
        controller.delegate = self
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initEmbeddedController()
        initFloatingViews()
        
        navigationItem.title = "Add items"
    }

    func initEmbeddedController() {
        addChildViewControllerAndView(itemsController)
        view.sendSubviewToBack(itemsController.view)
        itemsController.view.translatesAutoresizingMaskIntoConstraints = false
        itemsController.view.fillSuperview()
        itemsController.view.backgroundColor = UIColor.whiteColor()
    }
    
    private func initFloatingViews() {
        floatingViews.setActions([FLoatingButtonAttributedAction(action: .Submit, xRight: 20)])
        floatingViews.delegate = self
    }
    
    // MARK: - QuickAddGroupItemsViewControllerDelegate
    
    func onSubmit(items: [GroupItem]) {
        delegate?.onSubmit(items)
    }

    func onCancel() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - BottonPanelViewDelegate
    
    func onSubmitAction(action: FLoatingButtonAction) {
        switch action {
        case .Submit:
            itemsController.submit()
        default:
            print("Warn: ManageGroupsAddEditController not handled action: \(action)")
            break
        }
    }
}
