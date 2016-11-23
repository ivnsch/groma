//
//  ShareAppViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKShareKit

class ShareAppViewController: UIViewController {

    @IBOutlet weak var facebookButton: FBSDKShareButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = URL(string: "https://developers.facebook.com")
        // Note that when link to store apparently title and description not used, see https://developers.facebook.com/docs/sharing/ios
        content.contentTitle = "Share Foo"
//        content.contentDescription = "All round manager for shopping lists, household inventory and budget" // we don't want to accidentally publish this in FB yet ;)
        content.contentDescription = "Description blabla"
//        content.imageURL = NSURL(string: "<INSERT STRING HERE>")
        facebookButton.shareContent = content
    }
}
