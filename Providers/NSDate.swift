//
//  NSDate.swift
//  shoppin
//
//  Created by ischuetz on 23/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

public extension Date {

    public var dayMonthYear: (day: Int, month: Int, year: Int) {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        return (components.day!, components.month!, components.year!)
    }

    public var startOfMonth: Date {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.month, .year], from: self)
        return calendar.date(from: components)!
    }
    
    public var daysInMonth: Int {
        let calendar = Calendar.current
        let days = (calendar as NSCalendar).range(of: .day, in: .month, for: self)
        return days.length
    }
    
    // Note: this returns days according to exact hours passed not "formal" days, for example if we have Jan 1 and Jan 2 but only 20 hours difference, this returns 0
    public func daysUntil(_ date: Date) -> Int {
        let components = (Calendar.current as NSCalendar).components(.day, from: self, to: date, options: NSCalendar.Options(rawValue: 0))
        return components.day!
    }

    
    public static func startOfMonth(_ month: Int, year: Int) -> Date? {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = DateComponents()
        components.month = month
        components.year = year
        return gregorian.date(from: components)
    }
    
    // src http://stackoverflow.com/a/4482938/930450
    // NOTE: Difference to SO answer: we don't need here only the last *day* of the month but the end (last "instant") which we will define as 1 second before (-1) of the next day (1) of the next month (+1).
    public static func endOfMonth(_ month: Int, year: Int) -> Date? {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = DateComponents()
        components.month = month + 1
        components.year = year
        components.day = 1
        components.second = -1
        return gregorian.date(from: components)
    }
    
    public static func currentMonthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
//        Date().dayMonthYear.month
        formatter.locale = Locale.current
        return formatter.string(from: Date())
    }
    
    public static func inMonths(_ months: Int) -> Date {
        let today = Date()
        return (Calendar.current as NSCalendar).date(
            byAdding: .month,
            value: months,
            to: today,
            options: NSCalendar.Options(rawValue: 0))!
    }
    
    public static func inYears(_ years: Int) -> Date {
        let today = Date()
        return (Calendar.current as NSCalendar).date(
            byAdding: .year,
            value: years,
            to: today,
            options: NSCalendar.Options(rawValue: 0))!
    }
    
    public func inMonths(_ months: Int) -> Date {
        return (Calendar.current as NSCalendar).date(
            byAdding: .month,
            value: months,
            to: self,
            options: NSCalendar.Options(rawValue: 0))!
    }

    public func inMinutes(_ minutes: Int) -> Date {
        return (Calendar.current as NSCalendar).date(
            byAdding: .minute,
            value: minutes,
            to: self,
            options: NSCalendar.Options(rawValue: 0))!
    }
    
    // src http://stackoverflow.com/a/5330027/930450
    public func dateWithZeroSeconds() -> Date {
        let time = floor(self.timeIntervalSinceReferenceDate / 60.0) * 60.0
        return Date(timeIntervalSinceReferenceDate: time)
    }
    
    public func debugDateStr() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: self)
    }
    
    public func toMillis() -> Int64 {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

//public func <(a: Date, b: Date) -> Bool {
//    return a.compare(b) == ComparisonResult.orderedAscending
//}
//
//public func ==(a: Date, b: Date) -> Bool {
//    return a.compare(b) == ComparisonResult.orderedSame
//}
