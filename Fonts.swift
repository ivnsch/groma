//
//  Fonts.swift
//  shoppin
//
//  Created by ischuetz on 02/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class Fonts {

    static let fontName: String = "HelveticaNeue"
    static let fontNameLight: String = "\(fontName)-Light"
    static let fontNameBold: String = "\(fontName)-Bold"
    
    static let largeSize: CGFloat = 19
    static let regularSize: CGFloat = 17
    static let smallSize: CGFloat = 15
    static let smallerSize: CGFloat = 14 // textfield default
    static let verySmallSize: CGFloat = 13
    static let superSmallSize: CGFloat = 11
    
    static var regular: UIFont = {UIFont(name: fontName, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var small: UIFont = {UIFont(name: fontName, size: smallSize) ?? UIFont.systemFontOfSize(smallSize)}()
    static var verySmall: UIFont = {UIFont(name: fontName, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmall: UIFont = {UIFont(name: fontName, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()
    
    static var regularLight: UIFont = {UIFont(name: fontNameLight, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var smallLight: UIFont = {UIFont(name: fontNameLight, size: smallSize) ?? UIFont.systemFontOfSize(smallSize)}()
    static var smallerLight: UIFont = {UIFont(name: fontNameLight, size: smallerSize) ?? UIFont.systemFontOfSize(smallerSize)}()
    static var verySmallLight: UIFont = {UIFont(name: fontNameLight, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmallLight: UIFont = {UIFont(name: fontNameLight, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()
    
    static var largeBold: UIFont = {UIFont(name: fontNameBold, size: largeSize) ?? UIFont.systemFontOfSize(largeSize)}()
    static var regularBold: UIFont = {UIFont(name: fontNameBold, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var smallerBold: UIFont = {UIFont(name: fontNameBold, size: smallerSize) ?? UIFont.systemFontOfSize(smallerSize)}()
    static var verySmallBold: UIFont = {UIFont(name: fontNameBold, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmallBold: UIFont = {UIFont(name: fontNameBold, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()
}
