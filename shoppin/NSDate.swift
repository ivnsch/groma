//
//  NSDate.swift
//  shoppin
//
//  Created by ischuetz on 23/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension NSDate: Comparable {

    var dayMonthYear: (Int, Int, Int) {
        let components = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: self)
        return (components.day, components.month, components.year)
    }

    var startOfMonth: NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Month, .Year], fromDate: self)
        return calendar.dateFromComponents(components)!
    }
}

public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedAscending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedSame
}