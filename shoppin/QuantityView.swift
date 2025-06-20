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
    func onQuantityInput(_ quantity: Float)
}

enum QuantityViewMode {
    case readonly, edit
}

// TODO for some reason the buttons are not interactive! outlets are connected, all views up in the hierarchy have userInteractionEnables = yes (until the custom view -in storyboard- in which this was contained). But nothing happens on tap also no press effect on the button. It should not be anything related with the cell, only the custom view, because when the buttons are added directly to the cell (like now) there are no problems.
@IBDesignable
class QuantityView: UIView, UITextFieldDelegate {
    
    weak var delegate: QuantityViewDelegate?
 
    @IBOutlet weak var quantityLabel: TextFieldMore!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    @IBOutlet weak var minusBottomWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var plusBottomWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTrailingConstraint: NSLayoutConstraint!

    fileprivate(set) var mode: QuantityViewMode = .edit
    
    fileprivate var showPlusDeltaTimerTask: DispatchWorkItem?
    fileprivate var showMinusDeltaTimerTask: DispatchWorkItem?

    var quantity: Float = 0 {
        didSet {
            // TODO????????????????
//            tableViewListItem.product.product.quantityWithMaybeUnitText(quantity: shownQuantity)
            quantityText = quantity.quantityString
        }
    }
    
    var quantityText: String? {
        get {
            return quantityLabel.text
            
        } set {
            quantityLabel.text = newValue
            quantityLabel.invalidateIntrinsicContentSize()
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
        
        quantityLabel.calculateIntrinsicSizeManually = true
        
        quantityLabel.delegate = self
        quantityLabel.addTarget(self, action: #selector(onQuantityTextChange(_:)), for: .editingChanged)

        plusButton.isExclusiveTouch = true
        minusButton.isExclusiveTouch = true
    }
    
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return mode == .edit
    }
    
    
    // MARK: -
    
    @objc func onQuantityTextChange(_ sender: UITextField) {
        if let quantity = quantityLabel.text?.floatValue {
            quantityText = quantityLabel.text ?? "" // NOTE we set quantityText not quantity because when we input decimals, since this is called on every keystroke, if we type e.g. "1." setting quantity will set the text back to "1"
            delegate?.onQuantityInput(quantity)
        }
    }
    
    @IBAction func onPlusTap(_ sender: UIButton) {
        delegate?.onRequestUpdateQuantity(1)
        showDelta(1)
    }
    
    @IBAction func onMinusTap(_ sender: UIButton) {
        let delta: Float = -1
        
        guard quantity + delta >= 0 else {return}
        
        delegate?.onRequestUpdateQuantity(delta)
        showDelta(delta)
    }
    
    override func resignFirstResponder() -> Bool {
        return quantityLabel.resignFirstResponder()
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
        return CGSize(width: minusBottomWidthConstraint.constant + quantityLabel.intrinsicContentSize.width + plusBottomWidthConstraint.constant, height: minusButton.height + quantityLabel.intrinsicContentSize.height + plusButton.height)
    }

    func setMode(_ mode: QuantityViewMode, animated: Bool) {
        guard mode != self.mode else {return}
        
        self.mode = mode
        
        if mode == .edit || mode == .readonly {
            let widthConstant: CGFloat = mode == .edit ? 41 : 0

            if animated {

                self.minusBottomWidthConstraint.constant = widthConstant
                self.plusBottomWidthConstraint.constant = widthConstant
                anim(Theme.defaultAnimDuration, {
                    self.layoutIfNeeded()
                    self.invalidateIntrinsicContentSize()

                }, onFinish: {
                })
            } else {
                minusBottomWidthConstraint.constant = widthConstant
                plusBottomWidthConstraint.constant = widthConstant
                invalidateIntrinsicContentSize()
                layoutIfNeeded()
            }
        }
    }
}
