//
//  StatsProvider.swift
//  shoppin
//
//  Created by ischuetz on 20/08/15.
//  Copyright © 2015 ivanschuetz. All rights reserved.
//

import Foundation

enum TimeUnit {
    case Month, Year
}

struct TimePeriod: Equatable {
    let quantity: Int
    let timeUnit: TimeUnit
    
    init(quantity: Int, timeUnit: TimeUnit) {
        self.quantity = quantity
        self.timeUnit = timeUnit
    }
    
    func dateOffsetComponent() -> NSDateComponents {
        return dateOffsetComponent(quantity)
    }
    
    func dateOffsetComponent(quantity: Int) -> NSDateComponents {
        
        let dateComponents = NSDateComponents()
        
        switch timeUnit {
        case .Month: dateComponents.month = quantity
        case .Year: dateComponents.year = quantity
        }
        
        return dateComponents
    }
}

func ==(lhs: TimePeriod, rhs: TimePeriod) -> Bool {
    return lhs.quantity == rhs.quantity && lhs.timeUnit == rhs.timeUnit
}

enum GroupByAttribute {
    case Name/*, Category*/ //TODO categories
}

enum AggregateGroup: Equatable {
    case All
//    case CategoryItem(Category) // TODO sth like this
    case ProductItem(Product)
}
func ==(lhs: AggregateGroup, rhs: AggregateGroup) -> Bool {
    switch (lhs, rhs) {
    case (.ProductItem(_), .ProductItem(_)): return true
    case (.All, .All): return true
    default: return false
    }
}

protocol StatsProvider {
    
    func aggregate(monthYear: MonthYear, groupBy: GroupByAttribute, _ handler: ProviderResult<[ProductAggregate]> -> ())

    func aggregate(timePeriod: TimePeriod, groupBy: GroupByAttribute, _ handler: ProviderResult<[ProductAggregate]> -> ())
    
    func history(timePeriod: TimePeriod, group: AggregateGroup, _ handler: ProviderResult<GroupMonthYearAggregate> -> ())
    
}
