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
    case Small // iPhone 4 / 5 / SE
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
            default: return .Small // iPhone 4,5
            }
        }()
//        QL2("Screen width: \(screenSize.width), widthDimension: \(dimension)")
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
//        QL2("Screen height: \(screenSize.height), heightDimension: \(dimension)")
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

    static var quickAddManageProductsHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 150
        case .Small: return 150
        case .Middle: return 180
        case .Large: return 200
        }
    }
    
    static var quickAddSlidingTabsViewHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 35
        case .Small: return 35
        case .Middle: return 50
        case .Large: return 50
        }
    }
    
    static var quickAddSlidingLineBottomOffset: CGFloat {
        switch heightDimension {
        case .VerySmall: return 5
        case .Small: return 5
        case .Middle: return 10
        case .Large: return 10
        }
    }
    
    static var quickAddCollectionViewSpacing: CGFloat {
        switch heightDimension {
        case .VerySmall: return 10
        case .Small: return 10
        case .Middle: return 20
        case .Large: return 20
        }
    }

    static var quickAddCollectionViewCellHPadding: CGFloat {
        switch heightDimension {
        case .VerySmall: return 10
        case .Small: return 10
        case .Middle: return 20
        case .Large: return 20
        }
    }

    static var quickAddCollectionViewCellVPadding: CGFloat {
        switch heightDimension {
        case .VerySmall: return 3
        case .Small: return 3
        case .Middle: return 6
        case .Large: return 6
        }
    }

    static var quickAddCollectionViewCellCornerRadius: CGFloat {
        switch heightDimension {
        case .VerySmall: return 15
        case .Small: return 15
        case .Middle: return 18
        case .Large: return 18
        }
    }

    // MARK: list items
    
    static var listItemsHeaderHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 28
        case .Small: return 30
        case .Middle: return 43
        case .Large: return 43
        }
    }

    // Note: used also for stats details - we now use this for all bottom info views to keep ui consistent
    static var listItemsPricesViewHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 54
        case .Small: return 54
        case .Middle: return 60
        case .Large: return 70
        }
    }
    
    // MARK: Common
    
    static var defaultCellHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 65
        case .Small: return 67
        case .Middle: return 82
        case .Large: return 91
        }
    }
    
    static var searchBarHeight: CGFloat {
        switch heightDimension {
        case .VerySmall: return 30
        case .Small: return 30
        case .Middle: return 30
        case .Large: return 35
        }
    }
    
    static var leftRightPaddingConstraint: CGFloat {
        switch widthDimension {
        case .Small: return 20
        case .Middle: return 25
        case .Large: return 30
        }
    }

    static var emptyViewTopConstraint: CGFloat {
        switch heightDimension {
        case .VerySmall: return 140
        case .Small: return 140
        case .Middle: return 160
        case .Large: return 160
        }
    }
    
    // The full width of the screen. Hack - we should not need to use hardcoded values for this. We need it now for bottom border of cells, bounds not calculated yet. TODO fix that and remove this.
    static var fullWidth: CGFloat {
        switch widthDimension {
        case .Small: return 320
        case .Middle: return 375
        case .Large: return 414
        }
    }
    
    static var topMenuBarHeight: CGFloat {
        return 40
    }
    
    // MARK: User details
    
    // Rename - default button radius?
    static var userDetailsLogoutButtonRadius: CGFloat {
        switch heightDimension {
        case .VerySmall: return 18
        case .Small: return 18
        case .Middle: return 25
        case .Large: return 25
        }
    }
    
    // MARK: Login
    
    static var topConstraintFirstInputWhenClose: CGFloat {
        switch heightDimension {
        case .VerySmall: return 50
        case .Small: return 60
        case .Middle: return 60
        case .Large: return 60
        }
    }
    
    static var topConstraintFirstInputWhenOpen: CGFloat {
        switch heightDimension {
        case .VerySmall: return 60
        case .Small: return 60
        case .Middle: return 60
        case .Large: return 60
        }
    }
}
