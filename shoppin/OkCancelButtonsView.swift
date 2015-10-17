//
//  OkCancelButtonsView.swift
//  shoppin
//
//  Created by ischuetz on 13/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol OkCancelButtonsViewDelegate {
    func onOkTap()
    func onCancelTap()
}

class OkCancelButtonsView: UIView {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!

    var delegate: OkCancelButtonsViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    private func xibSetup() {
        let view = NSBundle.loadView("OkCancelButtonsView", owner: self)!
        
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onOkTap(sender: UIButton) {
        delegate?.onOkTap()
    }
    
    @IBAction func onCancelTap(sender: UIButton) {
        delegate?.onCancelTap()
    }
}