//
//  UIView.swift
//  shoppin
//
//  Created by ischuetz on 29.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension UIView {
   
    func centerInParent(constantX:Float = 0, constantY:Float = 0) {
        self.centerXInParent(constantX)
        self.centerYInParent(constantY)
    }
    
    func centerYInParent(constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func centerXInParent(constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func positionBelowView(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func alignTop(view:UIView, constant:Float = 0) -> NSLayoutConstraint {
        let c = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: CGFloat(constant))
        self.superview!.addConstraint(c)
        return c
    }
    
    func matchSize(view: UIView) {
        self.superview?.addConstraints([
            NSLayoutConstraint.matchWidth(view: self, otherView: view),
            NSLayoutConstraint.matchHeight(view: self, otherView: view)])
    }
    
    /**
    Toggles a semi-transparent, blocking progress indicator overlay on this view
    */
    func defaultProgressVisible(visible: Bool = false) {
        if visible {
            if self.viewWithTag(ViewTags.GlobalActivityIndicator) == nil {
                let view = UIView(frame: self.frame)
                view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
                view.tag = ViewTags.GlobalActivityIndicator
                
                let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
                let size: CGFloat = 50
                let sizeH: CGFloat = size/2
                activityIndicator.frame = CGRect(x: self.frame.width / 2 - sizeH, y: self.frame.height / 2 - sizeH, width: size, height: size)
                activityIndicator.startAnimating()
                
                view.addSubview(activityIndicator)
                self.addSubview(view)
            }
        } else {
            self.viewWithTag(ViewTags.GlobalActivityIndicator)?.removeFromSuperview()
        }
    }
}
