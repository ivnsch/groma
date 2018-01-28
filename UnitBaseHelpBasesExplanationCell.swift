//
//  UnitBaseHelpBasesExplanationCell.swift
//  groma
//
//  Created by Ivan Schuetz on 27.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

class UnitBaseHelpBasesExplanationCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        label.text = "You enter unit, base quantity and second base quantity in the view where you opened this popup";
    }
}
