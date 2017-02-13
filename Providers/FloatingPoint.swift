//
//  FloatingPoint.swift
//  Providers
//
//  Created by Ivan Schuetz on 10/02/2017.
//
//

import Foundation

public extension FloatingPoint {
    
    var degreesToRadians: Self {
        return self * .pi / 180
    }
    
    var radiansToDegrees: Self {
        return self * 180 / .pi
    }
}
