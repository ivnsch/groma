//
//  UIColor.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

public extension UIColor {
    
    public static func randomColor() -> UIColor {
        // src http://classictutorials.com/2014/08/generate-a-random-color-in-swift/
        let red: CGFloat = CGFloat(drand48())
        let green: CGFloat = CGFloat(drand48())
        let blue: CGFloat = CGFloat(drand48())
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    // Added because of LiquidFloatingActionButton library (library is not directly included - only some modified parts copied)
    // src: https://github.com/yoavlt/LiquidFloatingActionButton/blob/master/Pod/Classes/UIColorEx.swift
    /////////////////////////////////////////////////////////////////////////////////////
    public var red: CGFloat {
        get {
            let components = self.cgColor.components
            return components![0]
        }
    }
    
    public var green: CGFloat {
        get {
            let components = self.cgColor.components
            return components![1]
        }
    }
    
    public var blue: CGFloat {
        get {
            let components = self.cgColor.components
            return components![2]
        }
    }
    
    public var alpha: CGFloat {
        get {
            return self.cgColor.alpha
        }
    }
    
    public func alpha(_ alpha: CGFloat) -> UIColor {
        return UIColor(red: self.red, green: self.green, blue: self.blue, alpha: alpha)
    }
    
    public func white(_ scale: CGFloat) -> UIColor {
        return UIColor(
            red: self.red + (1.0 - self.red) * scale,
            green: self.green + (1.0 - self.green) * scale,
            blue: self.blue + (1.0 - self.blue) * scale,
            alpha: 1.0
        )
    }
    
    // TODO port to swift and use for buttons pressed state
    // src http://stackoverflow.com/a/10670141/930450
    //    -(UIColor*) darkerShade {
    //
    //    float red, green, blue, alpha;
    //    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    //
    //    double multiplier = 0.8f;
    //    return [UIColor colorWithRed:red * multiplier green:green * multiplier blue:blue*multiplier alpha:alpha];
    //    }
    
    /////////////////////////////////////////////////////////////////////////////////////
    
    public static func opaqueColorByApplyingTransparentColorOrBackground(_ transparentColor: UIColor, backgroundColor: UIColor) -> UIColor {
        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        bgView.backgroundColor = backgroundColor
        let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        overlayView.backgroundColor = transparentColor
        bgView.addSubview(overlayView)
        
        let image = UIView.imageWithView(bgView)
        
        if let provider = image.cgImage?.dataProvider {
            let pixelData = provider.data
            if let data = CFDataGetBytePtr(pixelData) {
                return UIColor(
                    red: CGFloat(data[0]) / 255.0,
                    green: CGFloat(data[1]) / 255.0,
                    blue: CGFloat(data[2]) / 255.0,
                    alpha: 1
                )
            } else {
                QL4("Couldn't get image data, returning black")
                return UIColor.black
            }
            
        } else {
            QL4("Couldn't get cgImage, returning black")
            return UIColor.black
        }
    }
}
