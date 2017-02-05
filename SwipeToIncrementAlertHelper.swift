//
//  SwipeToIncrementAlertHelper.swift
//  shoppin
//
//  Created by ischuetz on 17/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers
import QorumLogs

class SwipeToIncrementAlertHelperNew {

    static let countToShowPopup: Int = 0
    
    var preference: PreferencesManagerKey?
    
    func showPopup() -> Bool {
        
        guard let preference = preference else {QL4("No preference, exit."); return false}
        
        let showedCanSwipeToIncrementCountNumber: NSNumber = PreferencesManager.loadPreference(preference) ?? 0
        let showedCanSwipeToIncrementCount = showedCanSwipeToIncrementCountNumber.intValue
        var show: Bool
        if showedCanSwipeToIncrementCount == SwipeToIncrementAlertHelperNew.countToShowPopup {
            show = true // no incrementing here, i.e. continue showing until user taps "got it" which sets the preference to false
        } else {
            PreferencesManager.savePreference(preference, value: NSNumber(value: showedCanSwipeToIncrementCount + 1))
            show = false
        }
        
        return show
    }
    
    func dontShowAgain() {
        guard let preference = preference else {QL4("No preference, exit."); return}

        PreferencesManager.savePreference(preference, value: NSNumber(value: SwipeToIncrementAlertHelperNew.countToShowPopup + 1))
    }
}

// deprecated
class SwipeToIncrementAlertHelper {
    
    static let countToShowPopup: Int = 0
    
    // Shows alert explaining swipe to increment if user has incremented x times.
    static func check(_ controller: UIViewController) {
        if showPopup() {
            AlertPopup.show(title: trans("popup_title_psst"), message: trans("popups_swipe_to_increment_explanation"), controller: controller)
        }
    }
    
    static func showPopup() -> Bool {
        let showedCanSwipeToIncrementCountNumber: NSNumber = PreferencesManager.loadPreference(.showedCanSwipeToIncrementCounter) ?? 0
        let showedCanSwipeToIncrementCount = showedCanSwipeToIncrementCountNumber.intValue
        var show: Bool
        if showedCanSwipeToIncrementCount == countToShowPopup {
            show = true // no incrementing here, i.e. continue showing until user taps "got it" which sets the preference to false
        } else {
            PreferencesManager.savePreference(PreferencesManagerKey.showedCanSwipeToIncrementCounter, value: NSNumber(value: showedCanSwipeToIncrementCount + 1))
            show = false
        }
        
        return show
    }
    
    static func dontShowAgain() {
        PreferencesManager.savePreference(PreferencesManagerKey.showedCanSwipeToIncrementCounter, value: NSNumber(value: countToShowPopup + 1))
    }
}
