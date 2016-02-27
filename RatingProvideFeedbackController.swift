//
//  RatingProvideFeedbackController.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI

protocol RatingProvideFeedbackControllerDelegate {
    func onEmailSent()
}

class RatingProvideFeedbackController: UIViewController, EmailHelperDelegate {

    private var emailHelper: EmailHelper?
    
    var delegate: RatingProvideFeedbackControllerDelegate?
    
    @IBAction func onProvideFeedbackTap(sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: NSDate())

        emailHelper = EmailHelper(controller: self)
        emailHelper?.showEmail()
    }
    
    @IBAction func onCancelTap(sender: UIButton) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - EmailHelperDelegate
    
    func onEmailSent() {
        delegate?.onEmailSent()
    }
}