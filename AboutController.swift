//
//  AboutController.swift
//  shoppin
//
//  Created by ischuetz on 2/6/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

class AboutController: UIViewController {

    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var vatinLabel: UILabel!
    @IBOutlet weak var followTwitterLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.mainBGColor

        if let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            appVersionLabel.text = versionNumber
        }

        vatinLabel.text = trans("about_vat_id", "DE289356506")
        followTwitterLabel.text = trans("about_follow_twitter")
    }

    @IBAction func didPressFollowOnTwitter(_ sender: UIButton) {
        TwitterShareHelper.followOnTwitter()
    }
}
