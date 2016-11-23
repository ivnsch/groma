//
//  MonthYear.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation
import QorumLogs

class MonthYear: Equatable, Hashable, CustomDebugStringConvertible {
    
    let month: Int
    let year: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
    }
    
    var hashValue: Int {
        return month * 10 + year // TODO review this
    }
    
    var debugDescription: String {
        return "{\(type(of: self)) month: \(month), year: \(year)}"
    }
    
    func toDate() -> Date? {
        let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
        var components = DateComponents()
        components.month = month
        components.year = year
        return gregorian.date(from: components)
    }
    
    func offsetMonths(_ months: Int) -> MonthYear? {
        let date = toDate()
        if let dateWithOffset = date?.inMonths(months) {
            let (_, month, year) = dateWithOffset.dayMonthYear
            return MonthYear(month: month, year: year)
        } else {
            QL4("Date is nil \(self)")
            return nil
        }
    }
}

func > (lhs: MonthYear, rhs: MonthYear) -> Bool {
    if lhs.year > rhs.year {
        return true
    } else if lhs.year < rhs.year {
        return false
    } else {
        return lhs.month > rhs.month
    }
}

func < (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return !(lhs > rhs || lhs == rhs)
}

func >= (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs > rhs || lhs == rhs)
}

func <= (lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs < rhs || lhs == rhs)
}

func ==(lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs.month == rhs.month) && (lhs.year == rhs.year)
}
