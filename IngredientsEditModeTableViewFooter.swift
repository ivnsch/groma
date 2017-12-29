//
//  IngredientsEditModeTableViewFooter.swift
//  groma
//
//  Created by Ivan Schuetz on 29.12.17.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

class IngredientsEditModeTableViewFooter: UITableViewHeaderFooterView {

    @IBOutlet weak var boldButton: UIButton!

    var boldTapHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Solves "Setting the background color on UITableViewHeaderFooterView has been deprecated. Please set a custom UIView with your desired background color to the backgroundView property instead."
        let bg = UIView()
        bg.backgroundColor = Theme.midGrey
        backgroundView = bg
    }
    static func createView() -> IngredientsEditModeTableViewFooter {
        return Bundle.loadView("IngredientsEditModeTableViewFooter", owner: nil) as! IngredientsEditModeTableViewFooter
    }

    @IBAction func onBoldTap(_sender: UIButton) {
        boldTapHandler?()
    }
}
