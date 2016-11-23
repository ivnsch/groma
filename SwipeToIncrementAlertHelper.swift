//
//  SwipeToIncrementAlertHelper.swift
//  shoppin
//
//  Created by ischuetz on 17/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class SwipeToIncrementAlertHelper {

    static let countToShowPopup: Int = 3
    
    // Shows alert explaining swipe to increment if user has incremented x times.
    static func check(_ controller: UIViewController) {
        let showedCanSwipeToIncrementCountNumber: NSNumber = PreferencesManager.loadPreference(.showedCanSwipeToIncrementCounter) ?? 0
        let showedCanSwipeToIncrementCount = showedCanSwipeToIncrementCountNumber.intValue
        if showedCanSwipeToIncrementCount == countToShowPopup {
            AlertPopup.show(title: trans("popup_title_psst"), message: trans("popups_swipe_to_increment_explanation"), controller: controller)
        }
        PreferencesManager.savePreference(PreferencesManagerKey.showedCanSwipeToIncrementCounter, value: NSNumber(value: showedCanSwipeToIncrementCount + 1 as Int))
    }
}
