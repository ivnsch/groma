//
//  SimpleSettingCell.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol SimpleSettingCellDelegate {
    func onSimpleSettingHelpTap(_ cell: SimpleSettingCell, setting: SimpleSetting)
}

class SimpleSettingCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var helpImage: UIImageView!

    var delegate: SimpleSettingCellDelegate?
    
    var setting: SimpleSetting? {
        didSet {
            if let setting = setting {
                label.text = setting.label
                label.textColor = setting.labelColor
                [helpButton, helpImage].forEach { $0.isHidden = !setting.hasHelp }

                helpButton.accessibilityTraits = UIAccessibilityTraitButton
                helpButton.accessibilityLabel = trans("accessibility_settings_button_help", setting.label)

            }
        }
    }
    
    @IBAction func onHelpTap(_ sender: UIButton) {
        if let setting = setting {
            delegate?.onSimpleSettingHelpTap(self, setting: setting)
        } else {
            logger.w("No setting set")
        }
    }
}
