//
//  InventoryPicker.swift
//  shoppin
//
//  Created by ischuetz on 07/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView
import Providers

class InventoryPicker: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var inventories: [DBInventory] = [] {
        didSet {
            selectedInventory = inventories.first
        }
    }
    
    fileprivate weak var button: UIButton!
    fileprivate weak var view: UIView!
    
    fileprivate var selectedInventory: DBInventory? {
        didSet {
            if let inventory = selectedInventory {
                onInventorySelected?(inventory)
                button.setTitle(inventory.name, for: UIControlState())
            }
        }
    }
    
    var onInventorySelected: ((DBInventory) -> Void)?
    
    fileprivate var inventoriesPopup: CMPopTipView?
    
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }
    
    init(button: UIButton, view: UIView, onInventorySelected: ((DBInventory) -> Void)?) {
        self.button = button
        self.view = view
        self.onInventorySelected = onInventorySelected
        
        super.init()
        
        button.addTarget(self, action: #selector(InventoryPicker.onButtonTap(_:)), for: .touchUpInside)
    }
    
    func onButtonTap(_ sender: UIButton) {
        if let popup = inventoriesPopup {
            popup.dismiss(animated: true)
        } else {
            let popup = MyTipPopup(customView: createPicker())
            popup.presentPointing(at: sender, in: view, animated: true)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return inventories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = inventories[row].name
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return DimensionsManager.pickerRowHeight
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedInventory = inventories[row]
    }
}
