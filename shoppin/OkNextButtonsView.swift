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
    case Add, Update
}

class OkNextButtonsView: UIView {

    weak var delegate: OkNextButtonsViewDelegate?
    
    @IBOutlet weak var addModusView: UIView!
    @IBOutlet weak var editModusView: UIView!
    
    var addModus: AddModus = .Add {
        didSet {
            if addModus == .Add {
                addModusView.hidden = false
                editModusView.hidden = true
            } else {
                addModusView.hidden = true
                editModusView.hidden = false
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
    
    private func xibSetup() {
        let view = NSBundle.loadView("OkNextButtonsView", owner: self)!
        
        view.frame = bounds
        // Make the view stretch with containing view
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        self.addSubview(view)
    }
    
    @IBAction func onOkEditModusTap(sender: UIButton) {
        delegate?.onOkAddModusTap()
    }
    
    @IBAction func onOkAddModusTap(sender: UIButton) {
        delegate?.onOkAddModusTap()
    }

    @IBAction func onOkNextAddModusTap(sender: UIButton) {
        delegate?.onOkNextAddModusTap()
    }
    
    @IBAction func onCancelAddModusTap(sender: UIButton) {
        delegate?.onCancelAddModusTap()
    }
    
    @IBAction func onCancelEditModusTap(sender: UIButton) {
        delegate?.onCancelEditModusTap()
    }
}
