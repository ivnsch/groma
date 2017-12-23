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

        layer.borderColor = Theme.midGrey.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
    }

    func configure(unitId: UnitId, unitName: String, base: Float, onTap: (() -> Void)?) {
        touchHandler = {
            onTap?()
        }
        show(base: base, unitId: unitId, unitName: unitName)
    }

    func show(base: Float, unitId: UnitId, unitName: String) {
        unitImageView.image = Theme.unitImage(unitId: unitId)
        unitImageView.tintColor = Theme.midGrey

        let unitName: String = {
            if unitId == .none {
                return base > 1 ? trans("recipe_unit_plural") : trans("recipe_unit_singular")
            } else {
                return unitName
            }
        } ()

        label.text = "\(base.quantityStringHideZero) \(unitName)"
        label.sizeToFit()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        // width: + left space + middle + right space, height: + top space * 2
        return CGSize(width: label.intrinsicContentSize.width + 10 + 15 + 10 + unitImageView.width, height: max(label.height, unitImageView.height) + 2 * 4)
    }
}
