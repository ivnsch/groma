//
//  SubmitView.swift
//  shoppin
//
//  Created by Ivan Schuetz on 20/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

protocol SubmitViewDelegate: class {
    func onSubmitButton()
}

@IBDesignable class SubmitView: UIView {

    weak var delegate: SubmitViewDelegate?
    
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func onSubmit(_ sender: UIButton) {
        delegate?.onSubmitButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func setButtonTitle(title: String) {
        submitButton.setTitle(title, for: .normal)
    }
    
    // TODO find a way to not have extra view here (add subview) since this is used in tableview cells.
    fileprivate func xibSetup() {
        let view = Bundle.loadView("SubmitView", owner: self)!
        
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        
        view.fillSuperview()
        
        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        backgroundColor = UIColor.clear
    }
}
