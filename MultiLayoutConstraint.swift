//
//  MultiLayoutConstraint.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import Providers

@IBDesignable class MultiLayoutConstraint: NSLayoutConstraint {

    @IBInspectable var horizontal: Bool = false

    fileprivate static let invalidNumber: Float = -9999999
    
    @IBInspectable var hSmall: Float = invalidNumber
    @IBInspectable var hMiddle: Float = invalidNumber
    @IBInspectable var hLarge: Float = invalidNumber

    @IBInspectable var vVerySmall: Float = invalidNumber
    @IBInspectable var vSmall: Float = invalidNumber
    @IBInspectable var vMiddle: Float = invalidNumber
    @IBInspectable var vLarge: Float = invalidNumber
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // logging
        func dimensionStr() -> String {
            return horizontal ? String(describing: DimensionsManager.widthDimension) : String(describing: DimensionsManager.heightDimension)
        }

        let constant: Float = {
            if horizontal {
                switch DimensionsManager.widthDimension {
                case .small: return hSmall
                case .middle: return hMiddle
                case .large: return hLarge
                }
            } else {
                switch DimensionsManager.heightDimension {
                case .verySmall: return vVerySmall
                case .small: return vSmall
                case .middle: return vMiddle
                case .large, .xLarge: return vLarge
                }
            }
        }()

        if constant != MultiLayoutConstraint.invalidNumber {
            self.constant = CGFloat(constant)
        } else {
            logger.w("Value for dimension not provided. horizontal: \(horizontal)")
        }

//        logger.v(horizontal)
//        logger.v(hSmall)
//        logger.v(hMiddle)
//        logger.v(hLarge)
//        logger.v(vVerySmall)
//        logger.v(vSmall)
//        logger.v(vMiddle)
//        logger.v(vLarge)
    }
}
