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
    
    private func xibSetup() {
        let view = NSBundle.loadView("AddItemView", owner: self)!

        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onAddTap(sender: UIButton) {
        delegate?.onAddTap()
    }
    
    func setVisible(visible: Bool, animated: Bool = true) {
        if let bottomConstraint = self.bottomConstraint {
            bottomConstraint.constant = visible ? 0 : -100
            if animated {
                UIView.animateWithDuration(0.2) {[weak self] () -> Void in
                    self?.superview?.layoutIfNeeded()
                }
            } else {
                superview?.layoutIfNeeded()
            }
        } else {
            print("Error: AddItemView: trying to animate without top constraint")
        }
    }
    
    func setButtonText(text: String) {
        addButton.setTitle(text, forState: .Normal)
    }
    
    func setButtonColor(color: UIColor) {
        addButton.backgroundColor = color
    }
}