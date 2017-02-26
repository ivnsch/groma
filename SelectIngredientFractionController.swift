//
//  SelectIngredientFractionController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 25/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol SelectIngredientFractionControllerDelegate {
    func onSelectFraction(fraction: Fraction?)
}

class SelectIngredientFractionController: UIViewController, EditableFractionViewDelegate {

    @IBOutlet weak var fractionImageView: UIView!
    @IBOutlet weak var fractionTextInputView: EditableFractionView!
    
    var delegate: SelectIngredientFractionControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fractionTextInputView.delegate = self
    }
    
    // MARK: - EditableFractionViewDelegate
    
    func onFractionInputChange(fractionInput: Fraction?) {
        delegate?.onSelectFraction(fraction: fractionInput)
    }
}
