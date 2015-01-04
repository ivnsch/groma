//
//  CartMenuView.swift
//  shoppin
//
//  Created by ischuetz on 04.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit


protocol CartMenuDelegate {
    func onAddToInventoryTap()
}

class CartMenuView: UIView {

    var delegate:CartMenuDelegate?
    
    @IBAction func onAddToInventoryTap(sender: UIButton) {
        delegate?.onAddToInventoryTap()
    }
}
