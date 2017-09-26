//
//  RatingPopup.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol RatingPopupDelegate: class {
    func onDismissRatingPopup()
}

// A more customisable version of RatingAlert but without a decent UI yet
class RatingPopup: RatingPopupControllerDelegate {

    fileprivate let showLaterDays = 7
    
    fileprivate var controller: UIViewController?
    
    weak var delegate: RatingPopupDelegate?
    
    func checkShow(_ parentController: UIViewController) {
        
        func appInstallDate() -> Date {
            return PreferencesManager.loadPreference(PreferencesManagerKey.firstLaunchDate) ?? {
                logger.e("Invalid state: There's no app first launch date stored.")
                return Date() // just to return something - note that with this we will never show the popup as the time offset will be ~0
            }()
        }
        
        // When the user hasn't selected "never show again"
        func onCanShow() {
            // use last time user tapped "later" as reference date or the app install date if this hasn't happened yet
            let referenceDate = PreferencesManager.loadPreference(PreferencesManagerKey.lastAppRatingDialogDate).map {(date: Date) in
                return date
            } ?? appInstallDate()
            
            let passedDays = referenceDate.daysUntil(Date())
            logger.v("\(passedDays) days passed since last reference date. Showing if >= \(showLaterDays)")
            if passedDays >= showLaterDays {
                show(parentController)
            }
        }
        
        if let selectedNeverShow: Bool = PreferencesManager.loadPreference(PreferencesManagerKey.dontShowAppRatingDialogAgain) {
            if !selectedNeverShow {
                onCanShow()
            } else {
                logger.v("User selected to never show rating popup.")
            }
        } else {
            logger.v("The rating dialog was never shown yet. Checking time.")
            onCanShow()
        }
    }
    
    func show(_ parentController: UIViewController) {
        let controller = UIStoryboard.ratingPopupController()
        
        let width = parentController.view.frame.width
        let height = parentController.view.frame.height

        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
    
        controller.delegate = self
    
        parentController.present(controller, animated: true, completion: nil)

        self.controller = controller
    }
    
    // MARK: - RatingPopupControllerDelegate
    
    func dismiss() {
        controller?.presentingViewController?.dismiss(animated: true, completion: nil)
        delegate?.onDismissRatingPopup()
    }
}
