//
//  RecipeTextCell.swift
//  groma
//
//  Created by Ivan Schuetz on 25.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class RecipeTextCell: UITableViewCell {

    @IBOutlet weak var recipeTextLabel: UILabel!

    func config(recipeText: NSAttributedString) {
        recipeTextLabel.attributedText = recipeText
    }
}
