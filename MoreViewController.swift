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
        case 7: // Share
            share("Message message", sharingImage: nil, sharingURL: NSURL(string: "https://developers.facebook.com"))
            // Initially implemented this, which contains facebook sharing using its SDK. It seems with the default share we achieve the same functionality (Facebook seems to not allow to add title and description to links to the app store, which is what we want to link to, see https://developers.facebook.com/docs/sharing/ios - this would have been the only reason to use the SDK). Letting it commented just in case.
//            let controller = UIStoryboard.shareAppViewController()
//            navigationController?.setNavigationBarHidden(true, animated: false)
//            navigationController?.pushViewController(controller, animated: true)
            
        default: break
        }
    }
    
    // src: http://stackoverflow.com/a/13499204/930450
    func share(sharingText: String?, sharingImage: UIImage?, sharingURL: NSURL?) {
        var sharingItems = [AnyObject]()
        if let text = sharingText {
            sharingItems.append(text)
        }
        if let image = sharingImage {
            sharingItems.append(image)
        }
        if let url = sharingURL {
            sharingItems.append(url)
        }
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
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
