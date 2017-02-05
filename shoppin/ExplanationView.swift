//
//  ExplanationView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 05/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol ExplanationViewDelegate: class {
    
    func onGotItTap(sender: UIButton)
}

class ExplanationView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var gotItButton: UIButton!
    
    var delegate: ExplanationViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view = Bundle.loadView("ExplanationView", owner: self)!
        
//        view.frame = bounds
        // Make the view stretch with containing view
//        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
    }
    
    @IBAction func onGotItTap(sender: UIButton) {
        delegate?.onGotItTap(sender: sender)
    }
}
