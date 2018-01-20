//
//  DragView.swift
//  groma
//
//  Created by Ivan Schuetz on 20.01.18.
//  Copyright © 2018 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable
class DragView: UIView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        logger.i("height: \(height)", .ui)
        addSubview(lineView(y: 0))
        addSubview(lineView(y: 8))
    }

    fileprivate func lineView(y: CGFloat) -> UIView {
        let leftRightOffset: CGFloat = 1
        let view = UIView(frame: CGRect(x: leftRightOffset, y: y, width: width - (leftRightOffset * 2), height: 4))
        view.backgroundColor = UIColor(hexString: "AAAAAA")
        view.layer.cornerRadius = 3
        view.layer.borderColor = UIColor(hexString: "8E9697").cgColor
        view.layer.borderWidth = 0.5
        return view
    }
}
