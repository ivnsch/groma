//
//  LeftRightPaddingConstraint.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

class LeftRightPaddingConstraint: NSLayoutConstraint {
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let constant: CGFloat = {
            switch DimensionsManager.widthDimension {
            case .Small: return 20
            case .Middle: return 25
            case .Large: return 30
            }
        }()
        
        self.constant = constant
    }
}