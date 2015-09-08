//
//  Array.swift
//  shoppin
//
//  Created by ischuetz on 28.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension Array {
    func forEach<U>(function: (element: Element) -> U) {
        for e in self {
            function(element: e)
        }
    }
    
    func findFirst(function: (element: Element) -> Bool) -> Element? {
        for e in self {
            if function(element: e) {
                return e
            }
        }
        return nil
    }
    
    // src: http://stackoverflow.com/a/30593673/930450
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
