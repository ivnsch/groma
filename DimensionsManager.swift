//
//  DimensionsManager.swift
//  shoppin
//
//  Created by ischuetz on 31/03/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit


/**
* Current available iPhone sizes (pt)
* 4/S: 320x480
* 5/C/S/SE: 320x568
* 6/S: 375x667
* 6+/S: 414x736
* X: 375x812
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
    case xLarge // iPhone X
    case xxLarge // iPhone XS max
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
//        logger.d("Screen width: \(screenSize.width), widthDimension: \(dimension)")
        return dimension
    }
    
    static var heightDimension: HeightDimension {
        let dimension: HeightDimension = {
            switch screenSize.height {
            case let h where h >= 896: return .xxLarge // iPhone XS max
            case let h where h >= 812: return .xLarge // iPhone X, XS
            case let h where h >= 735: return .large // iPhone 6+
            case let h where h >= 666: return .middle // iPhone 6
            case let h where h >= 567: return .small // iPhone 5
            default: return .verySmall // iPhone 4
            }
        }()
//        logger.d("Screen height: \(screenSize.height), heightDimension: \(dimension)")
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
        case .small: return 220
        case .middle: return 285
        case .large, .xLarge, .xxLarge: return 310
        }
    }
    
    static var quickEditItemHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 160
        case .small: return 160
        case .middle: return 160
        case .large, .xLarge, .xxLarge: return 160
        }
    }

    static var quickAddManageProductsHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 150
        case .small: return 150
        case .middle: return 180
        case .large, .xLarge, .xxLarge: return 200
        }
    }
    
    static var quickAddSlidingTabsViewHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 35
        case .middle: return 50
        case .large, .xLarge, .xxLarge: return 50
        }
    }
    
    static var quickAddSlidingLineBottomOffset: CGFloat {
        switch heightDimension {
        case .verySmall: return 0
        case .small: return 5
        case .middle: return 10
        case .large, .xLarge, .xxLarge: return 10
        }
    }

    static var quickAddSlidingLeftRightPadding: CGFloat {
        switch widthDimension {
        case .small: return 90
        case .middle: return 110
        case .large: return 130
        }
    }
    
    static var quickAddCollectionViewSpacing: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 10
        case .middle: return 20
        case .large, .xLarge, .xxLarge: return 20
        }
    }

    static var quickAddCollectionViewCellHPadding: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 10
        case .middle: return 20
        case .large, .xLarge, .xxLarge: return 20
        }
    }

    static var quickAddCollectionViewCellVPadding: CGFloat {
        switch heightDimension {
        case .verySmall: return 0
        case .small: return 3
        case .middle: return 6
        case .large, .xLarge, .xxLarge: return 6
        }
    }
    
    // TODO use in all places where needed
    static var quickAddCollectionViewItemsFixedHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 35
        case .middle: return 35
        case .large, .xLarge, .xxLarge: return 40
        }
    }
    
    static var quickAddCollectionViewCellCornerRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 16
        case .small: return 16
        case .middle: return 18
        case .large, .xLarge, .xxLarge: return 18
        }
    }
    
    static var unitInUnitBaseViewSize: CGFloat {
        switch heightDimension {
        case .verySmall: return 25
        case .small: return 25
        case .middle: return 30
        case .large, .xLarge, .xxLarge: return 30
        }
    }

    static var unitBaseViewTopBottomPadding: CGFloat {
        switch heightDimension {
        case .verySmall: return 0
        case .small: return 0
        case .middle: return 10
        case .large, .xLarge, .xxLarge: return 10
        }
    }

    static var unitBaseViewHeightConstraint: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 30
        case .middle: return 35
        case .large, .xLarge, .xxLarge: return 35
        }
    }

    // MARK: list items
    
    static var listItemsHeaderHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 25
        case .small: return 25
        case .middle: return 30
        case .large, .xLarge, .xxLarge: return 30
        }
    }

    // Note: used also for stats details - we now use this for all bottom info views to keep ui consistent
    static var listItemsPricesViewHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 64
        case .small: return 64
        case .middle: return 70
        case .large, .xLarge, .xxLarge: return 70
        }
    }
    
    // MARK: Common
    
    static var defaultCellHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 70
        case .small: return 70
        case .middle: return 82
        case .large, .xLarge, .xxLarge: return 91
        }
    }
    
    static var ingredientsCellHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 40
        case .small: return 40
        case .middle: return 50
        case .large, .xLarge, .xxLarge: return 50
        }
    }
    
    static var ingredientsUnitCellHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 40
        case .small: return 40
        case .middle: return 40
        case .large, .xLarge, .xxLarge: return 40
        }
    }
    
    static var searchBarHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 30
        case .small: return 30
        case .middle: return 30
        case .large, .xLarge, .xxLarge: return 35
        }
    }
    
    static var leftRightPaddingConstraint: CGFloat {
        switch widthDimension {
        case .small: return 20
        case .middle: return 25
        case .large: return 30
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
        case .verySmall: return 100
        case .small: return 100
        case .middle: return 150
        case .large: return 150
        case .xLarge, .xxLarge: return 180
        }
    }

    static var textFieldHeightConstraint: CGFloat {
        switch heightDimension {
        case .verySmall: return 20
        case .small: return 35
        case .middle: return 40
        case .large, .xLarge, .xxLarge: return 40
        }
    }
    
    static var contractedSectionHeight: CGFloat {
        return 4
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

    // For now this is used only in authentication related controllers
    static var submitButtonHeight: CGFloat {
        switch heightDimension {
        case .verySmall: return 40
        case .small: return 40
        case .middle: return 45
        case .large, .xLarge, .xxLarge: return 45
        }
    }

    static var socialButtonHeight: CGFloat {
        return submitButtonHeight
    }

    static var submitButtonCornerRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 20
        case .small: return 20
        case .middle: return 20
        case .large, .xLarge, .xxLarge: return 20
        }
    }

    // horizontal space popup edges to screen edges
    static var minPopupHMargin: CGFloat {
        return 20
    }

    // MARK: Login
    
    static var topConstraintFirstInputWhenClose: CGFloat {
        switch heightDimension {
        case .verySmall: return 10
        case .small: return 30
        case .middle: return 60
        case .large, .xLarge, .xxLarge: return 80
        }
    }
    
    static var topConstraintFirstInputWhenOpen: CGFloat {
        switch heightDimension {
        case .verySmall: return 60
        case .small: return 60
        case .middle: return 60
        case .large, .xLarge, .xxLarge: return 60
        }
    }

    static var topConstraintLoginButton: CGFloat {
        switch heightDimension {
        case .verySmall: return 31
        case .small: return 31
        case .middle: return 31
        case .large, .xLarge, .xxLarge: return 40
        }
    }

    static var topConstraintRegisterButton: CGFloat {
        switch heightDimension {
        case .verySmall: return 18
        case .small: return 18
        case .middle: return 18
        case .large, .xLarge, .xxLarge: return 25
        }
    }

    // MARK: Report

    
    static var pieChartRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 70
        case .small: return 80
        case .middle: return 85
        case .large, .xLarge, .xxLarge: return 85
        }
    }

    static var pieChartLabelRadius: CGFloat {
        switch heightDimension {
        case .verySmall: return 55
        case .small: return 65
        case .middle: return 70
        case .large, .xLarge, .xxLarge: return 70
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
    
    // MARK: Picker general
    
    static var pickerRowHeight: CGFloat {
        return 25
    }

    // MARK: Other

    static var tapToGoBackLabelY: CGFloat {
        switch heightDimension {
        case .verySmall: return 90
        case .small: return 90
        case .middle: return 90
        case .large, .xLarge, .xxLarge: return 105
        }
    }
}
