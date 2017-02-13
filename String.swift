//
//  String.swift
//  shoppin
//
//  Created by Ivan Schuetz on 13/02/2017.
//  Copyright © 2017 ivanschuetz. All rights reserved.
//

import UIKit

extension String {

    public func makeAttributedBoldRegular(_ range: NSRange) -> NSAttributedString {
        return makeAttributed(range, normalFont: Fonts.regularLight, font: Fonts.regularBold)
    }
    
}
