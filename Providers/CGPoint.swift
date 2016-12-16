//
//  CGPoint.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension CGPoint {

    /////////////////////////////////////////////////////////////////////////////////////
    // Added because of LiquidFloatingActionButton library (library is not directly included - only some modified parts copied)
    // src: https://github.com/yoavlt/LiquidFloatingActionButton/blob/master/Pod/Classes/CGPointEx.swift
    /////////////////////////////////////////////////////////////////////////////////////
    
    public func plus(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
    
    public func minus(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x - point.x, y: self.y - point.y)
    }
    
    public func minusX(_ dx: CGFloat) -> CGPoint {
        return CGPoint(x: self.x - dx, y: self.y)
    }
    
    public func minusY(_ dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: self.y - dy)
    }
    
    public func mul(_ rhs: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * rhs, y: self.y * rhs)
    }
    
    public func div(_ rhs: CGFloat) -> CGPoint {
        return CGPoint(x: self.x / rhs, y: self.y / rhs)
    }
    
    public func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    public func normalized() -> CGPoint {
        return self.div(self.length())
    }
    
    public func dot(_ point: CGPoint) -> CGFloat {
        return self.x * point.x + self.y * point.y
    }
    
    public func cross(_ point: CGPoint) -> CGFloat {
        return self.x * point.y - self.y * point.x
    }
    
    public func split(_ point: CGPoint, ratio: CGFloat) -> CGPoint {
        return self.mul(ratio).plus(point.mul(1.0 - ratio))
    }
    
    public func mid(_ point: CGPoint) -> CGPoint {
        return split(point, ratio: 0.5)
    }
    
    public static func intersection(_ from: CGPoint, to: CGPoint, from2: CGPoint, to2: CGPoint) -> CGPoint? {
        let ac = CGPoint(x: to.x - from.x, y: to.y - from.y)
        let bd = CGPoint(x: to2.x - from2.x, y: to2.y - from2.y)
        let ab = CGPoint(x: from2.x - from.x, y: from2.y - from.y)
        let bc = CGPoint(x: to.x - from2.x, y: to.y - from2.y)
        
        let area = bd.cross(ab)
        let area2 = bd.cross(bc)
        
        if abs(area + area2) >= 0.1 {
            let ratio = area / (area + area2)
            return CGPoint(x: from.x + ratio * ac.x, y: from.y + ratio * ac.y)
        }
        
        return nil
    }
    /////////////////////////////////////////////////////////////////////////////////////

    public func copy(x: CGFloat? = nil, y: CGFloat? = nil) -> CGPoint {
        return CGPoint(x: x ?? self.x, y: y ?? self.y)
    }
    
    public func plusX(_ dx: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y)
    }
}
