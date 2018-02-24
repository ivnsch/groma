//
//  AboutController.swift
//  shoppin
//
//  Created by ischuetz on 2/6/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class AboutController: UIViewController {

    fileprivate var emailHelper: EmailHelper?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.mainBGColor
    }

    @IBAction func onContactTap(_ sender: UIButton) {
        emailHelper = EmailHelper(controller: self)
        emailHelper?.showEmail(appendSpecs: false)
    }
}
