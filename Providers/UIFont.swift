//
//  UIFont.swift
//  shoppin
//
//  Created by ischuetz on 04/05/16.
//  Copyright © 2016 ivanschuetz. All rights reserved.
//

import UIKit

extension UIFont {
    
    public var isBold: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    public var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
}
