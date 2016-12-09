//
//  LoadingFooter.swift
//  shoppin
//
//  Created by ischuetz on 27/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class LoadingFooter: UIView {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        self.activityIndicator.startAnimating()
    }
}
