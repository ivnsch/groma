//
//  MyTipPopup.swift
//  shoppin
//
//  Created by ischuetz on 03/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import CMPopTipView

class MyTipPopup: CMPopTipView {

    init(customView: UIView, borderColor: UIColor? = UIColor.flatGrayColor()) {
        super.init(customView: customView)
        self.borderColor = borderColor
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sharedInit() {
        hasShadow = false
        borderWidth = 1
        has3DStyle = false
        hasGradientBackground = false
        backgroundColor = UIColor.whiteColor()
        dismissTapAnywhere = true
        disableTapToDismiss = false
        animation = CMPopTipAnimationPop
    }
}
