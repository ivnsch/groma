//
//  UILabel.swift
//  shoppin
//
//  Created by Ivan Schuetz on 10/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit
import QorumLogs
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
        
        guard let boldFont = font.bold else {QL4("Couldn't get bold version. Font: \(font)"); return false}
        
        font = boldFont
        
        return true
    }
}
