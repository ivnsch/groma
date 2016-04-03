//
//  NSDate.swift
//  shoppin
//
//  Created by ischuetz on 23/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

extension NSDate: Comparable {

    var dayMonthYear: (day: Int, month: Int, year: Int) {
        let components = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: self)
        return (components.day, components.month, components.year)
    }

    var startOfMonth: NSDate {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Month, .Year], fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    var daysInMonth: Int {
        let calendar = NSCalendar.currentCalendar()
        let days = calendar.rangeOfUnit(.Day, inUnit: .Month, forDate: self)
        return days.length
    }
    
    // Note: this returns days according to exact hours passed not "formal" days, for example if we have Jan 1 and Jan 2 but only 20 hours difference, this returns 0
    func daysUntil(date: NSDate) -> Int {
        let components = NSCalendar.currentCalendar().components(.Day, fromDate: self, toDate: date, options: NSCalendarOptions(rawValue: 0))
        return components.day
    }

    
    static func startOfMonth(month: Int, year: Int) -> NSDate? {
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = NSDateComponents()
        components.month = month
        components.year = year
        return gregorian!.dateFromComponents(components)
    }
    
    // src http://stackoverflow.com/a/4482938/930450
    static func endOfMonth(month: Int, year: Int) -> NSDate? {
        let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = NSDateComponents()
        components.month = month + 1
        components.year = year
        components.day = 0
        return gregorian!.dateFromComponents(components)
    }
    
    static func currentMonthName() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MMMM"
        NSDate().dayMonthYear.month
        formatter.locale = NSLocale.currentLocale()
        return formatter.stringFromDate(NSDate())
    }
    
    static func inMonths(months: Int) -> NSDate {
        let today = NSDate()
        return NSCalendar.currentCalendar().dateByAddingUnit(
            .Month,
            value: months,
            toDate: today,
            options: NSCalendarOptions(rawValue: 0))!
    }
    
    func inMonths(months: Int) -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(
            .Month,
            value: months,
            toDate: self,
            options: NSCalendarOptions(rawValue: 0))!
    }
    
    // src http://stackoverflow.com/a/5330027/930450
    func dateWithZeroSeconds() -> NSDate {
        let time = floor(self.timeIntervalSinceReferenceDate / 60.0) * 60.0
        return NSDate(timeIntervalSinceReferenceDate: time)
    }
}

public func <(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedAscending
}

public func ==(a: NSDate, b: NSDate) -> Bool {
    return a.compare(b) == NSComparisonResult.OrderedSame
}