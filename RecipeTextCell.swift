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
    @IBOutlet weak var noTextContainer: UIView!
    @IBOutlet weak var noTextPlusImageView: UIImageView!
    @IBOutlet weak var noTextLabel: UILabel!

    func config(recipeText: NSAttributedString) {
        if recipeText.string.isEmpty {
            noTextLabel.text = trans("recipe_edit_to_enter_text")
            noTextPlusImageView.rotate(22.5) // reusing cross image, so rotate it to make it a "+"
            noTextPlusImageView.tintColor = UIColor(hexString: "BBBBBB")
            noTextContainer.isHidden = false
        } else {
            noTextContainer.isHidden = true
            recipeTextLabel.attributedText = recipeText
        }
    }
}
