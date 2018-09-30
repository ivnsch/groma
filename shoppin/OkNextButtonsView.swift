//
//  OkNextButtonsView.swift
//  shoppin
//
//  Created by ischuetz on 08/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

protocol OkNextButtonsViewDelegate: class {
    func onOkEditModusTap()
    func onOkAddModusTap()
    func onOkNextAddModusTap()
    func onCancelAddModusTap()
    func onCancelEditModusTap()
}

enum AddModus {
    case add, update
}

class OkNextButtonsView: UIView {

    weak var delegate: OkNextButtonsViewDelegate?
    
    @IBOutlet weak var addModusView: UIView!
    @IBOutlet weak var editModusView: UIView!
    
    var addModus: AddModus = .add {
        didSet {
            if addModus == .add {
                addModusView.isHidden = false
                editModusView.isHidden = true
            } else {
                addModusView.isHidden = true
                editModusView.isHidden = false
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
    
    fileprivate func xibSetup() {
        let view = Bundle.loadView("OkNextButtonsView", owner: self)!
        
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onOkEditModusTap(_ sender: UIButton) {
        delegate?.onOkAddModusTap()
    }
    
    @IBAction func onOkAddModusTap(_ sender: UIButton) {
        delegate?.onOkAddModusTap()
    }

    @IBAction func onOkNextAddModusTap(_ sender: UIButton) {
        delegate?.onOkNextAddModusTap()
    }
    
    @IBAction func onCancelAddModusTap(_ sender: UIButton) {
        delegate?.onCancelAddModusTap()
    }
    
    @IBAction func onCancelEditModusTap(_ sender: UIButton) {
        delegate?.onCancelEditModusTap()
    }
}
