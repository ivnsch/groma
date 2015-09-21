//
//  InfoAlert.swift
//  shoppin
//
//  Created by ischuetz on 15/09/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class InfoAlertBuilder {
    
    static func create(title title: String? = nil, message: String) -> UIViewController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        return alert
    }
}
