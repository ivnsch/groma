//
//  EmailHelper.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI
import QorumLogs

protocol EmailHelperDelegate: class {
    func onEmailSent()
}

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    
    private let controller: UIViewController
    
    weak var delegate: EmailHelperDelegate?
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    func showEmail(appendSpecs appendSpecs: Bool = true) {
        let email = "foo@bar.com"
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject("Feedback")
            
            if appendSpecs {
                let device = UIDevice().type
                
                if device == .unrecognized {
                    QL4("No device name for: \(device)")
                }
                
                let userStrMaybe = Providers.userProvider.mySharedUser.map{"User id: \($0.email)"}
                
                let strMaybe: String? = {
                    switch (userStrMaybe, device) {
                    case (nil, .unrecognized): return nil
                    case (nil, let deviceId): return "\n\n\(trans("email_device", deviceId.rawValue))"
                    case (let userStr, .unrecognized): return "\n\n\(userStr!)"
                    case (let userStr, let deviceId): return "\n\n\(userStr!), \(trans("email_device", deviceId.rawValue))"
                    }
                }()
                
                if let str = strMaybe {
                    mail.setMessageBody(str, isHTML: false)
                }
            }

            controller.presentViewController(mail, animated: true, completion: nil)
        } else {
            AlertPopup.show(message: trans("popup_couldnt_find_email_account", email), controller: controller)
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