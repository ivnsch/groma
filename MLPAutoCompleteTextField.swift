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
        borderStyle = .line
        autoCompleteTableBorderColor = UIColor.gray
        autoCompleteTableBorderWidth = 0.3
//        autoCompleteTableCornerRadius = 8
        autoCompleteBoldFontName = UIFont.systemFont(ofSize: 12).bold?.fontName
        autoCompleteRegularFontName = UIFont.systemFont(ofSize: 12).fontName
        showTextFieldDropShadowWhenAutoCompleteTableIsOpen = false
        reverseAutoCompleteSuggestionsBoldEffect = true // to mark the matched part as bold and the rest regular
        maximumNumberOfAutoCompleteRows = 4
        sortAutoCompleteSuggestionsByClosestMatch = true
        shouldResignFirstResponderFromKeyboardAfterSelectionOfAutoCompleteRows = false
        autoCompleteTableBackgroundColor = UIColor.white
        autoCompleteTableOriginOffset = CGSize(width: 0, height: -1.5)
        partOfAutoCompleteRowHeightToCut = 0.8
    }
}
