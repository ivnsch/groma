//
//  MonthYear.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

class MonthYear: Equatable, Hashable {
    
    let month: Int
    let year: Int
    
    init(month: Int, year: Int) {
        self.month = month
        self.year = year
    }
    
    var hashValue: Int {
        return month * 10 + year // TODO review this
    }
}

func ==(lhs: MonthYear, rhs: MonthYear) -> Bool {
    return (lhs.month == rhs.month) && (lhs.year == rhs.year)
}