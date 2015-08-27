//
//  NSLayoutConstraint.swift
//  shoppin
//
//  Created by ischuetz on 05/04/15.
//  Copyright (c) 2015 ivanschuetz. All rights reserved.
//

import Cocoa

extension NSLayoutConstraint {

    class func matchWidth(view view: NSView, otherView: NSView) -> NSLayoutConstraint {
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutAttribute.Width)
    }
    
    class func matchHeight(view view: NSView, otherView: NSView) -> NSLayoutConstraint {
        return NSLayoutConstraint.sameAttributeConstraint(view: view, otherView: otherView, multiplier: 1, constant: 0, attribute: NSLayoutAttribute.Height)
    }
    
    class func horizontalCenterConstraint(view: NSView, superview: NSView, multiplier: Float = 1, constant: Float = 0) -> NSLayoutConstraint {
        return self.sameAttributeConstraint(view: view, otherView: superview, multiplier: multiplier, constant: constant, attribute: NSLayoutAttribute.CenterX)
    }
    
    class func verticalCenterConstraint(view: NSView, superview: NSView, multiplier: Float = 1, constant: Float = 0) -> NSLayoutConstraint {
        return self.sameAttributeConstraint(view: view, otherView: superview, multiplier: multiplier, constant: constant, attribute: NSLayoutAttribute.CenterY)
    }
  
    // returns nil if views is empty
    class func distributeEvenlyHorizontallyConstraint(views: [NSView], leading: Float = 0, trailing: Float = 0) -> [NSLayoutConstraint]? {
        
        if !views.isEmpty {
            var elementsStr = ""
            var dictionary = Dictionary<String, NSView>()
            var firstViewStr: String?
            for (index, view) in views.enumerate() {
                let viewStr = "v\(index)"
                if index == 0 {
                    firstViewStr = viewStr
                    elementsStr += "[\(viewStr)]"
                } else {
                    elementsStr += "[\(viewStr)(==\(firstViewStr!))]"
                }
                dictionary[viewStr] = view
            }
            
            return NSLayoutConstraint.constraintsWithVisualFormat(
                "H:|-(\(leading))-\(elementsStr)-(\(trailing))-|",
                options: NSLayoutFormatOptions(),
                metrics: nil,
                views: dictionary) as [NSLayoutConstraint]
                
        } else {
            return nil
        }
    }
    
    private class func sameAttributeConstraint(view view: NSView, otherView: NSView, multiplier: Float = 1, constant: Float = 0, attribute: NSLayoutAttribute) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: view, attribute: attribute, relatedBy: NSLayoutRelation.Equal, toItem: otherView, attribute: attribute, multiplier: CGFloat(multiplier), constant: CGFloat(constant))
    }
}
