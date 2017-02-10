//
//  FractionView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 10/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class FractionView: UIView {
    
    //@IBOutlet weak var wholeNumberLabel: UILabel!
    @IBOutlet weak var numeratorLabel: UILabel!
    @IBOutlet weak var denominatorLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    
    var fraction: Fraction? {
        didSet {
            if let fraction = fraction {
                //wholeNumberLabel.text = fraction.wholeNumber == 0 ? "" : "\(fraction.wholeNumber)"
                numeratorLabel.text = "\(fraction.numerator)"
                denominatorLabel.text = "\(fraction.denominator)"
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lineView.rotate(45)
    }
}
