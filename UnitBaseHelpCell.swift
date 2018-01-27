//
//  UnitBaseHelpCell.swift
//  groma
//
//  Created by Ivan Schuetz on 23.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class UnitBaseHelpCell: UITableViewCell {

    struct CellModel {
        let itemName: String
        let quantity: Float
        let baseQuantity: Float
        let secondBaseQuantity: Float?
        let unit: String?
        let referenceQuantity: Float
        let price: Float
        let image: UIImage
    }

    @IBOutlet weak var helpImageView: UIImageView!

    @IBOutlet weak var firstLineContainer: UIView!
    @IBOutlet weak var secondLineContainer: UIView!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var secondBaseQuantityLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var baseQuantityLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var referenceQuantityLabel: UILabel!
    @IBOutlet weak var referenceUnitLabel: UILabel!
    @IBOutlet weak var equalsLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    @IBOutlet weak var nameToSecondBaseConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondBaseToXConstraint: NSLayoutConstraint!
    @IBOutlet weak var xToBaseConstraint: NSLayoutConstraint!
    @IBOutlet weak var referenceUnitToEqualsConstraint: NSLayoutConstraint!
    @IBOutlet weak var equalsToPriceConstraint: NSLayoutConstraint!

    fileprivate var circles: [UIView] = []

    func config(model: CellModel, circleColorsDictionary: Dictionary<BaseUnitHelpItemType, UIColor>, animateCircles: Bool) {
        helpImageView.image = model.image

        nameLabel?.text = model.itemName
        secondBaseQuantityLabel.text = model.secondBaseQuantity?.quantityString
        baseQuantityLabel.text = model.baseQuantity.quantityString
        unitLabel.text = model.unit
        referenceQuantityLabel.text = model.referenceQuantity.quantityString
        referenceUnitLabel.text = model.unit
        priceLabel.text = model.price.toLocalCurrencyString()

        if model.secondBaseQuantity == nil {
            nameToSecondBaseConstraint.constant = 0
            secondBaseToXConstraint.constant = 0
            xLabel.text = ""
        } else {
            nameToSecondBaseConstraint.constant = 4
            secondBaseToXConstraint.constant = 4
            xLabel.text = "x"
        }

        DispatchQueue.main.async {
            for circle in self.circles {
                circle.removeFromSuperview()
            }
            self.addCircles(model: model, circleColorsDictionary: circleColorsDictionary, animated: animateCircles)
        }
    }

    fileprivate func addCircles(model: CellModel, circleColorsDictionary: Dictionary<BaseUnitHelpItemType, UIColor>, animated: Bool) {

        let labels: [UILabel] = [baseQuantityLabel, unitLabel, referenceQuantityLabel, referenceUnitLabel, priceLabel] + (model.secondBaseQuantity == nil ? [] : [secondBaseQuantityLabel])

        for label in labels {

            guard let container = label.superview else {
                logger.e("Invalid state: no superview for label: \(label)", .ui)
                continue
            }

            let center = contentView.convert(label.center, from: container)

            let circleSize: CGFloat = 7
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: circleSize, height: circleSize))

            let itemType: BaseUnitHelpItemType? = {
                switch label {
                case secondBaseQuantityLabel: return .secondBase
                case baseQuantityLabel: return .base
                case unitLabel: return .unit
                case referenceQuantityLabel: return .refQuantity
                case referenceUnitLabel: return .unit
                case priceLabel: return .price
                default: return nil
                }
            } ()

            circle.backgroundColor = itemType.map { circleColorsDictionary[$0] } ?? {
                logger.e("Item type or color not found, returning black", .ui)
                return UIColor.black
            } ()

            circle.layer.cornerRadius = circleSize / 2
            self.contentView.addSubview(circle)
            circle.center = center.copy(y: center.y + 14)
            circles.append(circle)

            if animated {
                circle.transform = CGAffineTransform(scaleX: 0, y: 0)
                circle.alpha = 0.5
                UIView.animate(withDuration: 1, delay: 0.8, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [], animations: {
                    circle.transform = CGAffineTransform(scaleX: 1, y: 1)
                    circle.alpha = 1
                }, completion: { _ in
                })
            }
        }
    }
}
