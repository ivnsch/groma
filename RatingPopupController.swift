//
//  RatingPopupController.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

protocol RatingPopupControllerDelegate {
    func dismiss()
}

class RatingPopupController: UIViewController, RatingProvideFeedbackControllerDelegate {
    
    private let appId = "Groma"
    
    var delegate: RatingPopupControllerDelegate?

    @IBAction func onGoodTap(sender: UIButton) {
        if let url = NSURL(string : "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(appId)&onlyLatestVersion=true&pageNumber=0&sortOrdering=1)") {
            if !UIApplication.sharedApplication().openURL(url) {
                AlertPopup.show(message: "Couldn't open app store url.", controller: self)
                PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true) // rating has practically the same meaning as selecting don't show again
            }
        } else {
            QL4("Url is nil, can't go to rating")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let feedbackController = segue.destinationViewController as? RatingProvideFeedbackController {
            feedbackController.delegate = self
        } else {
            QL4("Unexpected controller: \(segue.destinationViewController)")
        }
    }
    
    @IBAction func onAskLaterTap(sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: NSDate())
        delegate?.dismiss()
    }
    
    @IBAction func onNeverAskAgainTap(sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true)
        delegate?.dismiss()        
    }
    
    // MARK: - RatingProvideFeedbackControllerDelegate
    
    func onEmailSent() {
        delegate?.dismiss()
    }
}