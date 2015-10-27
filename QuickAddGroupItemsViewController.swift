//
//  QuickAddGroupItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuickAddGroupItemsViewControllerDelegate {
    func onSubmit(items: [GroupItem])
    func onCancel()
}

class QuickAddGroupItemsViewController: UIViewController, QuickAddListItemDelegate {

    @IBOutlet weak var itemsLabel: UILabel!
    @IBOutlet weak var itemsTableViewContainer: UIView!
    
    var list: List? // TODO list should not be necessary here
    
    var groupItemsController: QuickAddListItemViewController?
    
    private var itemsDictionary = OrderedDictionary<String, GroupItem>()
    
    var delegate: QuickAddGroupItemsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let groupItemsController = UIStoryboard.quickAddListItemViewController()
        itemsTableViewContainer.addSubview(groupItemsController.view)
          groupItemsController.view.translatesAutoresizingMaskIntoConstraints = false
        groupItemsController.view.fillSuperview()
        groupItemsController.delegate = self
        groupItemsController.onViewDidLoad = { // ensure called after outlets set
            groupItemsController.itemType = .Product
        }
        self.groupItemsController = groupItemsController
    }
    
    func submit() {
        delegate?.onSubmit(itemsDictionary.values)
    }
    
    // MARK: - QuickAddListItemDelegate
    
    func onAddProduct(product: Product) { // TODO quantity
        
        let quantity = 1 // TODO
        
        if let item = itemsDictionary[product.uuid] {
            itemsDictionary[product.uuid] = item.copy(quantity: item.quantity + quantity)
        } else {
            // TODO section
            itemsDictionary[product.uuid] = GroupItem(uuid: NSUUID().UUIDString, quantity: quantity, product: product)
        }
        
        itemsLabel.text = buildItemsLabelString() // TODO incr/decr quantity in QuickAddListItemViewController. Hold numbers there (also show in light blue in tableview) (and pass current quantity to delegate?)
    }

    private func buildItemsLabelString() -> String {
        return ", ".join(itemsDictionary.mapValues{"\($0.product.name) \($0.quantity)x"})
    }
    
    func onAddGroup(group: ListItemGroup) {
        // not used
    }
    
    func onCloseQuickAddTap() {
        // not used
    }
}
