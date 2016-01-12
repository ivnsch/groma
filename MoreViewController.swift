//
//  MoreViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import MessageUI

class MoreViewController: UITableViewController, MFMailComposeViewControllerDelegate {
   
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row  {
            
        case 1: // Manage product
            let controller = UIStoryboard.manageProductsViewController()
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.pushViewController(controller, animated: true)
            
        case 6: // Feedback
            let email = "foo@bar.com"
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([email])
                mail.setSubject("Feedback")
//                mail.setMessageBody("", isHTML: true)
                presentViewController(mail, animated: true, completion: nil)
            } else {
                AlertPopup.show(message: "Couldn't find an email account. If the problem persists, please send us an e-mail manually to the address: \(email)", controller: self)
            }
            
        default: break
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
        case MFMailComposeResultFailed.rawValue:
            print("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
