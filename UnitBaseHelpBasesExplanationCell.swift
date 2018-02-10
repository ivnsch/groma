//
//  UnitBaseHelpBasesExplanationCell.swift
//  groma
//
//  Created by Ivan Schuetz on 27.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class UnitBaseHelpBasesExplanationCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    func config(colorDict: [BaseUnitHelpItemType: UIColor]) {
        let text = trans("base_unit_help_unit_bases");
        label.attributedText = UnitBaseHelpCellExplanationHighlighter().generateAttributedString(colorDict: colorDict, text: text, font: label.font)
    }
}
