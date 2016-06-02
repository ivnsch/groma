//
//  AboutController.swift
//  shoppin
//
//  Created by ischuetz on 2/6/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class AboutController: UIViewController {

    private var emailHelper: EmailHelper?

    @IBAction func onContactTap(sender: UIButton) {
        emailHelper = EmailHelper(controller: self)
        emailHelper?.showEmail(appendSpecs: false)
    }
}
