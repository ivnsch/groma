//
//  EmailHelper.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI

protocol EmailHelperDelegate {
    func onEmailSent()
}

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    
    private let controller: UIViewController
    
    var delegate: EmailHelperDelegate?
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    func showEmail() {
        let email = "foo@bar.com"
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject("Feedback")
            //                mail.setMessageBody("", isHTML: true)
            controller.presentViewController(mail, animated: true, completion: nil)
        } else {
            AlertPopup.show(message: "Couldn't find an email account. If the problem persists, please send us an e-mail manually to the address: \(email)", controller: controller)
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResultSaved.rawValue:
            print("Mail saved")
        case MFMailComposeResultSent.rawValue:
            print("Mail sent")
            delegate?.onEmailSent() // TODO!!!! test this with device
        case MFMailComposeResultFailed.rawValue:
            print("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}