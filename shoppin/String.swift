//
//  String.swift
//  shoppin
//
//  Created by ischuetz on 24.12.14.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

import Foundation

extension String {
    
    func contains(str:String) -> Bool {
        return self.rangeOfString(str) != nil
    }
    
    var floatValue: Float {
        return (self as NSString).floatValue
    }
    
    var intValue: Int {
        return (self as NSString).integerValue
    }
//    func startsWith(str:String) -> Bool {
//        var startsWith = false
//        if let range = self.rangeOfString(str) {
//            
//            println (range)
//            println (range.startIndex)
//            // FIXME doesn't work when the found string is near to the end...
//            // e.g. self = "section1", str = "n"
//            // above prints:
////            6..<7
////            6
//            //and then:
//            //fatal error: can not increment endIndex
//            startsWith = distance(str.startIndex, range.startIndex) == 0
//        }
//        return startsWith
//    }
}