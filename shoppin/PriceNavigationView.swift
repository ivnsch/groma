//
//  PriceNavigationView.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class PriceNavigationView: UIView {
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    @IBOutlet weak var separatorLabel: UILabel!
    
    var totalPrice:Float? {
        didSet {
            self.totalPriceLabel.text = self.formattedPrice(totalPrice!)
        }
    }
    
    var donePrice:Float? {
        didSet {
            self.donePriceLabel.text = self.formattedPrice(donePrice!)
        }
    }
    
    private func formattedPrice(price:Float) -> String {
        return NSNumber(float: price).stringValue + " €"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let views = ["tp": self.totalPriceLabel, "sp": self.separatorLabel, "dp": self.donePriceLabel]
        for view in views.values {view.setTranslatesAutoresizingMaskIntoConstraints(false)}
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        for constraint in [
            "H:|[tp]-[sp]-[dp]|"
            ] {
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(constraint, options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        }
        
        for v in [self.totalPriceLabel, self.separatorLabel, self.donePriceLabel] {v.centerYInParent()}
        
        self.centerInParent()
    }

}