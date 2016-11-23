//
//  FrozenEffect.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

class FrozenEffect {
    
    class func apply(_ view:UIView) {
        let blurView = createBlurView(forView: view)
        
        blurView.translatesAutoresizingMaskIntoConstraints = false
        
        let views:Dictionary = ["blurView": blurView]
        
        view.insertSubview(blurView, at: 0)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[blurView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[blurView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views))
    }
    
    fileprivate class func createBlurView(forView view:UIView) -> UIView {
        var blurView:UIView
        
        if NSClassFromString("UIBlurEffect") != nil {
            let blurEffect:UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
            blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.frame //view.frame ?? (controller's)
        } else {
            blurView = UIToolbar(frame: view.bounds)
        }
        
        return blurView
    }

}
