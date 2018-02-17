//
//  ReferenceQuantityPriceHelpCell.swift
//  groma
//
//  Created by Ivan Schuetz on 27.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class ReferenceQuantityPriceHelpCell: UITableViewCell {

    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var priceView: PriceView!
    @IBOutlet weak var secondExplanationLabel: UILabel!
    @IBOutlet weak var touchBlocker: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        priceView.show(price: 0)
        secondExplanationLabel.text = trans("base_unit_help_reference_quantity_price_2")

        DispatchQueue.main.async {
            self.showTooltip()
        }
    }

    func config(colorDict: [BaseUnitHelpItemType: UIColor]) {
        let text = trans("base_unit_help_reference_quantity_price")
        explanationLabel.attributedText = UnitBaseHelpCellExplanationHighlighter().generateAttributedString(colorDict: colorDict, text: text, font: explanationLabel.font)
    }

    func showTooltip() {
        let controller = createPriceInputsControler()
        let popup = MyTipPopup(customView: controller.view)
        popup.preferredPointDirection = .down
        popup.dismissTapAnywhere = false
        popup.sidePadding = 50
        popup.presentPointing(at: priceView, in: contentView, animated: false)
        contentView.bringSubview(toFront: touchBlocker)
    }

    fileprivate func createPriceInputsControler() -> PriceInputsController {
        let controller = PriceInputsController()
        let tooltipWidth = contentView.width - 120
        controller.view.frame = CGRect(x: 0, y: 0, width: tooltipWidth, height: 50)

        controller.prefill(quantity: 1, secondQuantity: nil, price: 1.99, unitName: trans("unit_liter"))
        return controller
    }
}
