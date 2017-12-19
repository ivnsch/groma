//
//  IngredientQuantityView.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import ASValueTrackingSlider

protocol QuantityImage {
    func showQuantity(whole: Int, fraction: Fraction, animated: Bool)
}

class IngredientQuantityView: UIView, ASValueTrackingSliderDataSource, QuantityViewDelegate, EditableFractionViewDelegate {

    @IBOutlet weak var quantityImageContainer: UIView!
    @IBOutlet weak var fractionSlider: ASValueTrackingSlider!
    @IBOutlet weak var fractionTextInputView: EditableFractionView!
    @IBOutlet weak var quantityView: QuantityView!
    @IBOutlet weak var enterManuallyButton: UIButton!

    fileprivate var quantityImage: QuantityImage?

    fileprivate let sliderFractionLimit: Float = 0.8 // not bigger than this

    var onQuantityChanged: ((Int, Fraction) -> Void)?
    fileprivate var didLayoutSubviews = false

    static func createView() -> IngredientQuantityView {
        return Bundle.loadView("IngredientQuantityView", owner: self) as! IngredientQuantityView
    }

    fileprivate var wholeQuantity: Int = IngredientDataController.defaultQuantity {
        didSet {
            notifyQuantityChanged()
        }
    }

    fileprivate var fraction: Fraction = IngredientDataController.defaultFraction {
        didSet {
            notifyQuantityChanged()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    fileprivate func initSlider() {
        fractionSlider.maximumValue = 1
        fractionSlider.setMaxFractionDigitsDisplayed(1)
        fractionSlider.popUpViewCornerRadius = 12
        fractionSlider.popUpViewColor = Theme.blue
        //fractionSlider.font =
        fractionSlider.textColor = UIColor.white
        fractionSlider.value = fraction.decimalValue
        fractionSlider.dataSource = self
    }

    fileprivate func initQuantityView() {
        quantityView.quantity = Float(wholeQuantity)
        quantityView.delegate = self
    }

    fileprivate func initFractionEditableView() {
        fractionTextInputView.delegate = self
    }

    func configure(unit: Providers.Unit, fraction: Fraction?) {

        quantityImageContainer.removeSubviews()

        let viewToAdd: UIView & QuantityImage = {
            switch unit.id {
            default:
                return MoundsView()
            }
        } ()

        viewToAdd.translatesAutoresizingMaskIntoConstraints = false
        quantityImageContainer.addSubview(viewToAdd)
        viewToAdd.fillSuperview()

        self.quantityImage = viewToAdd
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initSlider()
        initQuantityView()
        initFractionEditableView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !didLayoutSubviews else { return }
        didLayoutSubviews = true

        delay(0.2) { // without delay wholeQuantity disappears! (only fraction should disappear) TODO fix
            self.quantityImage?.showQuantity(whole: self.wholeQuantity, fraction: self.fraction, animated: false)
        }
    }

    @IBAction func onTapEnterManually(_ sender: UIButton) {
        UIView.animate(withDuration: Theme.defaultAnimDuration, animations: {
            self.enterManuallyButton.alpha = 0
            self.fractionTextInputView.alpha = 1
        }) { finished in
//            self.enterManuallyButton.removeFromSuperview()
            self.enterManuallyButton.isHidden = true
        }
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

        let valueInRange = fraction.decimalValue * sliderFractionLimit
        let fractionInRange = rationalApproximationOf(x0: Double(valueInRange))

        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fractionInRange, animated: true)
        fractionTextInputView.prefill(fraction: fractionInRange)

        self.fraction = fractionInRange
//        delegate?.onSelectFraction(fraction: fraction)
    }

    fileprivate func notifyQuantityChanged() {
        onQuantityChanged?(wholeQuantity, fraction)
    }

    // MARK: - ASValueTrackingSliderDataSource

    func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {

        let valueInRange = value * sliderFractionLimit
        let fractionInRange = rationalApproximationOf(x0: Double(valueInRange))

        switch fractionInRange.decimalValue {
        case 0: return "0"
        case 1: return "1"
        default: return "\(fractionInRange.numerator)/\(fractionInRange.denominator)"
        }
    }

    // MARK: - QuantityViewDelegate

    func onRequestUpdateQuantity(_ delta: Float) {
        wholeQuantity = wholeQuantity + Int(delta)
        quantityView.quantity = Float(wholeQuantity)
        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fraction, animated: true)
    }

    func onQuantityInput(_ quantity: Float) {
    }

    // MARK: EditableFractionViewDelegate

    func onFractionInputChange(fractionInput: Fraction?) {
        if let fraction = fractionInput {
            // Replace possible division by 0 by a valid 0 value fraction - we shouldn't expect maths of the users.
            let correctedFraction: Fraction = {
                return fraction.denominator == 0 ? Fraction(numerator: 0, denominator: 1) : fraction
            } ()
            let isValid = abs(correctedFraction.decimalValue) < 1
            if isValid {
                quantityImage?.showQuantity(whole: wholeQuantity, fraction: correctedFraction, animated: true)
                fractionSlider.value = correctedFraction.decimalValue
                self.fraction = correctedFraction
            }
            fractionTextInputView.showValid(valid: isValid)
        }
    }
}
