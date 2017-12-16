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
    func showQuantity(whole: Int, fraction: Fraction)
}

class IngredientQuantityView: UIView, ASValueTrackingSliderDataSource, QuantityViewDelegate {

    @IBOutlet weak var quantityImageContainer: UIView!
    @IBOutlet weak var fractionSlider: ASValueTrackingSlider!
    @IBOutlet weak var fractionTextInputView: EditableFractionView!
    @IBOutlet weak var quantityView: QuantityView!

    fileprivate var quantityImage: QuantityImage?

    static func createView() -> IngredientQuantityView {
        return Bundle.loadView("IngredientQuantityView", owner: self) as! IngredientQuantityView
    }

    fileprivate var wholeQuantity: Int = 1
    fileprivate var fraction: Fraction = Fraction(numerator: 1, denominator: 2)

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

        fractionSlider.dataSource = self
    }

    fileprivate func initQuantityView() {
        quantityView.quantity = 1
        quantityView.delegate = self
    }

    func configure(unit: Providers.Unit, fraction: Fraction?) {

        quantityImageContainer.removeSubviews()

        let viewToAdd: UIView & QuantityImage = {
            switch unit.id {
            case .spoon, .teaspoon:
                return MoundsView()
            default:
                fatalError("TODO")
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
    }
    
    @IBAction func onTapEnterManually(_ sender: UIButton) {
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

        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fraction)
        fractionTextInputView.prefill(fraction: fraction)

        self.fraction = fraction
//        delegate?.onSelectFraction(fraction: fraction)
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

    // MARK: - QuantityViewDelegate

    func onRequestUpdateQuantity(_ delta: Float) {
        wholeQuantity = wholeQuantity + Int(delta)
        quantityView.quantity = Float(wholeQuantity)
        quantityImage?.showQuantity(whole: wholeQuantity, fraction: fraction)
    }

    func onQuantityInput(_ quantity: Float) {
    }
}
