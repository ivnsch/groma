//
//  Fonts.swift
//  :
//
//  Created by ischuetz on 02/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

enum FontType {
    case light, regular, bold
}

enum FontSize {
    case superSmall, verySmall, smaller, small, regular, large
}

class Fonts {

    static func fontForSizeCategory(_ fontType: Int) -> UIFont {
        if let fontSize = LabelMore.mapToFontSize(fontType) { // TODO move this out of LabelMore
            return UIFont.systemFont(ofSize: fontSize)
        } else {
            QL3("No fond size for size category: \(fontType)")
            return UIFont.systemFont(ofSize: 15) // return something
        }
    }
    
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // deprecated! from now on only size categories
    static let fontName: String = "HelveticaNeue"
    static let fontNameLight: String = "\(fontName)-Light"
    static let fontNameBold: String = "\(fontName)-Bold"
    
    static let largeSize: CGFloat = 20
    static let regularSize: CGFloat = 18
    static let smallSize: CGFloat = 15
    static let smallerSize: CGFloat = 14 // textfield default
    static let verySmallSize: CGFloat = 13
    static let superSmallSize: CGFloat = 11

    static var large: UIFont = {UIFont(name: fontName, size: largeSize) ?? UIFont.systemFont(ofSize: largeSize)}()
    static var regular: UIFont = {UIFont(name: fontName, size: regularSize) ?? UIFont.systemFont(ofSize: regularSize)}()
    static var small: UIFont = {UIFont(name: fontName, size: smallSize) ?? UIFont.systemFont(ofSize: smallSize)}()
    static var smaller: UIFont = {UIFont(name: fontName, size: smallerSize) ?? UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmall: UIFont = {UIFont(name: fontName, size: verySmallSize) ?? UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmall: UIFont = {UIFont(name: fontName, size: superSmallSize) ?? UIFont.systemFont(ofSize: superSmallSize)}()
    
    static var largeLight: UIFont = {UIFont(name: fontNameLight, size: largeSize) ?? UIFont.systemFont(ofSize: largeSize)}()
    static var regularLight: UIFont = {UIFont(name: fontNameLight, size: regularSize) ?? UIFont.systemFont(ofSize: regularSize)}()
    static var smallLight: UIFont = {UIFont(name: fontNameLight, size: smallSize) ?? UIFont.systemFont(ofSize: smallSize)}()
    static var smallerLight: UIFont = {UIFont(name: fontNameLight, size: smallerSize) ?? UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmallLight: UIFont = {UIFont(name: fontNameLight, size: verySmallSize) ?? UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmallLight: UIFont = {UIFont(name: fontNameLight, size: superSmallSize) ?? UIFont.systemFont(ofSize: superSmallSize)}()
    
    static var largeBold: UIFont = {UIFont(name: fontNameBold, size: largeSize) ?? UIFont.systemFont(ofSize: largeSize)}()
    static var regularBold: UIFont = {UIFont(name: fontNameBold, size: regularSize) ?? UIFont.systemFont(ofSize: regularSize)}()
    static var smallBold: UIFont = {UIFont(name: fontNameBold, size: smallSize) ?? UIFont.systemFont(ofSize: smallSize)}()
    static var smallerBold: UIFont = {UIFont(name: fontNameBold, size: smallerSize) ?? UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmallBold: UIFont = {UIFont(name: fontNameBold, size: verySmallSize) ?? UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmallBold: UIFont = {UIFont(name: fontNameBold, size: superSmallSize) ?? UIFont.systemFont(ofSize: superSmallSize)}()

    static func fontSize(_ heightDimension: HeightDimension, size: FontSize) -> CGFloat {
        switch heightDimension {
        case .verySmall: // iPhone 4
            switch size {
            case .superSmall: return 11
            case .verySmall: return 13
            case .smaller: return 14
            case .small: return 15
            case .regular: return 17
            case .large: return 19
            }

        case .small: // iPhone 5
            switch size {
            case .superSmall: return 10
            case .verySmall: return 11
            case .smaller: return 12
            case .small: return 13
            case .regular: return 15
            case .large: return 17
            }
        case .middle: // iPhone 6
            switch size {
            case .superSmall: return 11
            case .verySmall: return 13
            case .smaller: return 14
            case .small: return 15
            case .regular: return 17
            case .large: return 19
            }
        case .large: // iPhone 6+
            switch size {
            case .superSmall: return 11
            case .verySmall: return 13
            case .smaller: return 14
            case .small: return 15
            case .regular: return 17
            case .large: return 19
            }
        }
    }
    
    fileprivate static func fontName(_ type: FontType) -> String {
        switch type {
        case .light: return fontNameLight
        case .regular: return fontName
        case .bold: return fontNameBold
        }
    }
    
    static func font(_ heightDimension: HeightDimension, size: FontSize, type: FontType) -> UIFont {
        
        // TODO optimisation: lazy variables for fonts?
        // would need to have a static variable for each variant, like this:
//        //     static var largeRegularFont: UIFont?
//        func f() -> UIFont {
//            let size = fontSize(heightDimension, size: size)
//            return UIFont(name: fontName(type), size: size) ?? UIFont.systemFontOfSize(size)
//        }
        // then each time we get the font, check if static var is set if not initialise it. This looks a bit ugly though, better way?
//        switch (size, type) {
//        // ...
//        default: return largeRegularFont ?? {
//            let font = f()
//            self.largeRegularFont = f()
//            return font
//        }()
//        }
        
        let size = fontSize(heightDimension, size: size)
        return UIFont(name: fontName(type), size: size) ?? UIFont.systemFont(ofSize: size)
    }
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
}
