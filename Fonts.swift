//
//  Fonts.swift
//  :
//
//  Created by ischuetz on 02/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
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
            logger.w("No fond size for size category: \(fontType)")
            return UIFont.systemFont(ofSize: 15) // return something
        }
    }
    
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    // deprecated! from now on only size categories
//    static let fontName: String = "HelveticaNeue"
//    static let fontNameLight: String = "\(fontName)-Light"
//    static let fontNameBold: String = "\(fontName)-Bold"

    static let largeSize: CGFloat = 20
    static let regularSize: CGFloat = 18
    static let smallSize: CGFloat = 15
    static let smallerSize: CGFloat = 14 // textfield default
    static let verySmallSize: CGFloat = 13
    static let superSmallSize: CGFloat = 11

    static var large: UIFont = {UIFont.systemFont(ofSize: largeSize)}()
    static var regular: UIFont = {UIFont.systemFont(ofSize: regularSize)}()
    static var small: UIFont = {UIFont.systemFont(ofSize: smallSize)}()
    static var smaller: UIFont = {UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmall: UIFont = {UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmall: UIFont = {UIFont.systemFont(ofSize: superSmallSize)}()
    
    static var largeLight: UIFont = {UIFont.systemFont(ofSize: largeSize)}()
    static var regularLight: UIFont = {UIFont.systemFont(ofSize: regularSize)}()
    static var smallLight: UIFont = {UIFont.systemFont(ofSize: smallSize)}()
    static var smallerLight: UIFont = {UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmallLight: UIFont = {UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmallLight: UIFont = {UIFont.systemFont(ofSize: superSmallSize)}()
    
    static var largeBold: UIFont = {UIFont.systemFont(ofSize: largeSize)}()
    static var regularBold: UIFont = {UIFont.systemFont(ofSize: regularSize)}()
    static var smallBold: UIFont = {UIFont.systemFont(ofSize: smallSize)}()
    static var smallerBold: UIFont = {UIFont.systemFont(ofSize: smallerSize)}()
    static var verySmallBold: UIFont = {UIFont.systemFont(ofSize: verySmallSize)}()
    static var superSmallBold: UIFont = {UIFont.systemFont(ofSize: superSmallSize)}()

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
        case .large, .xLarge, .xxLarge: // iPhone 6+, iPhone X, iPhone XR, iPhone XS, iPhone XS max
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
    
//    fileprivate static func fontName(_ type: FontType) -> String {
//        switch type {
//        case .light: return fontNameLight
//        case .regular: return fontName
//        case .bold: return fontNameBold
//        }
//    }
//
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
        return UIFont.systemFont(ofSize: size)
    }
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
}
