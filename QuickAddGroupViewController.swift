//
//  QuickAddGroupViewController.swift
//  shoppin
//
//  Created by ischuetz on 21/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

protocol QuickAddGroupViewControllerDelegate {
    func onGroupCreated(group: ListItemGroup)
}

class QuickAddGroupViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QuickAddGroupItemsViewControllerDelegate, QuantityCellDelegate {

    @IBOutlet weak var groupNameInput: UITextField!
    @IBOutlet weak var itemsTableView: UITableView!

    private var groupItems: [GroupItem] = [] {
        didSet {
            itemsTableView.reloadData()
        }
    }
    
    private let cellIdentifier = "cell"

    private var validator: Validator?

    var delegate: QuickAddGroupViewControllerDelegate?
    
    // TODO in edit case, pass the group and pre-fill
    
    override func viewDidLoad() {
        super.viewDidLoad()
        itemsTableView.registerNib(UINib(nibName: "QuantityCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        
        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(groupNameInput, rules: [MinLengthRule(length: 1, message: "validation_group_name_not_empty")])
        self.validator = validator
    }
    
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = itemsTableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! QuantityCell
        
        let groupItem = groupItems[indexPath.row]
        
        cell.name = groupItem.product.name
        cell.quantity = "\(groupItem.quantity)" 
        
        cell.indexPath = indexPath
        cell.delegate = self

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "itemsSegue" {
            let controller = segue.destinationViewController as! QuickAddGroupItemsViewController
            // TODO in edit case (or add case after adding items) pass existing items
            controller.delegate = self
        }
    }
    
    @IBAction func onSaveTap(sender: UIButton) {
        submit()
    }
    
    private func submit() {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
                presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
            }
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let name = groupNameInput.text {
                let group = ListItemGroup(uuid: NSUUID().UUIDString, name: name, items: groupItems)
                Providers.listItemGroupsProvider.add([group], successHandler{[weak self] in
                    // TODO show a "toast" confirmation
                    // add group to view controller (list) - scroll to it
                    self?.delegate?.onGroupCreated(group)
                })
                
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    
    // MARK: - QuickAddGroupItemsViewControllerDelegate
    
    func onSubmit(items: [GroupItem]) {
        groupItems = items
        dismissItemsSelectionController()
    }
    
    func onCancel() {
        dismissItemsSelectionController()
    }
    
    private func dismissItemsSelectionController() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - QuantityCellDelegate
    
    func onPlusTap(cell: QuantityCell, indexPath: NSIndexPath) {
        incrementItemQuantity(indexPath, delta: 1)
    }
    
    func onMinusTap(cell: QuantityCell, indexPath: NSIndexPath) {
        incrementItemQuantity(indexPath, delta: -1)
    }
    
    private func incrementItemQuantity(indexPath: NSIndexPath, delta: Int) {
        let groupItem = groupItems[indexPath.row]
        groupItems[indexPath.row] = groupItem.copy(quantity: groupItem.quantity + delta)
    }
}
