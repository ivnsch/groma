//
//  SimpleSettingCell.swift
//  shoppin
//
//  Created by ischuetz on 02/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class SimpleSettingCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    var setting: SimpleSetting? {
        didSet {
            if let setting = setting {
                label.text = setting.label
                label.textColor = setting.labelColor
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .None
    }
}