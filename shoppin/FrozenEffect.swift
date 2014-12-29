//
//  FrozenEffect.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class FrozenEffect {
    
    class func apply(view:UIView) {
        let blurView = createBlurView(forView: view)
        
        blurView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        let views:Dictionary = ["blurView": blurView]
        
        view.insertSubview(blurView, atIndex: 0)
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[blurView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[blurView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: views))
    }
    
    private class func createBlurView(forView view:UIView) -> UIView {
        var blurView:UIView
        
        if NSClassFromString("UIBlurEffect") != nil {
            let blurEffect:UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.ExtraLight)
            blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.frame //view.frame ?? (controller's)
        } else {
            blurView = UIToolbar(frame: view.bounds)
        }
        
        return blurView
    }

}
