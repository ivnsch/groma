//
//  IntroPageView.swift
//  shoppin
//
//  Created by ischuetz on 02/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import UIKit

class IntroPageView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.font = Fonts.smallLight
        
        imageView.contentMode = .Center
    }
}
