//
//  SwitchSettingCell.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol SwitchSettingCellDelegate: class {
    func onSwitch(setting: SwitchSetting, on: Bool)
}

class SwitchSettingCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switch_: UISwitch!
    
    weak var delegate: SwitchSettingCellDelegate?
    
    var setting: SwitchSetting? {
        didSet {
            if let setting = setting {
                label.text = setting.label
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
    
    @IBAction func onSwitchChanged(sender: UISwitch) {
        if let setting = setting {
            delegate?.onSwitch(setting, on: sender.on)
        } else {
            QL3("No setting")
        }
    }
}
