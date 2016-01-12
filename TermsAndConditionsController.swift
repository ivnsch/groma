//
//  TermsAndConditionsController.swift
//  shoppin
//
//  Created by ischuetz on 12/01/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class TermsAndConditionsController: UIViewController {

    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let url = NSURL (string: "http://www.shoppin.\(domain)\terms")
        let url = NSURL (string: "http://www.google.\(domain)")
        let requestObj = NSURLRequest(URL: url!)
        webview.loadRequest(requestObj)
    }
    
    var domain: String {
        if let countryCode = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String {
            // maybe we need to do some mappings here later
            return countryCode
        } else {
            print("Error: TermsAndConditionsController.domain: Couldn't get locale: \(NSLocale.currentLocale())")
            return "com"
        }
    }
}
