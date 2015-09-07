//
//  PricesView.swift
//  shoppin
//
//  Created by ischuetz on 01.01.15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

class PricesView: UIView {

    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    
    var totalPrice:Float? {
        didSet {
            self.totalPriceLabel.text = totalPrice!.toLocalCurrencyString()
        }
    }
    
    var donePrice:Float? {
        didSet {
            self.donePriceLabel.text = donePrice!.toLocalCurrencyString()
        }
    }
}
