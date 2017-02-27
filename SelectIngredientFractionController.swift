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

class SelectIngredientFractionController: UIViewController, EditableFractionViewDelegate, FillShapeViewDelegate {

    @IBOutlet weak var fractionImageView: FillShapeView!
    @IBOutlet weak var fractionTextInputView: EditableFractionView!
    
    var delegate: SelectIngredientFractionControllerDelegate?
    
    var onUIReady: (() -> Void)?
    
    var unit: Providers.Unit? {
        didSet {
            guard let unit = unit else {return}
            let (imageName, maskName): (String, String) = {
                switch unit.id {
                case .teaspoon: fallthrough
                case .spoon: return ("spoon_shape", "spoon_shape_mask")
                case .liter: return ("bottle_shape", "bottle_shape_mask")
                default: return ("default_shape", "default_shape_mask")
                }
            }()
            
            fractionImageView.config(shapeImageName: imageName, maskImageName: maskName)
            fractionImageView.fillTo(percentage: 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fractionTextInputView.delegate = self
        
        fractionImageView.delegate = self
        
        onUIReady?()
    }
    
    // MARK: - EditableFractionViewDelegate
    
    func onFractionInputChange(fractionInput: Fraction?) {
        
        // Don't allow fractions > 1 - this doesn't make sense + currently breaks the fill shape animation
        let finalFractionInput = fractionInput.map {
            $0.decimalValue >= 1 ? Fraction.one : $0
        }
        
        if let fraction = finalFractionInput {
            fractionImageView.fillTo(percentage: CGFloat(fraction.decimalValue))
        } else {
            fractionImageView.fillTo(percentage: 1)
        }
        
        delegate?.onSelectFraction(fraction: finalFractionInput)
    }
    
    // MARK: - FillShapeViewDelegate
    
    func onFillShapeValueUpdated(fraction: Fraction) {
        fractionTextInputView.prefill(fraction: fraction)
        delegate?.onSelectFraction(fraction: fraction)
    }
}
