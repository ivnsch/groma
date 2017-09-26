//
//  MonthYear.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation


public class MonthYear: Equatable, Hashable, CustomDebugStringConvertible {
    
    public let month: Int
    public let year: Int
    
    public init(month: Int, year: Int) {
        self.month = month
        self.year = year
    }
    
    public var hashValue: Int {
        return month * 10 + year // TODO review this
    }
    
    public var debugDescription: String {
        return "{\(type(of: self)) month: \(month), year: \(year)}"
    }
    
    public func toDate() -> Date? {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = DateComponents()
        components.month = month
        components.year = year
        return gregorian.date(from: components)
    }
    
    public func offsetMonths(_ months: Int) -> MonthYear? {
        let date = toDate()
        if let dateWithOffset = date?.inMonths(months) {
            let (_, month, year) = dateWithOffset.dayMonthYear
            return MonthYear(month: month, year: year)
        } else {
            logger.e("Date is nil \(self)")
            return nil
        }
    }
}

public func > (lhs: MonthYear, rhs: MonthYear) -> Bool {
    if lhs.year > rhs.year {
        return true
    } else if lhs.year < rhs.year {
        return false
    } else {
        return lhs.month > rhs.month
    }
}

public func < (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return !(lhs > rhs || lhs == rhs)
}

public func >= (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs > rhs || lhs == rhs)
}

public func <= (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs < rhs || lhs == rhs)
}

public func ==(lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs.month == rhs.month) && (lhs.year == rhs.year)
}
