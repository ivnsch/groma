//
//  CommunityController.swift
//  shoppin
//
//  Created by Ivan Schuetz on 28/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
import Providers

class CommunityController: UIViewController {
    
    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = trans("more_community")
        
        let url = URL (string: "http://www.google.com")
        let requestObj = URLRequest(url: url!)
        webview.loadRequest(requestObj)
    }
}
