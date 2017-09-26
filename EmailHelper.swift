//
//  EmailHelper.swift
//  shoppin
//
//  Created by ischuetz on 27/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI

import Providers

protocol EmailHelperDelegate: class {
    func onEmailSent()
}

class EmailHelper: NSObject, MFMailComposeViewControllerDelegate {
    
    fileprivate let controller: UIViewController
    
    weak var delegate: EmailHelperDelegate?
    
    init(controller: UIViewController) {
        self.controller = controller
    }
    
    func showEmail(appendSpecs: Bool = true) {
        let email = "info@groma.co"
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([email])
            mail.setSubject("Feedback")
            
            if appendSpecs {
                let device = UIDevice().type
                
                if device == .unrecognized {
                    logger.e("No device name for: \(device)")
                }
                
                let userStrMaybe = Prov.userProvider.mySharedUser.map{"User id: \($0.email)"}
                
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

            controller.present(mail, animated: true, completion: nil)
        } else {
            AlertPopup.show(message: trans("popup_couldnt_find_email_account", email), controller: controller)
        }
    }
    
    // MARK: - MFMailComposeViewControllerDelegate
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result.rawValue {
        case MFMailComposeResult.cancelled.rawValue:
            print("Mail cancelled")
        case MFMailComposeResult.saved.rawValue:
            print("Mail saved")
        case MFMailComposeResult.sent.rawValue:
            print("Mail sent")
            delegate?.onEmailSent() // TODO!!!! test this with device
        case MFMailComposeResult.failed.rawValue:
            print("Mail sent failure: \(String(describing: error?.localizedDescription))")
        default:
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
}
