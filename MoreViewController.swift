//
//  MoreViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

enum MoreItemType {
    case History, ManageProduct, User, Settings, Help, Share, Feedback, WatchIntro, About
}

typealias MoreItem = (type: MoreItemType, text: String)

class MoreViewController: UITableViewController {
   
    private var emailHelper: EmailHelper?
    
    private var items: [MoreItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleBackButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        items = [
            MoreItem(type: .History, text: trans("more_history")),
            MoreItem(type: .ManageProduct, text: trans("more_products")),
            MoreItem(type: .Settings, text: trans("more_settings")),
            MoreItem(type: .Help, text: trans("more_help")),
            MoreItem(type: .Share, text: trans("more_share")),
            MoreItem(type: .Feedback, text: trans("more_feedback")),
            MoreItem(type: .WatchIntro, text: trans("more_intro")),
            MoreItem(type: .About, text: trans("more_about"))
        ]
        
        if CountryHelper.isInServerSupportedCountry() {
            items.insert((type: .User, text: trans("more_user")), atIndex: 2)
        }
        
        tableView.reloadData()
    }
    
    private func styleBackButton() {
        let backBtn = UIImage(named: "tb_back")?.imageWithRenderingMode(.AlwaysOriginal)
        navigationController?.navigationBar.backIndicatorImage = backBtn
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backBtn
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = items[indexPath.row]
        
        switch item.type {
            
        case .History:
            let controller = UIStoryboard.historyViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .ManageProduct:
            let controller = UIStoryboard.manageProductsViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .User:
            let controller = UIStoryboard.userTabItemViewController()
            navigationController?.pushViewController(controller, animated: true)

        case .Settings:
            let controller = UIStoryboard.settingsViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .Help:
            let controller = UIStoryboard.helpViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .Feedback:
            emailHelper = EmailHelper(controller: self)
            emailHelper?.showEmail()
            
        case .Share:
            share(trans("sharing_message"), sharingImage: nil, sharingURL: NSURL(string: "https://itunes.apple.com/app/groma/id1121689899?&mt=8"))
            // Initially implemented this, which contains facebook sharing using its SDK. It seems with the default share we achieve the same functionality (Facebook seems to not allow to add title and description to links to the app store, which is what we want to link to, see https://developers.facebook.com/docs/sharing/ios - this would have been the only reason to use the SDK). Letting it commented just in case.
//            let controller = UIStoryboard.shareAppViewController()
//            navigationController?.setNavigationBarHidden(true, animated: false)
//            navigationController?.pushViewController(controller, animated: true)
            
        case .WatchIntro:
            let controller = UIStoryboard.introViewController()
            controller.mode = .More
            navigationController?.pushViewController(controller, animated: true)
            
        case .About:
            let controller = UIStoryboard.aboutViewController()
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("moreCell", forIndexPath: indexPath) as! MoreCell
        let item = items[indexPath.row]
        cell.moreItem = item
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
            controller.setValue(trans("share_subject"), forKey: "Subject")
            return controller
        }) {[weak self] (controller: UIViewController) in
            self?.view.defaultProgressVisible(false)
            self?.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    deinit {
        QL1("Deinit more controller")
    }
}
