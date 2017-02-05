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
    case small // iPhone 4 / 5 / SE
    case middle // iPhone 6
    case large // iPhone 6+
}

enum HeightDimension {
    case verySmall // iPhone 4
    case small // iPhone 5 / SE
    case middle // iPhone 6
    case large // iPhone 6+
}

class DimensionsManager {

    static var screenSize: CGSize {
        let bounds = UIScreen.main.bounds
        return CGSize(width: bounds.width, height: bounds.height)
    }
    
    static var widthDimension: WidthDimension {
        let dimension: WidthDimension = {
            switch screenSize.width {
            case let w where w >= 413: return .large // iPhone 6+
            case let w where w >= 374: return .middle // iPhone 6
            default: return .small // iPhone 4,5
            }
        }()
//        QL2("Screen width: \(screenSize.width), widthDimension: \(dimension)")
        return dimension
    }
    
    static var heightDimension: HeightDimension {
        let dimension: HeightDimension = {
            switch screenSize.height {
            case let h where h >= 735: return .large // iPhone 6+
            case let h where h >= 666: return .middle // iPhone 6
            case let h where h >= 567: return .small // iPhone 5
            default: return .verySmall // iPhone 4
            }
        }()
//        QL2("Screen height: \(screenSize.height), heightDimension: \(dimension)")
        return dimension
    }

    // MARK: Fonts
    
    static func font(_ fontSize: FontSize, fontType: FontType) -> UIFont {
        return Fonts.font(heightDimension, size: fontSize, type: fontType)
    }
    
    // MARK: Quick add
    
    static var quickAddHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 150
        case .small: return 210
        case .middle: return 285
        case .large: return 310
        }
    }

    static var quickAddManageProductsHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 150
        case .small: return 150
        case .middle: return 180
        case .large: return 200
        }
    }
    
    static var quickAddSlidingTabsViewHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 35
        case .middle: return 50
        case .large: return 50
        }
    }
    
    static var quickAddSlidingLineBottomOffset: CGFloat {
        switch heightDimension {
        case .verySmall: return 0
        case .small: return 5
        case .middle: return 10
        case .large: return 10
        }
    }

    static var quickAddSlidingLeftRightPadding: CGFloat {
        switch widthDimension {
        case .small: return 120
        case .middle: return 140
        case .large: return 180
        }
    }
    
    static var quickAddCollectionViewSpacing: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 10
        case .middle: return 20
        case .large: return 20
        }
    }

    static var quickAddCollectionViewCellHPadding: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 10
        case .middle: return 20
        case .large: return 20
        }
    }

    static var quickAddCollectionViewCellVPadding: CGFloat {
        switch heightDimension {
        case .verySmall: return 0
        case .small: return 3
        case .middle: return 6
        case .large: return 6
        }
    }

    static var quickAddCollectionViewCellCornerRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 16
        case .small: return 16
        case .middle: return 18
        case .large: return 18
        }
    }

    // MARK: list items
    
    static var listItemsHeaderHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 26
        case .small: return 26
        case .middle: return 28
        case .large: return 28
        }
    }

    // Note: used also for stats details - we now use this for all bottom info views to keep ui consistent
    static var listItemsPricesViewHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 54
        case .small: return 54
        case .middle: return 60
        case .large: return 70
        }
    }
    
    // MARK: Common
    
    static var defaultCellHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 65
        case .small: return 67
        case .middle: return 82
        case .large: return 91
        }
    }
    
    static var cartStashCellHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 45
        case .small: return 45
        case .middle: return 52
        case .large: return 66
        }
    }
    
    static var searchBarHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 30
        case .middle: return 30
        case .large: return 35
        }
    }
    
    static var leftRightPaddingConstraint: CGFloat {
        switch widthDimension {
        case .small: return 15
        case .middle: return 20
        case .large: return 25
        }
    }

    static var leftRightBigPaddingConstraint: CGFloat {
        switch widthDimension {
        case .small: return 30
        case .middle: return 45
        case .large: return 55
        }
    }
    
    static var emptyViewTopConstraint: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 70
        case .middle: return 160
        case .large: return 160
        }
    }

    static var textFieldHeightConstraint: CGFloat {
        switch heightDimension {
        case .verySmall: return 20
        case .small: return 35
        case .middle: return 40
        case .large: return 40
        }
    }
    
    // The full width of the screen. Hack - we should not need to use hardcoded values for this. We need it now for bottom border of cells, bounds not calculated yet. TODO fix that and remove this.
    static var fullWidth: CGFloat {
        switch widthDimension {
        case .small: return 320
        case .middle: return 375
        case .large: return 414
        }
    }
    
    static var topMenuBarHeight: CGFloat {
        return 40
    }
    
    // MARK: User details
    
    // Rename - default button radius?
    static var userDetailsLogoutButtonRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 18
        case .small: return 18
        case .middle: return 25
        case .large: return 25
        }
    }
    
    // MARK: Login
    
    static var topConstraintFirstInputWhenClose: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 30
        case .middle: return 60
        case .large: return 80
        }
    }
    
    static var topConstraintFirstInputWhenOpen: CGFloat {
        switch heightDimension {
        case .verySmall: return 60
        case .small: return 60
        case .middle: return 60
        case .large: return 60
        }
    }
    
    // MARK: Report
    
    static var pieChartRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 70
        case .small: return 80
        case .middle: return 85
        case .large: return 85
        }
    }

    static var pieChartLabelRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 55
        case .small: return 65
        case .middle: return 70
        case .large: return 70
        }
    }
    
    // MARK: Color picker
    
    static var colorCircleCellSize: CGFloat {
        switch widthDimension {
        case .small: return 45
        case .middle: return 60
        case .large: return 70
        }
    }
    
    static var colorCircleSize: CGFloat {
        switch widthDimension {
        case .small: return 40
        case .middle: return 50
        case .large: return 50
        }
    }
}
