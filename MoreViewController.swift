//
//  MoreViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class MoreViewController: UITableViewController {
   
    private var emailHelper: EmailHelper?

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row  {
            
        case 1: // Manage product
            let controller = UIStoryboard.manageProductsSelectionController()
            navigationController?.pushViewController(controller, animated: true)
            
        case 5: // Feedback
            emailHelper = EmailHelper(controller: self)
            emailHelper?.showEmail()
  
        case 6: // Share
            share("Message message", sharingImage: nil, sharingURL: NSURL(string: "https://developers.facebook.com"))
            // Initially implemented this, which contains facebook sharing using its SDK. It seems with the default share we achieve the same functionality (Facebook seems to not allow to add title and description to links to the app store, which is what we want to link to, see https://developers.facebook.com/docs/sharing/ios - this would have been the only reason to use the SDK). Letting it commented just in case.
//            let controller = UIStoryboard.shareAppViewController()
//            navigationController?.setNavigationBarHidden(true, animated: false)
//            navigationController?.pushViewController(controller, animated: true)
            
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        // When returning cell height programatically, here it's still the height from the storyboard so we have to pass the offset for the line to eb draw at the bottom.
        cell.contentView.addBorderWithYOffset(Theme.cellBottomBorderColor, width: 1, offset: DimensionsManager.defaultCellHeight)
        return cell
    }
    
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
        
        view.defaultProgressVisible(true)
        background({
            let controller = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
//            controller.excludedActivityTypes = [UIActivityTypeAirDrop]
            return controller
        }) {[weak self] (controller: UIViewController) in
            self?.view.defaultProgressVisible(false)
            self?.presentViewController(controller, animated: true, completion: nil)
        }
    }
}
