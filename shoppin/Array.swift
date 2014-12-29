//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

    extension Array {
        func forEach<U>(function: (element: T) -> U) {
            for e in self {
                function(element: e)
            }
        }
    }
