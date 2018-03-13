//
//  EmptyView.swift
//  groma
//
//  Created by Ivan Schuetz on 05.03.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

@IBDesignable class EmptyView: UIView {

    @IBOutlet weak var line1: UILabel!
    @IBOutlet weak var line2: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    fileprivate func xibSetup() {
        let view = Bundle.loadView("EmptyView", owner: self)!

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.fillSuperview()

        isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true

        backgroundColor = UIColor.clear
    }
}
