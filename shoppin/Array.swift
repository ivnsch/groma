//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension Array {
    func forEach<U>(function: (element: T) -> U) {
        for e in self {
            function(element: e)
        }
    }
    
    func findFirst(function: (element: T) -> Bool) -> T? {
        for e in self {
            if function(element: e) {
                return e
            }
        }
        return nil
    }
}
