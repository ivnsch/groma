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
    func onUpdateTap(name:String, price:String, quantity:String, sectionName:String)
    func onSectionInputChanged(text:String)
}

enum AddModus {
    case Add, Update
}

// TODO wrap this in controller, which also handles validating, creating listitem, maybe also storing in provider
class AddItemView: UIView, UITextFieldDelegate {
    
    @IBOutlet weak var productDetailsContainer: UIView!
    @IBOutlet weak var inputBar: UIView!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var addSectionContainer: UIView!
    
    @IBOutlet weak var priceInput: UITextField!
    @IBOutlet weak var quantityInput: UITextField!
    
    @IBOutlet weak var sectionInput: UITextField!
    
    @IBOutlet weak var heightConstraint:NSLayoutConstraint!
    @IBOutlet weak var topConstraint:NSLayoutConstraint!

    @IBOutlet weak var addButton: UIButton!

    var expanded:Bool = true

    
    private var addModus:AddModus = .Add {
        didSet {
            switch addModus {
            case .Add:
                self.addButton.setTitle("Add", forState: UIControlState.Normal)
            case .Update:
                self.addButton.setTitle("Update", forState: UIControlState.Normal)
            }
        }
    }
    
    private var inputs:[UITextField] {
        return [self.inputField, self.priceInput, self.quantityInput, self.sectionInput]
    }

    private var originalHeight:CGFloat!

    
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
        
        self.originalHeight = self.heightConstraint.constant
    }
    
    func sectionInputFieldChanged(textField:UITextField) {
        delegate.onSectionInputChanged(textField.text)
    }

    @IBAction func onAddTap(sender: AnyObject) {
        let text = inputField.text
        let priceText = priceInput.text
        let quantityText = quantityInput.text
        let sectionText = sectionInput.text
        
        switch self.addModus {
        case .Add:
            delegate.onAddTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
        case .Update:
            delegate.onUpdateTap(text, price: priceText, quantity: quantityText, sectionName: sectionText)
        }
        
        self.addModus = .Add // after adding item, either if we come from add or update, we go back to add modus
    }

    func clearInputs() {
        for input in self.inputs {
            if input != self.sectionInput { // section name stays
                input.text = ""
            }
        }
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

    override func resignFirstResponder() -> Bool {
        self.inputs.forEach{$0.resignFirstResponder()}
        return true
    }
    
    func setUpdateItem(listItem:ListItem) {
        self.addModus = .Update
        
        self.prefill(listItem)
    }
    
    private func prefill(listItem:ListItem) {
        self.inputField.text = listItem.product.name
        self.sectionInput.text = listItem.section.name
        self.quantityInput.text = String(listItem.quantity)
        self.priceInput.text = listItem.product.price.toString(2)
    }
}
