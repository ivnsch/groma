//
//  LabelMore.swift
//  shoppin
//
//  Created by ischuetz on 01/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs

@IBDesignable class LabelMore: UILabel {
    
    @IBInspectable var fontType: Int = -1
    
    // TODO enum for fontTypes? with the same name as the numbers such that we can add later 21, 22 etc. if necessary. For storyboards this is not very useful but when we set the font programmatically at least
    static func mapToFontSize(fontType: Int) -> CGFloat? {
        switch (DimensionsManager.widthDimension, fontType) {
        case (.Small, 20): return 11
        case (.Small, 30): return 13
        case (.Small, 40): return 15
        case (.Small, 50): return 17
        case (.Small, 60): return 19

        case (.Middle, 20): return 11
        case (.Middle, 30): return 13
        case (.Middle, 40): return 15
        case (.Middle, 50): return 18
        case (.Middle, 60): return 20

        case (.Large, 20): return 13
        case (.Large, 30): return 15
        case (.Large, 40): return 17
        case (.Large, 50): return 19
        case (.Large, 60): return 21
        
        default:
            QL3("Not handled fontType: \(fontType)")
            return nil
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let size = LabelMore.mapToFontSize(fontType) {
            
            QL1("Init label with font size: \(size), text?: \(text). Dimension: \(DimensionsManager.widthDimension)")
            
            self.font = {
                if font.isBold {
                    return UIFont.boldSystemFontOfSize(size)
                } else {
                    return UIFont.systemFontOfSize(size)
                }
            }()
        }
    }
}