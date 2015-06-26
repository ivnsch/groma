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
        self.centerXInParent(constant: constantX)
        self.centerYInParent(constant: constantY)
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
}
