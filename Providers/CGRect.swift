//
//  CGRect.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

public extension CGRect {
    
    public var bounds: CGRect {
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    public func copy(_ x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) -> CGRect {
        return CGRect(
            x: x ?? self.origin.x,
            y: y ?? self.origin.y,
            width: width ?? self.width,
            height: height ?? self.height)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // Added because of LiquidFloatingActionButton library (library is not directly included - only some modified parts copied)
    // src: https://github.com/yoavlt/LiquidFloatingActionButton/blob/master/Pod/Classes/CGPointEx.swift
    /////////////////////////////////////////////////////////////////////////////////////
    
    public var rightBottom: CGPoint {
        get {
            return CGPoint(x: origin.x + width, y: origin.y + height)
        }
    }
    public var center: CGPoint {
        get {
            return origin.plus(rightBottom).mul(0.5)
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////

    public var rightTop: CGPoint {
        get {
            return CGPoint(x: origin.x + width, y: origin.y)
        }
    }

    public var leftBottom: CGPoint {
        get {
            return CGPoint(x: origin.x, y: origin.y + height)
        }
    }
    
    public func inset(_ top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) -> CGRect {
        return CGRect(x: origin.x + left, y: origin.y + top, width: width - left - right, height: height - top - bottom)
    }
    
    public func insetAll(_ inset: CGFloat) -> CGRect {
        return self.inset(inset, bottom: inset, left: inset, right: inset)
    }
}
