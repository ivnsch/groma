//
//  RatingPopup.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol RatingPopupDelegate {
    func onDismissRatingPopup()
}

// A more customisable version of RatingAlert but without a decent UI yet
class RatingPopup: RatingPopupControllerDelegate {

    private let showLaterDays = 7
    
    private var controller: UIViewController?
    
    var delegate: RatingPopupDelegate?
    
    func checkShow(parentController: UIViewController) {
        
        func appInstallDate() -> NSDate {
            return PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) ?? {
                QL4("Invalid state: There's no app first launch date stored.")
                return NSDate() // just to return something - note that with this we will never show the popup as the time offset will be ~0
            }()
        }
        
        // When the user hasn't selected "never show again"
        func onCanShow() {
            // use last time user tapped "later" as reference date or the app install date if this hasn't happened yet
            let referenceDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastAppRatingDialogDate).map {(date: NSDate) in
                return date
            } ?? appInstallDate()
            
            let passedDays = referenceDate.daysUntil(NSDate())
            QL1("\(passedDays) days passed since last reference date. Showing if >= \(showLaterDays)")
            if passedDays >= showLaterDays {
                show(parentController)
            }
        }
        
        if let selectedNeverShow: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.dontShowAppRatingDialogAgain) {
            if !selectedNeverShow {
                onCanShow()
            } else {
                QL1("User selected to never show rating popup.")
            }
        } else {
            QL1("The rating dialog was never shown yet. Checking time.")
            onCanShow()
        }
    }
    
    func show(parentController: UIViewController) {
        let controller = UIStoryboard.ratingPopupController()
        
        let width = parentController.view.frame.width
        let height = parentController.view.frame.height

        controller.view.frame = CGRectMake(0, 0, width, height)
    
        controller.delegate = self
    
        parentController.presentViewController(controller, animated: true, completion: nil)

        self.controller = controller
    }
    
    // MARK: - RatingPopupControllerDelegate
    
    func dismiss() {
        controller?.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        delegate?.onDismissRatingPopup()
    }
}
