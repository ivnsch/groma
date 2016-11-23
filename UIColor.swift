//
//  UIColor.swift
//  shoppin
//
//  Created by ischuetz on 25/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

extension UIColor {

    static func randomColor() -> UIColor {
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
    var red: CGFloat {
        get {
            let components = self.cgColor.components
            return components![0]
        }
    }
    
    var green: CGFloat {
        get {
            let components = self.cgColor.components
            return components![1]
        }
    }
    
    var blue: CGFloat {
        get {
            let components = self.cgColor.components
            return components![2]
        }
    }
    
    var alpha: CGFloat {
        get {
            return self.cgColor.alpha
        }
    }
    
    func alpha(_ alpha: CGFloat) -> UIColor {
        return UIColor(red: self.red, green: self.green, blue: self.blue, alpha: alpha)
    }
    
    func white(_ scale: CGFloat) -> UIColor {
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
    
    static func opaqueColorByApplyingTransparentColorOrBackground(_ transparentColor: UIColor, backgroundColor: UIColor) -> UIColor {
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
    
    // src: https://gist.github.com/yannickl/16f0ed38f0698d9a8ae7
    convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as String
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    var hexStr: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"%06x", rgb) as String
    }
}
