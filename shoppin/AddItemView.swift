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
    
    @IBOutlet weak var plusButton: UIButton!
    
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var totalPriceLabel: UILabel!
    @IBOutlet weak var donePriceLabel: UILabel!
    @IBOutlet weak var shopStatusContainer: UIView!
    @IBOutlet weak var sectionInput: UITextField!

    private var shopStatusContainerTopConstraint:NSLayoutConstraint?
    
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
        self.donePriceLabel.userInteractionEnabled = true
        self.donePriceLabel.addGestureRecognizer(tapGesture)
    }
    
    
    func sectionInputFieldChanged(textField:UITextField) {
        println(textField.text)
        
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

    @IBAction func onPlusTap(sender: AnyObject) {
        self.expanded = !self.expanded
    }

    private func calculateFrameHeight(expanded:Bool) -> CGFloat {
        let first:CGFloat = 0
        let viewsHeight = [self.inputBar!, self.productDetailsContainer!, self.addSectionContainer!, self.shopStatusContainer!].reduce(first, combine: { (u:CGFloat, v:UIView) -> CGFloat in
            return u + (v.hidden ? 0 : v.frame.height)
        })
        
        if (expanded) {
            return viewsHeight
        } else { // FIXME why is necessary to add status bar height only on contracted state...? when solved also remove parameter expanded in this function
            let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
            return viewsHeight + statusBarHeight
        }
    }

    private func updateFrame(expanded:Bool) {
        let height = self.calculateFrameHeight(expanded)
        self.heightConstraint.constant = height
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    var expanded:Bool = true {
        didSet {
            self.inputBar.hidden = !expanded
            self.productDetailsContainer.hidden = !expanded
            self.addSectionContainer.hidden = !expanded
            
            self.plusButton.setTitle(self.expanded ? "-" : "+", forState: UIControlState.Normal)
            
            if let topConstraint = shopStatusContainerTopConstraint {
//                self.view.removeConstraint(topConstraint)
                self.removeConstraint(topConstraint)
            }
            
            if (self.expanded) {
                
                // FIXME hack... why not at bottom
                let constant =
                CGRectGetHeight(self.inputBar.frame)
                    + CGRectGetHeight(self.productDetailsContainer.frame)
                    + CGRectGetHeight(self.addSectionContainer.frame)
                
                //            self.shopStatusContainerTopConstraint = NSLayoutConstraint(
                //                item: self.shopStatusContainer,
                //                attribute: NSLayoutAttribute.Top,
                //                relatedBy: NSLayoutRelation.Equal,
                //                toItem: self.productDetailsContainer,
                //                attribute: NSLayoutAttribute.Bottom,
                //                multiplier: 0,
                //                constant: 0)
                self.shopStatusContainerTopConstraint = NSLayoutConstraint(
                    item: self.shopStatusContainer,
                    attribute: NSLayoutAttribute.Top,
                    relatedBy: NSLayoutRelation.Equal,
                    //                toItem: self.view,
                    toItem: self,
                    attribute: NSLayoutAttribute.Top,
                    multiplier: 0,
                    constant: constant)
                
                
            } else {
                
                //            let frame = self.shopStatusContainer.frame
                //            let newH = frame.size.height * 1.4
                //            self.shopStatusContainer.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, newH)
                //
                //            self.shopStatusContainer.addConstraint(NSLayoutConstraint(
                //                item: self.shopStatusContainer,
                //                attribute: NSLayoutAttribute.Height,
                //                relatedBy: NSLayoutRelation.Equal,
                //                toItem: nil,
                //                attribute: NSLayoutAttribute.NotAnAttribute,
                //                multiplier: 0,
                //                constant: newH))
                
                
                let constant:CGFloat =
                CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
                
                self.shopStatusContainerTopConstraint = NSLayoutConstraint(
                    item: self.shopStatusContainer,
                    attribute: NSLayoutAttribute.Top,
                    relatedBy: NSLayoutRelation.Equal,
                    //                toItem: self.view,
                    toItem: self,
                    attribute: NSLayoutAttribute.Top,
                    multiplier: 0,
                    constant: constant)
                
            }
            //        self.view.addConstraint(self.shopStatusContainerTopConstraint!)
            self.addConstraint(self.shopStatusContainerTopConstraint!)
            
            self.updateFrame(self.expanded)
            
            self.delegate.onAddItemViewExpanded(self.expanded)
        }
    }
    
    override func resignFirstResponder() -> Bool {
        self.inputs.forEach{$0.resignFirstResponder()}
        return true
    }
}
