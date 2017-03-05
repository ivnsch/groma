//
//  QuantityView.swift
//  shoppin
//
//  Created by ischuetz on 14/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol QuantityViewDelegate: class {
    func onRequestUpdateQuantity(_ delta: Float)
}

enum QuantityViewMode {
    case readonly, edit
}

// TODO for some reason the buttons are not interactive! outlets are connected, all views up in the hierarchy have userInteractionEnables = yes (until the custom view -in storyboard- in which this was contained). But nothing happens on tap also no press effect on the button. It should not be anything related with the cell, only the custom view, because when the buttons are added directly to the cell (like now) there are no problems.
class QuantityView: UIView {
    
    weak var delegate: QuantityViewDelegate?
 
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    @IBOutlet weak var minusBottomWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusBottomWidthConstraint: NSLayoutConstraint!
    
    var mode: QuantityViewMode = .edit
    
    fileprivate var showPlusDeltaTimerTask: DispatchWorkItem?
    fileprivate var showMinusDeltaTimerTask: DispatchWorkItem?

    var quantity: Float = 0 {
        didSet {
            // TODO????????????????
//            tableViewListItem.product.product.quantityWithMaybeUnitText(quantity: shownQuantity)
            quantityLabel.text = String(quantity.quantityString)
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
        showDelta(1)
    }
    
    @IBAction func onMinusTap(_ sender: UIButton) {
        delegate?.onRequestUpdateQuantity(-1)
        showDelta(-1)
    }
    
    func showDelta(_ delta: Float) {
        let resetColorDelay: Double = 0.3
        
        func resetPlus() {
            plusButton.setTitleColor(Theme.black, for: .normal)
            plusButton.imageView?.tintColor = Theme.grey
        }
        
        func resetMinus() {
            minusButton.setTitleColor(Theme.black, for: .normal)
            minusButton.imageView?.tintColor = Theme.grey
        }
        
        if delta > 0 {
            resetMinus()
            
            plusButton.setTitleColor(Theme.lighterGreen, for: .normal)
            plusButton.imageView?.tintColor = Theme.lighterGreen
            showPlusDeltaTimerTask?.cancel()
            showPlusDeltaTimerTask = delayNew(resetColorDelay) {
                resetPlus()
            }
        } else if delta < 0 {
            resetPlus()
            
            minusButton.setTitleColor(UIColor.flatRed, for: .normal)
            minusButton.imageView?.tintColor = UIColor.flatRed
            showMinusDeltaTimerTask?.cancel()
            showMinusDeltaTimerTask = delayNew(resetColorDelay) {
                resetMinus()
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: minusButton.width + quantityLabel.intrinsicContentSize.width + plusButton.width, height: minusButton.height + quantityLabel.intrinsicContentSize.height + plusButton.height)
    }
    
    func setMode(_ mode: QuantityViewMode, animated: Bool) {
        guard mode != self.mode else {return}
        
        self.mode = mode
        
        if mode == .edit || mode == .readonly {
            
            let widthConstant: CGFloat = mode == .edit ? 41 : 0

            minusBottomWidthConstraint.constant = widthConstant
            plusBottomWidthConstraint.constant = widthConstant
            if animated {
                anim {
                    self.layoutIfNeeded()
                }
            } else {
                layoutIfNeeded()
            }
        }
    }
}
