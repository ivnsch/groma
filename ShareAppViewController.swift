//
//  ShareAppViewController.swift
//  shoppin
//
//  Created by ischuetz on 16/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import FBSDKShareKit

class ShareAppViewController: UIViewController {

    @IBOutlet weak var facebookButton: FBSDKShareButton!

    override func viewWillAppear(_ animated: Bool) {
        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = URL(string: "https://developers.facebook.com")
        facebookButton.shareContent = content
    }
}
