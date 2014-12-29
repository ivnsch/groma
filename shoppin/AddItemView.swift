//
//  AddItemView.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit


protocol AddItemViewDelegate {
    func onAddTap(name:String, price:String, quantity:String, sectionName:String)
    func onSectionInputChanged(text:String)
    func onDonePriceTap()
    func onAddItemViewExpanded(expanded:Bool)
}

class AddItemView: UIView, UITextFieldDelegate {
    
    @IBOutlet weak var productDetailsContainer: UIView!
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var addSectionContainer: UIView!
    
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var sectionInput: UITextField!
    
    @IBOutlet weak var heightConstraint:NSLayoutConstraint!
    
    
    private var inputs:[UITextField] {
        return [self.inputField, self.priceInput, self.quantityInput, self.sectionInput]
    }

    
    var sectionText:String {
        set {
            self.sectionInput.text = newValue
        }
        get {
            return self.sectionInput.text
        }
    }
    
    var delegate:AddItemViewDelegate!
    
    private func formattedPrice(price:Float) -> String {
        return NSNumber(float: price).stringValue + " €"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setInputsDefaultValues()
        
        self.priceInput.keyboardType = UIKeyboardType.DecimalPad
        self.quantityInput.keyboardType = UIKeyboardType.DecimalPad
        
        self.inputField.placeholder = "Item name"
        self.sectionInput.placeholder = "Section (optional)"
        
        FrozenEffect.apply(self)
        
        self.sectionInput.delegate = self
        self.sectionInput.addTarget(self, action: "sectionInputFieldChanged:", forControlEvents: UIControlEvents.EditingChanged)
        sectionInput.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "onDonePriceTap:")
    }
    
    func sectionInputFieldChanged(textField:UITextField) {
        delegate.onSectionInputChanged(textField.text)
    }

    func onDonePriceTap(sender:UITapGestureRecognizer) {
        delegate.onDonePriceTap()
    }
    
    @IBAction func onAddTap(sender: AnyObject) {
        let text = inputField.text
        let priceText = priceInput.text
        let quantityText = quantityInput.text
        let sectionText = sectionInput.text
        
        delegate.onAddTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
    }

    func clearInputs() {
        self.inputs.forEach{$0.text = ""}
        self.setInputsDefaultValues()
    }
    
    private func setInputsDefaultValues() {
        self.quantityInput.text = "1"
    }
    
    func sectionAutosuggestionsFrame(autosuggestionsViewParentView:UIView) -> CGRect {
        let sectionFrame = self.sectionInput.frame
        let originAbsolute = self.sectionInput.superview!.convertPoint(sectionFrame.origin, toView: autosuggestionsViewParentView)
        let frame = CGRectMake(originAbsolute.x, originAbsolute.y + sectionFrame.size.height, sectionFrame.size.width, 0)
        return frame
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: AnyObject? = event.allTouches()?.anyObject()
        self.inputs.forEach { (element) -> Void in
            if element.isFirstResponder() && touch?.view != element {
                element.resignFirstResponder()
            }
        }
        super.touchesBegan(touches, withEvent: event)
    }

    private func calculateFrameHeight() -> CGFloat {
        let first:CGFloat = 0
        let viewsHeight = [self.inputBar!, self.productDetailsContainer!, self.addSectionContainer!].reduce(first, combine: { (u:CGFloat, v:UIView) -> CGFloat in
            return u + (v.hidden ? 0 : v.frame.height)
        })
        
        return viewsHeight
    }

    private func updateFrame() {
        let height = self.calculateFrameHeight()
        self.heightConstraint.constant = height
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    var expanded:Bool = true {
        didSet {
            self.inputBar.hidden = !expanded
            self.productDetailsContainer.hidden = !expanded
            self.addSectionContainer.hidden = !expanded
            
            self.updateFrame()
            
            self.delegate.onAddItemViewExpanded(self.expanded)
        }
    }
    
    override func resignFirstResponder() -> Bool {
        self.inputs.forEach{$0.resignFirstResponder()}
        return true
    }
}
