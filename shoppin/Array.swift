//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import UIKit

extension Array {
    func forEach(function: (element: T) -> Void) {
        for e in self {
            function(element: e)
        }
    }
}
