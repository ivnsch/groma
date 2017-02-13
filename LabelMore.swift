//
//  LabelMore.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

@IBDesignable public class LabelMore: UILabel {
    
    @IBInspectable public var fontType: NSNumber = -1
    
    // TODO enum for fontTypes? with the same name as the numbers such that we can add later 21, 22 etc. if necessary. For storyboards this is not very useful but when we set the font programmatically at least
    public static func mapToFontSize(_ fontType: Int) -> CGFloat? {
        switch (DimensionsManager.widthDimension, fontType) {
        case (.small, 20): return 10
        case (.small, 30): return 12
        case (.small, 40): return 14
        case (.small, 50): return 16
        case (.small, 60): return 18

        case (.middle, 20): return 11
        case (.middle, 30): return 13
        case (.middle, 40): return 15
        case (.middle, 50): return 18
        case (.middle, 60): return 20

        case (.large, 20): return 13
        case (.large, 30): return 15
        case (.large, 40): return 17
        case (.large, 50): return 20
        case (.large, 60): return 22
        
        default:
            QL3("Not handled fontType: \(fontType)")
            return nil
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        if let size = fontSize() {
            
//            QL1("Init label with font size: \(size), text?: \(text). Dimension: \(DimensionsManager.widthDimension)")
            
            self.font = {
                if font.isBold {
                    return UIFont.boldSystemFont(ofSize: size)
                } else {
                    return UIFont.systemFont(ofSize: size)
                }
            }()
        }
    }
    
    fileprivate func fontSize() -> CGFloat? {
        return LabelMore.mapToFontSize(fontType.intValue)
    }
    
    public func makeFontBold() {
        if let size = fontSize() {
            font = UIFont.boldSystemFont(ofSize: size)
        }
    }
    
    public func makeFontRegular() {
        if let size = fontSize() {
            font = UIFont.systemFont(ofSize: size)
        }
    }
}
