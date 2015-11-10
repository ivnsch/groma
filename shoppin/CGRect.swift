//
//  CGRect.swift
//  shoppin
//
//  Created by ischuetz on 09/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension CGRect {

    func copy(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) -> CGRect {
        return CGRectMake(
            x ?? self.origin.x,
            y ?? self.origin.y,
            width ?? self.width,
            height ?? self.height)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // Added because of LiquidFloatingActionButton library (library is not directly included - only some modified parts copied)
    // src: https://github.com/yoavlt/LiquidFloatingActionButton/blob/master/Pod/Classes/CGPointEx.swift
    /////////////////////////////////////////////////////////////////////////////////////
    
    var rightBottom: CGPoint {
        get {
            return CGPoint(x: origin.x + width, y: origin.y + height)
        }
    }
    var center: CGPoint {
        get {
            return origin.plus(rightBottom).mul(0.5)
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
}