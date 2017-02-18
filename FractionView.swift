//
//  FractionView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 10/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

protocol FractionViewDelegate {
    func onLongPress()
}

@IBDesignable class FractionView: UIView {
    
    @IBInspectable var isBold: Bool = false
    
    //@IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var numeratorLabel: UILabel!
    @IBOutlet weak var denominatorLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    
    var delegate: FractionViewDelegate?
    
    var markedToDelete: Bool = false

    var fraction: DBFraction? {
        didSet {
            if let fraction = fraction {
                //wholeNumberLabel.text = fraction.wholeNumber == 0 ? "" : "\(fraction.wholeNumber)"
                numeratorLabel.text = "\(fraction.numerator)"
                denominatorLabel.text = "\(fraction.denominator)"
                
                numeratorLabel.sizeToFit()
                denominatorLabel.sizeToFit()
                
                invalidateIntrinsicContentSize()
            }
        }
    }
    
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
        let view = Bundle.loadView("FractionView", owner: self)!
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        view.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
    }
    
    func mark(toDelete: Bool, animated: Bool) {
        animIf(animated) {[weak self] in
            self?.backgroundColor = toDelete ? UIColor.flatRed : UIColor.white
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lineView.rotate(45)
        
        if isBold {
            _ = numeratorLabel.makeBold()
            _ = denominatorLabel.makeBold()
        }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(longPress)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: numeratorLabel.width + lineView.width + denominatorLabel.width + 5 + 20, height: numeratorLabel.height + 20) // width: 5 pt (*2) spacing to line, 10 pt for 2*2 pt center constraint offset in labels + 20pt just to make a little more space.
    }
    
    func longPress(_ sender: Any) {
        delegate?.onLongPress()
    }
}
