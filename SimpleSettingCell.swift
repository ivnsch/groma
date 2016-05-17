//
//  SimpleSettingCell.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol SimpleSettingCellDelegate {
    func onSimpleSettingHelpTap(cell: SimpleSettingCell, setting: SimpleSetting)
}

class SimpleSettingCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    
    var delegate: SimpleSettingCellDelegate?
    
    var setting: SimpleSetting? {
        didSet {
            if let setting = setting {
                label.text = setting.label
                label.textColor = setting.labelColor
                helpButton.hidden = !setting.hasHelp
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    @IBAction func onHelpTap(sender: UIButton) {
        if let setting = setting {
            delegate?.onSimpleSettingHelpTap(self, setting: setting)
        } else {
            QL3("No setting set")
        }
    }
}