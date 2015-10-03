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

    override init(customView: UIView) {
        super.init(customView: customView)
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
        borderWidth = 0
        has3DStyle = false
        hasGradientBackground = false
        backgroundColor = UIColor(red: 1, green: 93/255, blue: 166/255, alpha: 1)
        dismissTapAnywhere = true
        disableTapToDismiss = false
        animation = CMPopTipAnimationPop
    }
}
