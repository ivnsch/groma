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
    
    func centerYInParent(constant:Float = 0) {
        self.superview!.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: CGFloat(constant)))
    }
    
    func centerXInParent(constant:Float = 0) {
        self.superview!.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: CGFloat(constant)))
    }
}
