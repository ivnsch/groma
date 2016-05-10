//
//  QuantityView.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuantityViewDelegate: class {
    func onRequestUpdateQuantity(delta: Int)
}

// TODO for some reason the buttons are not interactive! outlets are connected, all views up in the hierarchy have userInteractionEnables = yes (until the custom view -in storyboard- in which this was contained). But nothing happens on tap also no press effect on the button. It should not be anything related with the cell, only the custom view, because when the buttons are added directly to the cell (like now) there are no problems.
class QuantityView: UIView {
    
    weak var delegate: QuantityViewDelegate?
 
//    @IBOutlet weak var test: UIButton!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var quantity: Int = 0 {
        didSet {
            quantityLabel.text = String(quantity)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
    private func xibSetup() {
        let view = NSBundle.loadView("QuantityView", owner: self)!
        
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]

//        view.backgroundColor = UIColor.yellowColor()
//        test.backgroundColor = UIColor.redColor()

        
        self.addSubview(view)
        
//        userInteractionEnabled = true
//        view.userInteractionEnabled = true
//        test.userInteractionEnabled = true
    }
    
    @IBAction func onPlusTap(sender: UIButton) {
        delegate?.onRequestUpdateQuantity(1)
    }
    
    @IBAction func onMinusTap(sender: UIButton) {
        delegate?.onRequestUpdateQuantity(-1)
    }
}