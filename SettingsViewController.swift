//
//  SettingsViewController.swift
//  shoppin
//
//  Created by ischuetz on 04/02/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func onClearAllDataTap(sender: UIButton) {
        Providers.globalProvider.clearAllData(successHandler{
            AlertPopup.show(message: "The data was cleared", controller: self)
        })
    }
}