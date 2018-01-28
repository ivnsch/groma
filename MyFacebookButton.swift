//
//  MyFacebookButton.swift
//  groma
//
//  Created by Ivan Schuetz on 28.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

class MyFacebookButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

    fileprivate func xibSetup() {
        let view = Bundle.loadView("MyFacebookButton", owner: self)!

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.fillSuperview()

        backgroundColor = UIColor.clear
    }
}
