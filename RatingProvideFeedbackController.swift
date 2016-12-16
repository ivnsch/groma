//
//  RatingProvideFeedbackController.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI
import Providers

protocol RatingProvideFeedbackControllerDelegate: class {
    func onEmailSent()
}

class RatingProvideFeedbackController: UIViewController, EmailHelperDelegate {

    fileprivate var emailHelper: EmailHelper?
    
    weak var delegate: RatingProvideFeedbackControllerDelegate?
    
    @IBAction func onProvideFeedbackTap(_ sender: UIButton) {
        PreferencesManager.savePreference(PreferencesManagerKey.lastAppRatingDialogDate, value: Date())

        emailHelper = EmailHelper(controller: self)
        emailHelper?.showEmail()
    }
    
    @IBAction func onCancelTap(_ sender: UIButton) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - EmailHelperDelegate
    
    func onEmailSent() {
        delegate?.onEmailSent()
    }
}
