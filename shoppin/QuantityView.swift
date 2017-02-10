//
//  QuantityView.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol QuantityViewDelegate: class {
    func onRequestUpdateQuantity(_ delta: Float)
}

// TODO for some reason the buttons are not interactive! outlets are connected, all views up in the hierarchy have userInteractionEnables = yes (until the custom view -in storyboard- in which this was contained). But nothing happens on tap also no press effect on the button. It should not be anything related with the cell, only the custom view, because when the buttons are added directly to the cell (like now) there are no problems.
class QuantityView: UIView {
    
    weak var delegate: QuantityViewDelegate?
 
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    var quantity: Float = 0 {
        didSet {
            quantityLabel.text = String(quantity)
            invalidateIntrinsicContentSize()
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
    fileprivate func xibSetup() {
        let view = Bundle.loadView("QuantityView", owner: self)!
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        view.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }

    @IBAction func onPlusTap(_ sender: UIButton) {
        delegate?.onRequestUpdateQuantity(1)
    }
    
    @IBAction func onMinusTap(_ sender: UIButton) {
        delegate?.onRequestUpdateQuantity(-1)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: minusButton.width + quantityLabel.intrinsicContentSize.width + plusButton.width, height: minusButton.height + quantityLabel.intrinsicContentSize.height + plusButton.height)
    }
}
