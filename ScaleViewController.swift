//
//  ScaleViewController.swift
//  shoppin
//
//  Created by ischuetz on 11/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import SwiftValidator
import CMPopTipView


struct ProductScaleData {
    let price: Float
    let baseQuantity: Float
    let unit: ProductUnit

    init(price: Float, baseQuantity: Float, unit: ProductUnit) {
        self.price = price
        self.baseQuantity = baseQuantity
        self.unit = unit
    }
}

protocol ScaleViewControllerDelegate {
    func onScaleViewControllerValidationErrors(errors: [UITextField: ValidationError])
    func onScaleViewControllerSubmit(inputs: ProductScaleData)
    func onDismissScaleViewController(cancelled: Bool)    
}


class ScaleViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var baseQuantityInput: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    
//    private var scaleUnitPopup: CMPopTipView?

    private typealias ScaleUnitWithText = (scaleUnit: ProductUnit, text: String)
    
    private static let defaultUnit: ScaleUnitWithText = (.None, "None")
    
    var overlay: UIView!
    var animatedBG = false

    var onUIReady: VoidFunction?

    private let scaleUnits: [ScaleUnitWithText] = [
        defaultUnit,
        (.Gram, "Gram"),
        (.Kilogram, "Kilogram")
    ]
    
    var delegate: ScaleViewControllerDelegate?
    
    private var validator: Validator?

    func prefill(scaleInput: ProductScaleData) {
        baseQuantityInput.text = scaleInput.baseQuantity.toString(2)
        
        // find the scale unit with text for input's scale unit
        let scaleUnitWithText: ScaleUnitWithText? = {
            for scaleUnit in scaleUnits {
                if scaleUnit.scaleUnit == scaleInput.unit {
                    return scaleUnit
                }
            }
            return nil
        }()
        selectedScaleUnit = scaleUnitWithText
        
        priceInput.text = scaleInput.price == 0 ? "" : scaleInput.price.toString(2)
    }
    
    private var selectedScaleUnit: ScaleUnitWithText? {
        didSet {
            if let unitButton = unitButton, selectedScaleUnit = selectedScaleUnit {
                unitButton.setTitle(selectedScaleUnit.text, forState: .Normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.blackColor()
        overlay.alpha = 0
        
        self.overlay = overlay
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: "onTapBG:")
        overlay.addGestureRecognizer(tapRecognizer)
        
        initValidator()
        selectedScaleUnit = ScaleViewController.defaultUnit
        onUIReady?()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !animatedBG { // ensure fade-in animation is not shown again if e.g. user comes back from receiving a call
            animatedBG = true
            
            
            view.superview?.insertSubview(overlay, belowSubview: view)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.fillSuperview()
            animateOverlayAlpha(true)
        }
    }
    
    private func animateOverlayAlpha(show: Bool, onComplete: VoidFunction? = nil) {
        UIView.animateWithDuration(0.3) {[weak self] in
            self?.overlay?.alpha = show ? 0.3 : 0
            onComplete?()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        overlay.removeFromSuperview()
    }
    
    func dismiss() {
        animateOverlayAlpha(false) {[weak self] in
            self?.overlay.removeFromSuperview()
        }
        delegate?.onDismissScaleViewController(false)
        // see TODO below
    }
    
    // TODO popup should contain logic to animate back... not the parent controller
    func onTapBG(recognizer: UITapGestureRecognizer) {
        delegate?.onDismissScaleViewController(true)
    }
    
    private func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRectMake(0, 0, 150, 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }

    private func initValidator() {
        let validator = Validator()
        validator.registerField(baseQuantityInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_item_category_not_empty"), FloatRule(message: "validation_price_number")])
        
        self.validator = validator
    }
    
    @IBAction func onScaleUnitTap(sender: UIButton) {
        if let windowView = UIApplication.sharedApplication().keyWindow {
            let popup = MyTipPopup(customView: createPicker(), borderColor: UIColor.darkGrayColor())
            popup.presentPointingAtView(unitButton, inView: windowView, animated: true)
        } else {
            print("Warn: ScaleViewController.onScaleUnitTap: no window view")
        }
    }
    
    @IBAction func onOkTap(sender: UIButton) {
        submit()
    }
    
    func submit() {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (field, _) in errors {
                field.showValidationError()
                delegate?.onScaleViewControllerValidationErrors(errors)
            }
            
        } else {
            if let lastErrors = validator?.lastErrors {
                for (field, _) in lastErrors {
                    field.clearValidationError()
                }
            }
            
            if let baseQuantity = baseQuantityInput.text?.floatValue, selectedUnit = selectedScaleUnit?.scaleUnit, price = priceInput.text?.floatValue {
                let scaleData = ProductScaleData(price: price, baseQuantity: baseQuantity, unit: selectedUnit)
                delegate?.onScaleViewControllerSubmit(scaleData)
                
            } else {
                print("Error: ScaleViewController.submit: validation was not implemented correctly")
            }
        }
    }
    
    // MARK: - UIPicker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return scaleUnits.count
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = scaleUnits[row].text
        return label
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let scaleUnit = scaleUnits[row]
        selectedScaleUnit = scaleUnit
    }
}
