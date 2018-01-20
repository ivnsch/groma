//
//  AddRecipeTableViewHeader.swift
//  groma
//
//  Created by Ivan Schuetz on 23.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class AddRecipeTableViewHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!

    static func createView() -> AddRecipeTableViewHeader {
        return Bundle.loadView("AddRecipeTableViewHeader", owner: nil) as! AddRecipeTableViewHeader
    }

    func config(title: String, recipeColor: UIColor) {
        titleLabel.text = title
        titleLabel.backgroundColor = recipeColor
        titleLabel.textColor = UIColor(contrastingBlackOrWhiteColorOn: recipeColor, isFlat: true)
    }
}
