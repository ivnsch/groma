//
//  Int.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension Int {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
    
    var isEven: Bool {
        return self % 2 == 0
    }
    
    // MARK: - Random (src http://stackoverflow.com/a/28075467/930450)
    
    /// Returns a random Int point number between 0 and Int.max.
    public static var random:Int {
        get {
            return Int.random(Int.max)
        }
    }
    /**
    Random integer between 0 and n-1.
    
    - parameter n: Int
    
    - returns: Int
    */
    public static func random(_ n: Int) -> Int {
        return Int(arc4random_uniform(UInt32(n)))
    }
    /**
    Random integer between min and max
    
    - parameter min: Int
    - parameter max: Int
    
    - returns: Int
    */
    public static func random(_ min: Int, max: Int) -> Int {
        return Int.random(max - min + 1) + min
    }
}
