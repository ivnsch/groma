//
//  SelectIngredientDataHeader.swift
//  groma
//
//  Created by Ivan Schuetz on 16.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

struct SelectIngredientDataHeaderInputs {
    var productName: String
    var unitName: String
    var quantity: Float
    var fraction: Fraction
}

class SelectIngredientDataHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var fractionLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var wholeNumberTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var fractionTrailingConstraint: NSLayoutConstraint!

    fileprivate var titleLabelsFont: UIFont?

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = Theme.lightGrey2
        titleLabelsFont = itemNameLabel.font // NOTE: Assumes that all labels in title have same font
    }

    static func createView() -> SelectIngredientDataHeader {
        return Bundle.loadView("SelectIngredientDataHeader", owner: nil) as! SelectIngredientDataHeader
    }

    func update(inputs: SelectIngredientDataHeaderInputs) {
        guard let titleLabelsFont = titleLabelsFont else {logger.e("No title labels font. Can't update title."); return}

        itemNameLabel.text = inputs.productName
        
        let quantity = inputs.quantity

        let fractionStr = inputs.fraction.isValidAndNotZeroOrOneByOne ? inputs.fraction.description : ""
        // Don't show quantity if it's 0 and there's a fraction. If there's no fraction we show quantity 0, because otherwise there wouldn't be any number and this doesn't make sense.
        let wholeNumberStr = quantity == 0 ? (fractionStr.isEmpty ? quantity.quantityString : "") : "\(quantity.quantityString)"
        let unitStr = inputs.unitName

        let boldTime: Double = 1

        if fractionLabel.text != fractionStr {
            fractionLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if wholeNumberLabel.text != wholeNumberStr {
            wholeNumberLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }
        if unitLabel.text != unitStr {
            unitLabel.animateBold(boldTime, regularFont: titleLabelsFont)
        }

        fractionLabel.text = fractionStr
        wholeNumberLabel.text = wholeNumberStr
        unitLabel.text = unitStr

        wholeNumberTrailingConstraint.constant = wholeNumberStr.isEmpty || fractionStr.isEmpty ? 0 : 10
        fractionTrailingConstraint.constant = wholeNumberStr.isEmpty && fractionStr.isEmpty ? 0 : 10
    }
}
