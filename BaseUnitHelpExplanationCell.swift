//
//  BaseUnitHelpExplanationCell.swift
//  groma
//
//  Created by Ivan Schuetz on 27.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class BaseUnitHelpExplanationCell: UITableViewCell {

    @IBOutlet weak var explanationLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        explanationLabel.text = trans("base_unit_help_note_explanation_text")
    }
}
