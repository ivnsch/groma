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
        fractionSlider.popUpViewColor = Theme.darkerBlue
        fractionSlider.thumbTintColor = Theme.darkerBlue
        //fractionSlider.font =
        fractionSlider.textColor = UIColor.white
        fractionSlider.value = fraction.decimalValue
        fractionSlider.dataSource = self
        fractionSlider.clipsToBounds = false
    }

    fileprivate func initQuantityView() {
        quantityView.quantity = Float(wholeQuantity)
        quantityView.delegate = self
    }

    fileprivate func initFractionEditableView() {
        fractionTextInputView.delegate = self
    }

    func configure(unitId: UnitId, whole: Int, fraction: Fraction) {

        let viewToAdd: UIView & QuantityImage = {
            switch unitId {
            default:
                // We could use different images for different types of units
                return MoundsView()
            }
        } ()
        self.quantityImage = viewToAdd

        self.wholeQuantity = whole
        self.fraction = fraction

        quantityImageContainer.removeSubviews()
        viewToAdd.translatesAutoresizingMaskIntoConstraints = false
        quantityImageContainer.addSubview(viewToAdd)
        viewToAdd.fillSuperview()
        layoutIfNeeded()

        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fraction, animated: false)
        quantityView.quantity = Float(wholeQuantity)
        fractionSlider.value = fraction.decimalValue
        fractionTextInputView.prefill(fraction: fraction)
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
        let fraction = toFraction(decimal: fractionSlider.value)

        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fraction, animated: true)
        fractionTextInputView.prefill(fraction: fraction)

        self.fraction = fraction
//        delegate?.onSelectFraction(fraction: fraction)
    }

    fileprivate func toFraction(decimal: Float) -> Fraction {
        let biggestFraction = Fraction(numerator: 3, denominator: 4)  // 0.75

        let sliderFractions: [Fraction] = [
            Fraction(numerator: 0, denominator: 1),
            Fraction(numerator: 1, denominator: 4), // 0.25
            Fraction(numerator: 1, denominator: 3), // 0.33
            Fraction(numerator: 1, denominator: 2), // 0.5
            Fraction(numerator: 2, denominator: 3), // 0.66
            biggestFraction
        ]

        var fraction: Fraction = biggestFraction
        for sliderFraction in sliderFractions {
            if fractionSlider.value <= sliderFraction.decimalValue {
                fraction = sliderFraction
                break
            }
        }
        return fraction
    }

    fileprivate func notifyQuantityChanged() {
        onQuantityChanged?(wholeQuantity, fraction)
    }

    // MARK: - ASValueTrackingSliderDataSource

    func slider(_ slider: ASValueTrackingSlider!, stringForValue value: Float) -> String! {

        let fraction = toFraction(decimal: value)

        if fraction.decimalValue == 0 {
            return "0"
        } else {
            return "\(fraction.numerator)/\(fraction.denominator)"
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
