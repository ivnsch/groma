//
//  MoreViewController.swift
//  shoppin
//
//  Created by ischuetz on 27/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

enum MoreItemType {
    case history, manageProduct, user, settings, help, share, feedback, community, watchIntro, about, deviceInfo
}

typealias MoreItem = (type: MoreItemType, text: String, image: UIImage)

class MoreViewController: UITableViewController {
   
    fileprivate var emailHelper: EmailHelper?
    
    fileprivate var items: [MoreItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        styleBackButton()
        
        tableView.backgroundColor = Theme.defaultTableViewBGColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        items = [
            MoreItem(type: .history, text: trans("more_history"), image: #imageLiteral(resourceName: "more_history")),
            MoreItem(type: .manageProduct, text: trans("title_manage_database"), image: #imageLiteral(resourceName: "more_manage_items")),
            MoreItem(type: .settings, text: trans("more_settings"), image: #imageLiteral(resourceName: "more_settings")),
            MoreItem(type: .help, text: trans("more_help"), image: #imageLiteral(resourceName: "more_help")),
            MoreItem(type: .share, text: trans("more_share"), image: #imageLiteral(resourceName: "more_share")),
            MoreItem(type: .community, text: trans("more_community"), image: #imageLiteral(resourceName: "more_community")),
            MoreItem(type: .feedback, text: trans("more_feedback"), image: #imageLiteral(resourceName: "more_feedback")),
            MoreItem(type: .watchIntro, text: trans("more_intro"), image: #imageLiteral(resourceName: "more_intro")),
            MoreItem(type: .about, text: trans("more_about"), image: #imageLiteral(resourceName: "more_info")),
//            MoreItem(type: .deviceInfo, text: "\(UIDevice.current.modelCode), \(UIScreen.main.nativeBounds.height)")
        ]
        
        if CountryHelper.isInServerSupportedCountry() {
            items.insert((type: .user, text: trans("more_user"), image: #imageLiteral(resourceName: "more_user")), at: 2)
        }
        
        tableView.reloadData()

    }
    
    fileprivate func styleBackButton() {
        let backBtn = UIImage(named: "tb_back")?.withRenderingMode(.alwaysOriginal)
        navigationController?.navigationBar.backIndicatorImage = backBtn
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backBtn
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[(indexPath as NSIndexPath).row]
        
        switch item.type {
            
        case .history:
            let controller = UIStoryboard.historyViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .manageProduct:
            let controller = UIStoryboard.manageDatabaseController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .user:
            let controller = UIStoryboard.userTabItemViewController()
            navigationController?.pushViewController(controller, animated: true)

        case .settings:
            let controller = UIStoryboard.settingsViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .help:
            let controller = UIStoryboard.helpViewController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .feedback:
            emailHelper = EmailHelper(controller: self)
            emailHelper?.showEmail()

        case .community:
            let controller = CommunityController()
            navigationController?.pushViewController(controller, animated: true)
            
        case .share:
            share(trans("sharing_message"), sharingImage: nil, sharingURL: URL(string: "https://itunes.apple.com/app/groma/id1121689899?&mt=8"))
            // Initially implemented this, which contains facebook sharing using its SDK. It seems with the default share we achieve the same functionality (Facebook seems to not allow to add title and description to links to the app store, which is what we want to link to, see https://developers.facebook.com/docs/sharing/ios - this would have been the only reason to use the SDK). Letting it commented just in case.
//            let controller = UIStoryboard.shareAppViewController()
//            navigationController?.setNavigationBarHidden(true, animated: false)
//            navigationController?.pushViewController(controller, animated: true)
            
        case .watchIntro:
            let controller = UIStoryboard.introViewController()
            controller.mode = .more
            navigationController?.pushViewController(controller, animated: true)
            
        case .about:
            let controller = UIStoryboard.aboutViewController()
            navigationController?.pushViewController(controller, animated: true)

        case .deviceInfo: break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DimensionsManager.defaultCellHeight
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "moreCell", for: indexPath) as! MoreCell
        let item = items[(indexPath as NSIndexPath).row]
        cell.moreItem = item
        return cell
    }
    
    func share(_ sharingText: String?, sharingImage: UIImage?, sharingURL: URL?) {
        var sharingItems = [AnyObject]()
        if let text = sharingText {
            sharingItems.append(text as AnyObject)
        }
        if let image = sharingImage {
            sharingItems.append(image)
        }
        if let url = sharingURL {
            sharingItems.append(url as AnyObject)
        }
        
        view.defaultProgressVisible(true)
        background({
            let controller = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
//            controller.excludedActivityTypes = [UIActivityTypeAirDrop]
            controller.setValue(trans("share_subject"), forKey: "Subject")
            return controller
        }) {[weak self] (controller: UIViewController) in
            self?.view.defaultProgressVisible(false)
            self?.present(controller, animated: true, completion: nil)
        }
    }
    
    deinit {
        logger.v("Deinit more controller")
    }
}
