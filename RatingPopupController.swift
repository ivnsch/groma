//
//  RatingPopupController.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

protocol RatingPopupControllerDelegate: class {
    func dismiss()
}

class RatingPopupController: UIViewController, RatingProvideFeedbackControllerDelegate {
    
    fileprivate let appId = "Groma"
    
    weak var delegate: RatingPopupControllerDelegate?

    @IBAction func onGoodTap(_ sender: UIButton) {
        if let url = URL(string : "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(appId)&onlyLatestVersion=true&pageNumber=0&sortOrdering=1)") {
            if !UIApplication.shared.openURL(url) {
                MyPopupHelper.showPopup(parent: self, type: .error, title: title, message: trans("popup_couldnt_open_app_store_url"), centerYOffset: -80)
                PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true) // rating has practically the same meaning as selecting don't show again
            }
        } else {
            logger.e("Url is nil, can't go to rating")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let feedbackController = segue.destination as? RatingProvideFeedbackController {
            feedbackController.delegate = self
        } else {
            logger.e("Unexpected controller: \(segue.destination)")
        }
    }
    
    @IBAction func onAskLaterTap(_ sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: Date())
        delegate?.dismiss()
    }
    
    @IBAction func onNeverAskAgainTap(_ sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.dontShowAppRatingDialogAgain, value: true)
        delegate?.dismiss()        
    }
    
    // MARK: - RatingProvideFeedbackControllerDelegate
    
    func onEmailSent() {
        delegate?.dismiss()
    }
}
