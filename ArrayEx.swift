//
//  ArrayEx.swift
//  shoppin
//
//  Created by ischuetz on 24/10/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

/////////////////////////////////////////////////////////////////////////////////////
// src: https://github.com/yoavlt/LiquidFloatingActionButton/blob/master/Pod/Classes/ArrayEx.swift

// Don't use this - for each is for side effects and we use loops for this. Only added because library files use it and want to modify these files as little as possible.

/////////////////////////////////////////////////////////////////////////////////////
extension Array {

    func each(f: (Element) -> ()) {
        for item in self {
            f(item)
        }
    }
}
