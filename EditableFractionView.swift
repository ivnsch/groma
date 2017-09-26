//
//  EditableFractionView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 18/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers


protocol EditableFractionViewDelegate {
    
    // Nil means no fraction / one of the text fields is empty
    func onFractionInputChange(fractionInput: Fraction?)
}

class EditableFractionView: UIView {
    
    @IBInspectable var isBold: Bool = false
    
    @IBOutlet weak var numeratorTextField: UITextField!
    @IBOutlet weak var denominatorTextField: UITextField!
    @IBOutlet weak var lineView: UIView!
    
    var delegate: EditableFractionViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
    fileprivate func xibSetup() {
        let view = Bundle.loadView("EditableFractionView", owner: self)!
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        view.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }
    
    
    var fraction: Fraction? {
        guard let numerator = (numeratorTextField.text.flatMap{Int($0)}) else {return nil}
        guard let denominator = (denominatorTextField.text.flatMap{Int($0)}) else {return nil}
        
        return Fraction(wholeNumber: 0, numerator: numerator, denominator: denominator)
    }
    
    fileprivate func initTextListeners() {
        for textField in [numeratorTextField, denominatorTextField] {
            textField?.addTarget(self, action: #selector(onFractionInputChange(_:)), for: .editingChanged)
        }
    }
    
    func onFractionInputChange(_ sender: UITextField) {
        // If the input is nil (meaning at least one of the text fields is empty), we pass nil to the delegate
        // Note that we handle invalid characters theh same as if fields are empty. Shouldn't happen anyway as keyboard should be numeric.
        delegate?.onFractionInputChange(fractionInput: fraction)
    }
    
    func prefill(fraction: Fraction?) {
        if let fraction = fraction {
            numeratorTextField.text = "\(fraction.numerator)"
            denominatorTextField.text = "\(fraction.denominator)"
        } else {
            clear()
        }
    }
    
    func clear() {
        numeratorTextField.text = ""
        denominatorTextField.text = ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lineView.rotate(45)
        
        initTextListeners()
    }
    
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: numeratorTextField.width + lineView.width + denominatorTextField.width + 5 + 20, height: numeratorTextField.height + 20) // width: 5 pt (*2) spacing to line, 10 pt for 2*2 pt center constraint offset in labels + 6pt just to make a little more space. TODO copied from FractionView - check if these numbers are also valid here
//    }
    
    var hasFractionInputFocus: Bool {
        return numeratorTextField.isFirstResponder || denominatorTextField.isFirstResponder
    }
}
