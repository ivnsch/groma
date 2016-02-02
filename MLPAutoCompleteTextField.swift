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
        autoCompleteTableBorderColor = UIColor.lightGrayColor()
        autoCompleteTableBorderWidth = 0.4
        autoCompleteTableBackgroundColor = UIColor.whiteColor()
        autoCompleteTableCornerRadius = 14
        autoCompleteBoldFontName = Fonts.fontNameBold
        autoCompleteRegularFontName = Fonts.fontName
        showTextFieldDropShadowWhenAutoCompleteTableIsOpen = false
        reverseAutoCompleteSuggestionsBoldEffect = true // to mark the matched part as bold and the rest regular
        maximumNumberOfAutoCompleteRows = 4
        sortAutoCompleteSuggestionsByClosestMatch = true
    }
}
