//
//  MLPAutoCompleteswift
//  shoppin
//
//  Created by ischuetz on 07/11/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

extension MLPAutoCompleteTextField {

    func defaultAutocompleteStyle() {
        borderStyle = .Line
        autoCompleteTableBorderColor = UIColor.grayColor()
        autoCompleteTableBorderWidth = 0.3
//        autoCompleteTableCornerRadius = 8
        autoCompleteBoldFontName = Fonts.fontNameBold
        autoCompleteRegularFontName = Fonts.fontName
        showTextFieldDropShadowWhenAutoCompleteTableIsOpen = false
        reverseAutoCompleteSuggestionsBoldEffect = true // to mark the matched part as bold and the rest regular
        maximumNumberOfAutoCompleteRows = 4
        sortAutoCompleteSuggestionsByClosestMatch = true
        shouldResignFirstResponderFromKeyboardAfterSelectionOfAutoCompleteRows = false
        autoCompleteTableBackgroundColor = UIColor.whiteColor()
        autoCompleteTableOriginOffset = CGSizeMake(0, -1.5)
        partOfAutoCompleteRowHeightToCut = 0.8
    }
}
