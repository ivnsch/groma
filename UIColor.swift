//
//  UIColor.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension UIColor {

    static func randomColor() -> UIColor {
        // src http://classictutorials.com/2014/08/generate-a-random-color-in-swift/
        let red: CGFloat = CGFloat(drand48())
        let green: CGFloat = CGFloat(drand48())
        let blue: CGFloat = CGFloat(drand48())
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}