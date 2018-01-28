//
//  MyGoogleLoginButton.swift
//  groma
//
//  Created by Ivan Schuetz on 28.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit

@IBDesignable
class MyGoogleLoginButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

    fileprivate func xibSetup() {
        let view = Bundle.loadView("MyGoogleLoginButton", owner: self)!

        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)

        view.fillSuperview()

        backgroundColor = UIColor.clear
    }
}
