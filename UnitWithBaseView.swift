//
//  UnitWithBaseView.swift
//  groma
//
//  Created by Ivan Schuetz on 20.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class UnitWithBaseView: HandlingView {

    @IBOutlet weak var unitImageView: UIImageView!

    @IBOutlet weak var unitImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var unitImageViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    fileprivate func sharedInit() {
        let view = Bundle.loadView("UnitWithBaseView", owner: self)!
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.fillSuperview()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        unitImageView.tintColor = Theme.lightGrey2
        
        layer.borderColor = Theme.midGrey.cgColor
        layer.backgroundColor = UIColor.white.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4

        unitImageViewWidthConstraint.constant = DimensionsManager.unitInUnitBaseViewSize
        unitImageViewHeightConstraint.constant = DimensionsManager.unitInUnitBaseViewSize
    }

    func configure(onTap: (() -> Void)?) {
        touchHandler = {
            onTap?()
        }
    }

    func show(base: Float, secondBase: Float?, unitId: UnitId, unitName: String) {

        // Unit image
        unitImageView.image = Theme.unitImage(unitId: unitId)
        if unitImageView.image == nil { // Custom units
            initialsLabel.text = String(unitName.prefix(2).uppercased())
            initialsLabel.isHidden = false
        } else {
            initialsLabel.isHidden = true
        }

        // Text label
        let unitName: String = {
            if unitId == .none {
                return base > 1 ? trans("recipe_unit_plural") : trans("recipe_unit_singular")
            } else {
                return unitName
            }
        } ()
        let baseString = base.quantityStringHideZero
        let secondBaseString = secondBase.map { $0.quantityStringHideZero } ?? ""
        let basesSeparator = !baseString.isEmpty && !secondBaseString.isEmpty ? "x" : ""
        label.text = "\(secondBaseString)\(basesSeparator)\(baseString) \(unitName)"
        label.sizeToFit()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        // width: + left space + middle + right space, height: + top space * 2
        return CGSize(width: label.intrinsicContentSize.width + 10 + 15 + 10 + unitImageView.width, height: max(label.height, unitImageView.height) + 2 * DimensionsManager.unitBaseViewTopBottomPadding)
    }
}
