//
//  Fonts.swift
//  :
//
//  Created by ischuetz on 02/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

enum FontType {
    case Light, Regular, Bold
}

enum FontSize {
    case SuperSmall, VerySmall, Smaller, Small, Regular, Large
}

class Fonts {

    static func fontForSizeCategory(fontType: Int) -> UIFont {
        if let fontSize = LabelMore.mapToFontSize(fontType) { // TODO move this out of LabelMore
            return UIFont.systemFontOfSize(fontSize)
        } else {
            QL3("No fond size for size category: \(fontType)")
            return UIFont.systemFontOfSize(15) // return something
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

    static var large: UIFont = {UIFont(name: fontName, size: largeSize) ?? UIFont.systemFontOfSize(largeSize)}()
    static var regular: UIFont = {UIFont(name: fontName, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var small: UIFont = {UIFont(name: fontName, size: smallSize) ?? UIFont.systemFontOfSize(smallSize)}()
    static var smaller: UIFont = {UIFont(name: fontName, size: smallerSize) ?? UIFont.systemFontOfSize(smallerSize)}()
    static var verySmall: UIFont = {UIFont(name: fontName, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmall: UIFont = {UIFont(name: fontName, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()
    
    static var largeLight: UIFont = {UIFont(name: fontNameLight, size: largeSize) ?? UIFont.systemFontOfSize(largeSize)}()
    static var regularLight: UIFont = {UIFont(name: fontNameLight, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var smallLight: UIFont = {UIFont(name: fontNameLight, size: smallSize) ?? UIFont.systemFontOfSize(smallSize)}()
    static var smallerLight: UIFont = {UIFont(name: fontNameLight, size: smallerSize) ?? UIFont.systemFontOfSize(smallerSize)}()
    static var verySmallLight: UIFont = {UIFont(name: fontNameLight, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmallLight: UIFont = {UIFont(name: fontNameLight, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()
    
    static var largeBold: UIFont = {UIFont(name: fontNameBold, size: largeSize) ?? UIFont.systemFontOfSize(largeSize)}()
    static var regularBold: UIFont = {UIFont(name: fontNameBold, size: regularSize) ?? UIFont.systemFontOfSize(regularSize)}()
    static var smallBold: UIFont = {UIFont(name: fontNameBold, size: smallSize) ?? UIFont.systemFontOfSize(smallSize)}()
    static var smallerBold: UIFont = {UIFont(name: fontNameBold, size: smallerSize) ?? UIFont.systemFontOfSize(smallerSize)}()
    static var verySmallBold: UIFont = {UIFont(name: fontNameBold, size: verySmallSize) ?? UIFont.systemFontOfSize(verySmallSize)}()
    static var superSmallBold: UIFont = {UIFont(name: fontNameBold, size: superSmallSize) ?? UIFont.systemFontOfSize(superSmallSize)}()

    static func fontSize(heightDimension: HeightDimension, size: FontSize) -> CGFloat {
        switch heightDimension {
        case .VerySmall: // iPhone 4
            switch size {
            case .SuperSmall: return 11
            case .VerySmall: return 13
            case .Smaller: return 14
            case .Small: return 15
            case .Regular: return 17
            case .Large: return 19
            }

        case .Small: // iPhone 5
            switch size {
            case .SuperSmall: return 10
            case .VerySmall: return 11
            case .Smaller: return 12
            case .Small: return 13
            case .Regular: return 15
            case .Large: return 17
            }
        case .Middle: // iPhone 6
            switch size {
            case .SuperSmall: return 11
            case .VerySmall: return 13
            case .Smaller: return 14
            case .Small: return 15
            case .Regular: return 17
            case .Large: return 19
            }
        case .Large: // iPhone 6+
            switch size {
            case .SuperSmall: return 11
            case .VerySmall: return 13
            case .Smaller: return 14
            case .Small: return 15
            case .Regular: return 17
            case .Large: return 19
            }
        }
    }
    
    private static func fontName(type: FontType) -> String {
        switch type {
        case .Light: return fontNameLight
        case .Regular: return fontName
        case .Bold: return fontNameBold
        }
    }
    
    static func font(heightDimension: HeightDimension, size: FontSize, type: FontType) -> UIFont {
        
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
        return UIFont(name: fontName(type), size: size) ?? UIFont.systemFontOfSize(size)
    }
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
}
