//
//  DimensionsManager.swift
//  shoppin
//
//  Created by ischuetz on 31/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

/**
* Current available iPhone sizes (pt)
* 4/S: 320x480
* 5/C/S/SE: 320x568
* 6/S: 375x667
* 6+/S: 414x736
*
* We will not use fixed dimensions but continuous ranges, just in case. The ranges match 1:1 with the current available iPhones (a range contains max. 1 iPhone and every iPhone has a range). We use biger or equal than the size of each iPhone such that if there happens to be some unexpected screen size in the middle, it uses the next lowest size - which is less worse  than using the biggest size, as the latest can lead to layout overflowing the screen. Note: Also, substracting 1pt from max in comparisons below (e.g. using w >= 413 instead of w >= 414), for possible innacuracy (don't know if this is necessary but it doesn't hurt to do it).
*/

enum WidthDimension {
    case Small // iPhone 5 / SE
    case Middle // iPhone 6
    case Large // iPhone 6+
}

enum HeightDimension {
    case VerySmall // iPhone 4
    case Small // iPhone 5 / SE
    case Middle // iPhone 6
    case Large // iPhone 6+
}

class DimensionsManager {

    static var screenSize: CGSize {
        let bounds = UIScreen.mainScreen().bounds
        return CGSizeMake(bounds.width, bounds.height)
    }
    
    static var widthDimension: WidthDimension {
        let dimension: WidthDimension = {
            switch screenSize.width {
            case let w where w >= 413: return .Large // iPhone 6+
            case let w where w >= 374: return .Middle // iPhone 6
            default: return .Large // iPhone 4,5
            }
        }()
        QL2("Screen width: \(screenSize.width), widthDimension: \(dimension)")
        return dimension
    }
    
    static var heightDimension: HeightDimension {
        let dimension: HeightDimension = {
            switch screenSize.height {
            case let h where h >= 735: return .Large // iPhone 6+
            case let h where h >= 666: return .Middle // iPhone 6
            case let h where h >= 567: return .Small // iPhone 5
            default: return .VerySmall // iPhone 4
            }
        }()
        QL2("Screen height: \(screenSize.height), heightDimension: \(dimension)")
        return dimension
    }

    // MARK: Fonts
    
    static func font(fontSize: FontSize, fontType: FontType) -> UIFont {
        return Fonts.font(heightDimension, size: fontSize, type: fontType)
    }
    
    // MARK: Quick add
    
    static var quickAddHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 200
        case .Small: return 220
        case .Middle: return 290
        case .Large: return 310
        }
    }
}
