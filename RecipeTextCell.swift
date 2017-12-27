//
//  RecipeTextCell.swift
//  groma
//
//  Created by Ivan Schuetz on 25.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class RecipeTextCell: UITableViewCell {

    @IBOutlet weak var recipeTextLabel: UILabel!

    func config(recipeText: NSAttributedString) {
        recipeTextLabel.attributedText = recipeText.string.isEmpty ? NSAttributedString(string: trans("recipe_edit_to_enter_text")) : recipeText
    }
}
