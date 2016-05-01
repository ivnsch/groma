//
//  MultiLayoutConstraint.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

@IBDesignable class MultiLayoutConstraint: NSLayoutConstraint {

    @IBInspectable var horizontal: Bool = false

    private static let invalidNumber: Float = -9999999
    
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
            return horizontal ? String(DimensionsManager.widthDimension) : String(DimensionsManager.heightDimension)
        }

        let constant: Float = {
            if horizontal {
                switch DimensionsManager.widthDimension {
                case .Small: return hSmall
                case .Middle: return hMiddle
                case .Large: return hLarge
                }
            } else {
                switch DimensionsManager.heightDimension {
                case .VerySmall: return vVerySmall
                case .Small: return vSmall
                case .Middle: return vMiddle
                case .Large: return vLarge
                }
            }
        }()

        if constant != MultiLayoutConstraint.invalidNumber {
            if QorumLogs.minimumLogLevelShown < 3 {
                QL1("Updating constraint from: \(self.constant) to: \(constant), dimension: \(dimensionStr())")
            }
            self.constant = CGFloat(constant)
        } else {
            QL3("Value for dimension not provided. horizontal: \(horizontal)")
        }

//        QL1(horizontal)
//        QL1(hSmall)
//        QL1(hMiddle)
//        QL1(hLarge)
//        QL1(vVerySmall)
//        QL1(vSmall)
//        QL1(vMiddle)
//        QL1(vLarge)
    }
}
