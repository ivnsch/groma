//
//  UILabel.swift
//  shoppin
//
//  Created by Ivan Schuetz on 10/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

import Providers

public extension UILabel {

    /// We have to pass regularFont instead of using the current font, because if animateBold is called multiple times quickly, current "font" variable may be the bold font, so we set back the bold font at the end of the animation, and the label stays bold.
    func animateBold(_ duration: Double, regularFont: UIFont) {
        
        guard makeBold() else {return}
        
        delay(duration) {[weak self] in
            self?.font = regularFont
        }
    }
    
    func makeBold() -> Bool {
        
        guard let boldFont = font.bold else {logger.e("Couldn't get bold version. Font: \(font)"); return false}
        
        font = boldFont
        
        return true
    }

    // Param: overrideWidth: if for some reason the label's width isn't ready yet, allow to pass a pre-computed (e.g. using the constraint constants) one.
    func estimatedHeight(overrideWidth: CGFloat? = nil) -> CGFloat {
        let labelWidth = overrideWidth ?? frame.width
        return sizeThatFits(CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)).height
    }

    func boundingRect(forCharacterRange range: NSRange) -> CGRect? {
        guard let attributedText = attributedText else { return nil }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()

        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: bounds.size)
        textContainer.lineFragmentPadding = 0.0

        layoutManager.addTextContainer(textContainer)

        var glyphRange = NSRange()

        // Convert the range for glyphs.
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
}
