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

class InventoryPicker: NSObject {
    
    var inventories: [DBInventory] = [] {
        didSet {
            selectedInventory = inventories.first
        }
    }
    
    fileprivate weak var button: UIButton!
    fileprivate weak var controller: UIViewController!

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
    
    fileprivate func createPicker(options: [String], selectedOption: String?) -> UIViewController {
        let picker = TooltipPicker()
        picker.view.frame = CGRect(x: 0, y: 0, width: 150, height: 100)
        picker.config(options: options, selectedOption: selectedOption) { [weak self] selectedOption in
            guard let weakSelf = self else { return }
            weakSelf.selectedInventory = weakSelf.inventories.findFirst { $0.name == selectedOption }
        }
        return picker
    }
    
    init(button: UIButton, controller: UIViewController, onInventorySelected: ((DBInventory) -> Void)?) {
        self.button = button
        self.onInventorySelected = onInventorySelected
        self.controller = controller
        
        super.init()
        
        button.addTarget(self, action: #selector(InventoryPicker.onButtonTap(_:)), for: .touchUpInside)
    }
    
    @objc func onButtonTap(_ sender: UIButton) {
        if let popup = inventoriesPopup {
            popup.dismiss(animated: true)
        } else {
            let options = inventories.map { $0.name }
            let picker = createPicker(options: options, selectedOption: selectedInventory?.name)
            let popup = MyTipPopup(customView: picker.view)
            popup.presentPointing(at: sender, in: controller.view, animated: true)
            controller?.addChildViewController(picker)
            popup.onDismiss = { [weak picker] in
                picker?.removeFromParentViewController()
            }
        }
    }
}
