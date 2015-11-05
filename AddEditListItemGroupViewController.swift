//
//  AddEditListItemGroupViewController.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator

class AddEditListItemGroupViewController: UIViewController, UITableViewDataSource, AddEditListItemControllerDelegate, ListItemGroupItemCellDelegate {

    @IBOutlet weak var groupNameInput: UITextField!
    @IBOutlet weak var itemsTableView: UITableView!
    
    private var validator: Validator?

    var list: List? // TODO list should not be necessary here
    
    // the group for which this controller is showing - default: add case. Overwritten in update case.
    // Note that this is a different approach than in other controllers, normally the controller has its own model and we have an optional with editing object...
    // this is a bit messier, but quicker to implement.
    var group: ListItemGroup = ListItemGroup(uuid: NSUUID().UUIDString, name: "", items: []) {
        didSet {
            groupNameInput.text = group.name
            itemsTableView.reloadData()
        }
    }
    
    private var selectedGroupItem: GroupItem? // the group items which was selected in the list to update
    
    var onViewWillAppear: VoidFunction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initValidator()
    }
    
    private func initValidator() {
        let validator = Validator()
        validator.registerField(groupNameInput, rules: [MinLengthRule(length: 1, message: "validation_name_not_empty")])
        self.validator = validator
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        onViewWillAppear?()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func onSaveGroupTap(sender: UIButton) {
        submit()
    }
    
    private func submit() {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
            }
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            if let name = groupNameInput.text {
                let group = ListItemGroup(uuid: self.group.uuid, name: name, items: self.group.items)
                Providers.listItemGroupsProvider.add([group], successHandler {[weak self] in
                    self?.dismissController()
                })
            } else {
                print("Error: validation was not implemented correctly")
            }
        }
    }
    
    @IBAction func onAddItemsTap(sender: UIButton) {
        showGroupItemsController()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("itemCell", forIndexPath: indexPath) as! ListItemGroupItemCell
        cell.groupItem = group.items[indexPath.row]
        cell.delegate = self
        cell.indexPath = indexPath
        cell.backgroundColor = UIColor.clearColor()
        return cell
    }
    
    // MARK: - AddEditListItemControllerDelegate
    
    func onValidationErrors(errors: [UITextField: ValidationError]) {
        presentViewController(ValidationAlertCreator.create(errors), animated: true, completion: nil)
    }
    
    func onOkTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        addItem(name, price: priceText, quantity: quantityText, category: category, note: note) {[weak self] in
            self?.dismissGroupsItemsController()
        }
    }
    
    private func addItem(name: String, price priceText: String, quantity quantityText: String, category: String, note: String?, onFinish: VoidFunction) {
        if let price = priceText.floatValue, quantity = Int(quantityText), list = list {
            let itemInput = GroupItemInput(name: name, quantity: quantity, price: price, category: category)
            
            Providers.listItemGroupsProvider.add(itemInput, group: group, order: nil, possibleNewSectionOrder: nil, list: list, successHandler{[weak self] addedItem in
                self?.group.items.append(addedItem)
                self?.itemsTableView.reloadData()
                onFinish()
            })
            
        } else {
            print("Error: validation was not implemented correctly - price or quantity are not numbers, or list is not set")
        }
    }

    private func updateItem(input: GroupItemInput, groupItem: GroupItem, note: String?) {
        let updatedProduct = Product(uuid: groupItem.product.uuid, name: input.name, price: input.price, category: input.category)
        let updatedItem = GroupItem(uuid: groupItem.uuid, quantity: input.quantity, product: updatedProduct)
        
        Providers.listItemGroupsProvider.update([updatedItem], successHandler{[weak self] in
            self?.dismissGroupsItemsController()
        })
    }
    
    
    func onOkAndAddAnotherTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        addItem(name, price: priceText, quantity: quantityText, category: category, note: note) {
        }
    }
    
    func onUpdateTap(name: String, price priceText: String, quantity quantityText: String, category: String, sectionName: String, note: String?) {
        if let price = priceText.floatValue, quantity = Int(quantityText), groupItem = selectedGroupItem {
            let itemInput = GroupItemInput(name: name, quantity: quantity, price: price, category: category)
            
            updateItem(itemInput, groupItem: groupItem, note: note)
            
        } else {
            print("Error: validation was not implemented correctly - price or quantity are not numbers, or list is not set")
        }
    }
    
    
    private func showGroupItemsController() {
        let viewController = UIStoryboard.createListItemsViewController()
        viewController.delegate = self
        viewController.onViewDidLoad = {
            viewController.modus = .GroupItem
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func dismissGroupsItemsController() {
        navigationController?.popViewControllerAnimated(true) // pop the group items view controller
    }
    
    private func dismissController() {
        navigationController?.popViewControllerAnimated(true) // pop this view controller
    }
    
    func onCancelTap() {
        dismissController()
    }
    
    func productNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.productProvider.productSuggestions(successHandler{suggestions in
            handler(suggestions.map{$0.name})
        })
    }
    
    func sectionNameAutocompletions(text: String, handler: [String] -> ()) {
        Providers.sectionProvider.sectionSuggestions(successHandler{suggestions in
            handler(suggestions.map{$0.name})
        })
    }
    
    func planItem(productName: String, handler: PlanItem? -> ()) {
        // do nothing - plan does not make sense when adding group items
    }
    
    // MARK: - ListItemGroupItemCellDelegate
    
    func onDecrementItemTap(cell: ListItemGroupItemCell, indexPath: NSIndexPath) {
        increment(indexPath, delta: -1)
    }
    
    func onIncrementItemTap(cell: ListItemGroupItemCell, indexPath: NSIndexPath) {
        increment(indexPath, delta: 1)
    }
    
    private func increment(indexPath: NSIndexPath, delta: Int) {
        let groupItem = group.items[indexPath.row]
        group.items[indexPath.row] = groupItem.copy(quantity: groupItem.quantity + delta)
        itemsTableView.reloadData()
    }
}