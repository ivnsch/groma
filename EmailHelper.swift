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
import CMPopTipView

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
        let email = "contact@groma.co"
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
            let message = trans("popup_couldnt_find_email_account", email)
            let range: NSRange? = message.range(email) ?? {
                logger.e("Invalid state email not contained in: \(message)", .ui)
                return nil
            }()

            MyPopupHelper.showPopup(
                parent: controller,
                type: .info,
                message: message,
                highlightRanges: range.map { [$0] } ?? [],
                okText: trans("popup_button_yes"),
                centerYOffset: -80,
                onMessageTap: { [weak self] touchPointInPopup, popupController, messageLabel in
                    UIPasteboard.general.string = email

                    let tooltipLocation: CGPoint = (
                        range.flatMap { range in
                            let center: CGPoint? = messageLabel.boundingRect(forCharacterRange: range)?.center
                            return center.map { point in
                                messageLabel.convert(point, to: popupController.view)
                            }
                        }
                    ) ?? {
                        logger.e("Invalid state - didn't find email / center in text - fallback to touch point", .ui)
                        return touchPointInPopup
                    }()

                    self?.copiedEmailTooltip(location: tooltipLocation.copy(y: tooltipLocation.y - 20), popupView: popupController.view)
            })
        }
    }

    fileprivate func copiedEmailTooltip(location: CGPoint, popupView: UIView) {
        let popup = MyTipPopup(message: "Email copied")
        popup.autoDismiss(animated: true, atTimeInterval: 4)
        popup.presentPointing(at: location, in: popupView, animated: true)
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
