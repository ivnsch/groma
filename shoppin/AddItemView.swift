//
//  AddItemView.swift
//  shoppin
//
//  Created by ischuetz on 07/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol AddItemViewDelegate: class {
    func onAddTap()
}

@IBDesignable class AddItemView: UIVisualEffectView {
    
    weak var delegate: AddItemViewDelegate!
    var bottomConstraint: NSLayoutConstraint?

    @IBOutlet weak var addButton: UIButton!
    
    var addButtonCenter: CGPoint {
        return addButton.center
    }
    
    override init(effect: UIVisualEffect?) {
        super.init(effect: effect)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view = Bundle.loadView("AddItemView", owner: self)!

        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onAddTap(_ sender: UIButton) {
        delegate?.onAddTap()
    }
    
    func setVisible(_ visible: Bool, animated: Bool = true) {
        if let bottomConstraint = self.bottomConstraint {
            bottomConstraint.constant = visible ? 0 : -100
            if animated {
                UIView.animate(withDuration: 0.2, animations: {[weak self] () -> Void in
                    self?.superview?.layoutIfNeeded()
                }) 
            } else {
                superview?.layoutIfNeeded()
            }
        } else {
            print("Error: AddItemView: trying to animate without top constraint")
        }
    }
    
    func setButtonText(_ text: String) {
        addButton.setTitle(text, for: UIControlState())
    }
    
    func setButtonColor(_ color: UIColor) {
        addButton.backgroundColor = color
    }
}
