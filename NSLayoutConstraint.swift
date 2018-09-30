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
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutConstraint.Attribute.width)
    }
    
    class func matchHeight(view: UIView, otherView: UIView) -> NSLayoutConstraint {
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutConstraint.Attribute.height)
    }
    
    fileprivate class func sameAttributeConstraint(view: UIView, otherView: UIView, multiplier: Float = 1, constant: Float = 0, attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: attribute, relatedBy: NSLayoutConstraint.Relation.equal, toItem: otherView, attribute: attribute, multiplier: CGFloat(multiplier), constant: CGFloat(constant))
    }
}
