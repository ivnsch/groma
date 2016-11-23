//
//  OkCancelButtonsView.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol OkCancelButtonsViewDelegate: class {
    func onOkTap()
    func onCancelTap()
}

class OkCancelButtonsView: UIView {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    weak var delegate: OkCancelButtonsViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view = Bundle.loadView("OkCancelButtonsView", owner: self)!
        
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onOkTap(_ sender: UIButton) {
        delegate?.onOkTap()
    }
    
    @IBAction func onCancelTap(_ sender: UIButton) {
        delegate?.onCancelTap()
    }
}
