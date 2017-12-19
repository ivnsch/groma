//
//  IngredientDataSubHeaderCell.swift
//  groma
//
//  Created by Ivan Schuetz on 19.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class IngredientDataSubHeaderCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
}
