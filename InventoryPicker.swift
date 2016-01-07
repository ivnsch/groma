//
//  InventoryPicker.swift
//  shoppin
//
//  Created by ischuetz on 07/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

class InventoryPicker: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var inventories: [Inventory] = [] {
        didSet {
            selectedInventory = inventories.first
        }
    }
    
    private weak var button: UIButton!
    private weak var view: UIView!
    
    private var selectedInventory: Inventory? {
        didSet {
            if let inventory = selectedInventory {
                onInventorySelected?(inventory)
                button.setTitle(inventory.name, forState: .Normal)
            }
        }
    }
    
    var onInventorySelected: (Inventory -> Void)?
    
    private var inventoriesPopup: CMPopTipView?
    
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    init(button: UIButton, view: UIView, onInventorySelected: (Inventory -> Void)?) {
        self.button = button
        self.view = view
        self.onInventorySelected = onInventorySelected
        
        super.init()
        
        button.addTarget(self, action: "onButtonTap:", forControlEvents: .TouchUpInside)
    }
    
    func onButtonTap(sender: UIButton) {
        if let popup = inventoriesPopup {
            popup.dismissAnimated(true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointingAtView(sender, inView: view, animated: true)
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return inventories.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = inventories[row].name
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedInventory = inventories[row]
    }
}