//
//  NSLayoutConstraint.swift
//  shoppin
//
//  Created by ischuetz on 26/06/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import UIKit

// TODO is it possible to somehow merge this with the osx extension?
extension NSLayoutConstraint {

    class func matchWidth(view: UIView, otherView: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutAttribute.width)
    }
    
    class func matchHeight(view: UIView, otherView: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutAttribute.height)
    }
    
    fileprivate class func sameAttributeConstraint(view: UIView, otherView: UIView, multiplier: Float = 1, constant: Float = 0, attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: attribute, relatedBy: NSLayoutRelation.equal, toItem: otherView, attribute: attribute, multiplier: CGFloat(multiplier), constant: CGFloat(constant))
    }
}
