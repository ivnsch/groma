//
//  SelectIngredientFractionController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import ASValueTrackingSlider

protocol SelectIngredientFractionControllerDelegate {
    func onSelectFraction(fraction: Fraction?)
}

class SelectIngredientFractionController: UIViewController, EditableFractionViewDelegate/*, FillShapeViewDelegate*/, ASValueTrackingSliderDataSource {

//    @IBOutlet weak var fractionImageView: FillShapeView!
    @IBOutlet weak var fractionTextInputView: EditableFractionView!
    
    @IBOutlet weak var fractionSlider: ASValueTrackingSlider!

    var delegate: SelectIngredientFractionControllerDelegate?
    
    var onUIReady: (() -> Void)?
    
    var unit: Providers.Unit? {
        didSet {
//            guard let unit = unit else {return}
//            let (imageName, maskName): (String, String) = {
//                switch unit.id {
//                case .teaspoon: fallthrough
//                case .spoon: return ("spoon_shape", "spoon_shape_mask")
//                case .liter: return ("bottle_shape", "bottle_shape_mask")
//                default: return ("default_shape", "default_shape_mask")
//                }
//            }()
//            
//            fractionImageView.config(shapeImageName: imageName, maskImageName: maskName)
//            fractionImageView.fillTo(percentage: 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fractionTextInputView.delegate = self
        
//        fractionImageView.delegate = self
        
        fractionSlider.maximumValue = 1
        fractionSlider.setMaxFractionDigitsDisplayed(1)
        fractionSlider.popUpViewCornerRadius = 12
        fractionSlider.popUpViewColor = Theme.blue
        //fractionSlider.font =
        fractionSlider.textColor = UIColor.white
        
        fractionSlider.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        // Before of viewDidAppear dimensions are not correct - we use this callback to init the fill shape view, which needs final dimensions.
        onUIReady?()
    }
    
    func config(fraction: Fraction) {
//        fractionImageView.fillTo(percentage: CGFloat(fraction.decimalValue))
        fractionSlider.value = fraction.decimalValue
        fractionTextInputView.prefill(fraction: fraction)
    }
    
    
    // MARK: - EditableFractionViewDelegate
    
    func onFractionInputChange(fractionInput: Fraction?) {
        
        // Don't allow fractions > 1 - this doesn't make sense + currently breaks the fill shape animation
        let finalFractionInput = fractionInput.map {
            $0.decimalValue >= 1 ? Fraction.one : $0
        }
        
        if let fraction = finalFractionInput {
//            fractionImageView.fillTo(percentage: CGFloat(fraction.decimalValue))
            fractionSlider.value = fraction.decimalValue
            
        } else {
//            fractionImageView.fillTo(percentage: 1)
            fractionSlider.value = 1
        }
        
        delegate?.onSelectFraction(fraction: finalFractionInput)
    }
    
    // MARK: - FillShapeViewDelegate
    
    func onFillShapeValueUpdated(fraction: Fraction) {
        fractionTextInputView.prefill(fraction: fraction)
        delegate?.onSelectFraction(fraction: fraction)
    }
    
    // MARK: - Slider

    @IBAction func snapValue(_ sender: UISlider) {
        let fraction = rationalApproximationOf(x0: Double(fractionSlider.value))
        fractionSlider.value = fraction.decimalValue
        
//        let sliderFractions: [Float] = [0, 1/4, 1/3, 2/4, 2/3, 3/4, 1]
//        for snapPosition in sliderFractions {
//            if fractionSlider.value < snapPosition {
//                fractionSlider.value = snapPosition
//                break
//            }
//        }
        
        fractionTextInputView.prefill(fraction: fraction)
        delegate?.onSelectFraction(fraction: fraction)
    }
    
    // MARK: - ASValueTrackingSliderDataSource
    
    func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {
        
        let fraction = rationalApproximationOf(x0: Double(value))
        
        switch fraction.decimalValue {
        case 0: return "0"
        case 1: return "1"
        default: return "\(fraction.numerator)/\(fraction.denominator)"
        }
    }
}
