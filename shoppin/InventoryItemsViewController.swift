//
//  InventoryItemsViewController.swift
//  shoppin
//
//  Created by ischuetz on 01/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit


class InventoryItemsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var sortByButton: UIButton!
    @IBOutlet weak var sortByPicker: UIPickerView!
    private var tableViewController: InventoryItemsTableViewController?

    private let sortByOptions: [(value: InventorySortBy, key: String)] = [
        (.Count, "Count"), (.Alphabetic, "Alphabetic")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewController?.tableViewTopInset = 64
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sortByOptions.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sortByOptions[row].key
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sortByPicker.hidden = true
        let sortByOption = sortByOptions[row]
        sortBy(sortByOption.value)
        sortByButton.setTitle(sortByOption.key, forState: .Normal)
    }
    
    private func sortBy(sortBy: InventorySortBy) {
        tableViewController?.sortBy = sortBy
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedInventoryItemsTableViewSegue" {
            tableViewController = segue.destinationViewController as? InventoryItemsTableViewController
            
            tableViewController?.onViewWillAppear = {[weak self] in
                self?.tableViewController?.sortBy = .Count
            }
        }
    }
    
    @IBAction func onSortByTap(sender: UIButton) {
        sortByPicker.hidden = !sortByPicker.hidden
    }
}