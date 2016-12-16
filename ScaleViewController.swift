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
import Providers

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

protocol ScaleViewControllerDelegate: class {
    func onScaleViewControllerValidationErrors(_ errors: ValidatorDictionary<ValidationError>)
    func onScaleViewControllerSubmit(_ inputs: ProductScaleData)
    func onDismissScaleViewController(_ cancelled: Bool)    
}


class ScaleViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var baseQuantityInput: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var priceInput: UITextField!
    
//    private var scaleUnitPopup: CMPopTipView?

    fileprivate typealias ScaleUnitWithText = (scaleUnit: ProductUnit, text: String)
    
    fileprivate static let defaultUnit: ScaleUnitWithText = (.none, "None")
    
    var overlay: UIView!
    var animatedBG = false

    var onUIReady: VoidFunction?

    fileprivate let scaleUnits: [ScaleUnitWithText] = [
        defaultUnit,
        (.gram, "Gram"),
        (.kilogram, "Kilogram")
    ]
    
    weak var delegate: ScaleViewControllerDelegate?
    
    fileprivate var validator: Validator?

    func prefill(_ scaleInput: ProductScaleData) {
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
    
    fileprivate var selectedScaleUnit: ScaleUnitWithText? {
        didSet {
            if let unitButton = unitButton, let selectedScaleUnit = selectedScaleUnit {
                unitButton.setTitle(selectedScaleUnit.text, for: UIControlState())
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black
        overlay.alpha = 0
        
        self.overlay = overlay
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ScaleViewController.onTapBG(_:)))
        overlay.addGestureRecognizer(tapRecognizer)
        
        initValidator()
        selectedScaleUnit = ScaleViewController.defaultUnit
        onUIReady?()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !animatedBG { // ensure fade-in animation is not shown again if e.g. user comes back from receiving a call
            animatedBG = true
            
            
            view.superview?.insertSubview(overlay, belowSubview: view)
            overlay.translatesAutoresizingMaskIntoConstraints = false
            overlay.fillSuperview()
            animateOverlayAlpha(true)
        }
    }
    
    fileprivate func animateOverlayAlpha(_ show: Bool, onComplete: VoidFunction? = nil) {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.overlay?.alpha = show ? 0.3 : 0
            onComplete?()
        }) 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
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
    func onTapBG(_ recognizer: UITapGestureRecognizer) {
        delegate?.onDismissScaleViewController(true)
    }
    
    fileprivate func createPicker() -> UIPickerView {
        let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        picker.delegate = self
        picker.dataSource = self
        return picker
    }

    fileprivate func initValidator() {
        let validator = Validator()
        validator.registerField(baseQuantityInput, rules: [MinLengthRule(length: 1, message: "validation_item_name_not_empty"), FloatRule(message: "validation_price_number")])
        validator.registerField(priceInput, rules: [MinLengthRule(length: 1, message: "validation_item_category_not_empty"), FloatRule(message: "validation_price_number")])
        
        self.validator = validator
    }
    
    @IBAction func onScaleUnitTap(_ sender: UIButton) {
        if let windowView = UIApplication.shared.keyWindow {
            let popup = MyTipPopup(customView: createPicker(), borderColor: UIColor.darkGray)
            popup.presentPointing(at: unitButton, in: windowView, animated: true)
        } else {
            print("Warn: ScaleViewController.onScaleUnitTap: no window view")
        }
    }
    
    @IBAction func onOkTap(_ sender: UIButton) {
        submit()
    }
    
    func submit() {
        guard validator != nil else {return}
        
        if let errors = validator?.validate() {
            for (_, error) in errors {
                error.field.showValidationError()
                delegate?.onScaleViewControllerValidationErrors(errors)
            }
            
        } else {
            if let lastErrors = validator?.errors {
                for (_, error) in lastErrors {
                    error.field.clearValidationError()
                }
            }
            
            if let baseQuantity = baseQuantityInput.text?.floatValue, let selectedUnit = selectedScaleUnit?.scaleUnit, let price = priceInput.text?.floatValue {
                let scaleData = ProductScaleData(price: price, baseQuantity: baseQuantity, unit: selectedUnit)
                delegate?.onScaleViewControllerSubmit(scaleData)
                
            } else {
                print("Error: ScaleViewController.submit: validation was not implemented correctly")
            }
        }
    }
    
    // MARK: - UIPicker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return scaleUnits.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.font = Fonts.regularLight
        label.text = scaleUnits[row].text
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let scaleUnit = scaleUnits[row]
        selectedScaleUnit = scaleUnit
    }
}
