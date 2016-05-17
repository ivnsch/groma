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
    static func check(controller: UIViewController) {
        let showedCanSwipeToIncrementCountNumber: NSNumber = PreferencesManager.loadPreference(.showedCanSwipeToIncrementCounter) ?? 0
        let showedCanSwipeToIncrementCount = showedCanSwipeToIncrementCountNumber.integerValue
        if showedCanSwipeToIncrementCount == countToShowPopup {
            AlertPopup.show(title: "Psst!", message: "You can also swipe to the left or right of the cell to change the quantity.\nThis is specially useful if you want to increment/decrement more than 1 at a time!", controller: controller)
        }
        PreferencesManager.savePreference(PreferencesManagerKey.showedCanSwipeToIncrementCounter, value: NSNumber(integer: showedCanSwipeToIncrementCount + 1))
    }
}